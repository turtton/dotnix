OPENCODE_BIN="${OPENCODE_BIN:-@opencode-dir@/opencode}"
CHILD_WRAPPER="@child-wrapper@"

if [[ -n ${OPENCODE_NO_SANDBOX:-} ]]; then
  exec "$OPENCODE_BIN" "$@"
fi

PROJECT_DIR="$(pwd -P)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
if [[ -n ${OPENCODE_CONFIG_DIR:-} && ${OPENCODE_CONFIG_DIR:0:1} != "/" ]]; then
  echo "opencode-sandbox: ERROR: OPENCODE_CONFIG_DIR must be an absolute path" >&2
  exit 1
fi

REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"

if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

isolated_home() {
  if [[ -d $OPENCODE_CONFIG ]]; then
    local target_dir="${OPENCODE_HOME}${OPENCODE_CONFIG#"$REAL_HOME"}"
    mkdir -p "$(dirname "$target_dir")"
    ln -sfn "$OPENCODE_CONFIG" "$target_dir"
  fi

  local source target
  for source in \
    "${REAL_HOME}/.local/share/opencode" \
    "${REAL_HOME}/.cache/opencode" \
    "${REAL_HOME}/.local/state/opencode" \
    "${REAL_HOME}/.omo" \
    "${REAL_HOME}/.config/git" \
    "${REAL_HOME}/.config/gh"; do
    if [[ -d $source ]]; then
      target="${OPENCODE_HOME}${source#"$REAL_HOME"}"
      mkdir -p "$(dirname "$target")"
      ln -sfn "$source" "$target"
    fi
  done

  for source in \
    "${REAL_HOME}/.rustup" \
    "${REAL_HOME}/.cargo" \
    "${REAL_HOME}/.ssh" \
    "${REAL_HOME}/.gnupg" \
    "${REAL_HOME}/.docker"; do
    if [[ -d $source ]]; then
      ln -sfn "$source" "${OPENCODE_HOME}/${source##*/}"
    fi
  done

  if [[ -f "${REAL_HOME}/.gitconfig" ]]; then
    cp "${REAL_HOME}/.gitconfig" "${OPENCODE_HOME}/.gitconfig"
  fi

  if [[ -n ${HERDR_SOCKET_PATH:-} && -d $(dirname "$HERDR_SOCKET_PATH") ]]; then
    local herdr_session_dir
    herdr_session_dir=$(dirname "$HERDR_SOCKET_PATH")
    mkdir -p "${OPENCODE_HOME}/.config/herdr/sessions"
    ln -sfn "$herdr_session_dir" "${OPENCODE_HOME}/.config/herdr/sessions/${HERDR_SESSION}"
  fi
  if [[ -f "${REAL_HOME}/.config/herdr/config.toml" ]]; then
    mkdir -p "${OPENCODE_HOME}/.config/herdr"
    ln -sfn "${REAL_HOME}/.config/herdr/config.toml" "${OPENCODE_HOME}/.config/herdr/config.toml"
  fi
}

gpg_agent() {
  gpgconf --launch gpg-agent 2>/dev/null || true
}

container_socket() {
  if [[ -z ${CONTAINER_HOST:-} && -z ${DOCKER_HOST:-} ]] && command -v podman >/dev/null 2>&1; then
    local podman_socket
    podman_socket=$(HOME="$REAL_HOME" podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)
    podman_socket="${podman_socket%%$'\n'*}"
    if [[ -n $podman_socket && -S $podman_socket ]]; then
      export CONTAINER_HOST="unix://${podman_socket}"
    fi
  fi
}

opencode_port() {
  if [[ -n ${OPENCODE_PORT:-} ]]; then
    return
  fi

  local port free_port=""
  for port in $(seq 4097 4200); do
    if ! lsof -iTCP:"${port}" -sTCP:LISTEN -n -P 2>/dev/null | grep -q .; then
      free_port=$port
      break
    fi
  done

  if [[ -n $free_port ]]; then
    export OPENCODE_PORT="$free_port"
  else
    echo "opencode-sandbox: WARNING: no free port found in range 4097-4200; OMO may connect to wrong server" >&2
  fi
}

build_sandbox_profile() {
  sbpl_escape() {
    local value=$1
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
  }

  local allow_writes=(
    "$OPENCODE_HOME"
    "$REAL_REPO"
    "/tmp"
    "/private/tmp"
    "/private/var/folders"
    "/var/folders"
  )
  local dir real_config_dir
  for dir in \
    "${REAL_HOME}/.config/opencode" \
    "${REAL_HOME}/.local/share/opencode" \
    "${REAL_HOME}/.cache/opencode" \
    "${REAL_HOME}/.local/state/opencode" \
    "${REAL_HOME}/.cargo" \
    "${REAL_HOME}/.rustup" \
    "${REAL_HOME}/.docker"; do
    [[ -d $dir ]] && allow_writes+=("$dir")
  done
  if [[ -n ${HERDR_SOCKET_PATH:-} && -d $(dirname "$HERDR_SOCKET_PATH") ]]; then
    allow_writes+=("$(dirname "$HERDR_SOCKET_PATH")")
  fi
  if [[ -d $OPENCODE_CONFIG ]]; then
    real_config_dir=$(realpath "$OPENCODE_CONFIG")
    if [[ $real_config_dir != "${REAL_HOME}/.config/opencode" ]]; then
      allow_writes+=("$real_config_dir")
    fi
  fi

  printf '%s\n' '(version 1)' '(allow default)'
  printf '(deny file-write* (subpath "%s"))\n' "$(sbpl_escape "$REAL_HOME")"
  echo '(allow file-write*'
  for dir in "${allow_writes[@]}"; do
    printf '  (subpath "%s")\n' "$(sbpl_escape "$dir")"
  done
  echo ')'
}

setup_sandbox() {
  mkdir -p "$OPENCODE_CONFIG"
  isolated_home
  gpg_agent
  container_socket

  if [[ -z ${GH_TOKEN:-} ]]; then
    local gh_token=""
    gh_token=$(security find-generic-password -s 'gh:github.com' -w 2>/dev/null || true)
    if [[ -z $gh_token ]]; then
      gh_token=$(gh auth token 2>/dev/null || true)
    fi
    [[ -n $gh_token ]] && export GH_TOKEN="$gh_token"
  fi

  local sandbox_extra="${REPO_ROOT}/.opencode/sandbox-extra.sh"
  if [[ -f $sandbox_extra ]]; then
    source "$sandbox_extra"
  fi

  build_sandbox_profile >"${OPENCODE_HOME}/.sandbox.sb"
  opencode_port
  if [[ -n ${OPENCODE_CONFIG_DIR:-} ]]; then
    export OPENCODE_CONFIG_DIR="${OPENCODE_HOME}${OPENCODE_CONFIG#"$REAL_HOME"}"
  fi
}

shell_quote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\"\'\"\'}"
}

hcli() {
  local herdr_bin="" candidate
  if [[ -n ${OPENCODE_HERDR_TEST_MODE:-} ]]; then
    while IFS= read -r candidate; do
      if [[ $candidate != /nix/store/* ]]; then
        herdr_bin=$candidate
        break
      fi
    done < <(type -a -p herdr)
  fi
  [[ -n $herdr_bin ]] || herdr_bin=$(command -v herdr)
  env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
    "$herdr_bin" --session "$HERDR_SESSION" "$@"
}

run_direct() {
  OPENCODE_HOME=$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")
  export OPENCODE_HOME
  trap 'rm -rf "$OPENCODE_HOME"' EXIT INT TERM
  setup_sandbox
  exec sandbox-exec -f "${OPENCODE_HOME}/.sandbox.sb" \
    env OPENCODE_NO_SANDBOX=1 HOME="$OPENCODE_HOME" \
    bash "$CHILD_WRAPPER" "$PROJECT_DIR" "$OPENCODE_BIN" "$@"
}

launch_herdr_context() {
  local label state_dir lock_dir workspace_json panes_json created process_info
  local workspace_id="" pane_id="" command attempt candidate arg

  label="opencode-$(basename "$PROJECT_DIR" | LC_ALL=C sed 's/[^[:alnum:]]/-/g')"
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-launchers/${HERDR_SESSION}-${label}"
  lock_dir="$state_dir/lock"

  if ! workspace_json=$(hcli workspace list 2>/dev/null); then
    echo "opencode-sandbox: WARNING: herdr session is unavailable; running without herdr context" >&2
    return 1
  fi

  mkdir -p "$state_dir"
  for attempt in $(seq 1 200); do
    if mkdir "$lock_dir" 2>/dev/null; then
      break
    fi
    sleep 0.05
  done
  if [[ ! -d $lock_dir ]]; then
    echo "opencode-sandbox: ERROR: timed out waiting for launcher lock: $lock_dir" >&2
    exit 1
  fi
  trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM

  if ! workspace_json=$(hcli workspace list 2>/dev/null) ||
    ! panes_json=$(hcli pane list 2>/dev/null); then
    echo "opencode-sandbox: WARNING: herdr session became unavailable; running without herdr context" >&2
    rmdir "$lock_dir"
    trap - EXIT INT TERM
    return 1
  fi

  while IFS= read -r candidate; do
    [[ -n $candidate ]] || continue
    pane_id=$(jq -r --arg wid "$candidate" --arg cwd "$PROJECT_DIR" \
      '.result.panes[] | select(.workspace_id == $wid and .cwd == $cwd) | .pane_id' \
      <<<"$panes_json" | sed -n '1p')
    if [[ -n $pane_id ]]; then
      workspace_id=$candidate
      break
    fi
  done < <(jq -r --arg label "$label" \
    '.result.workspaces[] | select(.label == $label) | .workspace_id' <<<"$workspace_json")

  if [[ -n $pane_id ]]; then
    hcli workspace focus "$workspace_id" >/dev/null
    process_info=$(hcli pane process-info --pane "$pane_id" 2>/dev/null || true)
    if ! jq -e '.result.process_info as $p | $p.foreground_process_group_id == $p.shell_pid and $p.foreground_processes[0].pid == $p.shell_pid' \
      >/dev/null 2>&1 <<<"$process_info"; then
      rmdir "$lock_dir"
      trap - EXIT INT TERM
      return 0
    fi
  else
    created=$(hcli workspace create --cwd "$PROJECT_DIR" --label "$label" --focus)
    pane_id=$(jq -r '.result.root_pane.pane_id // empty' <<<"$created")
    if [[ -z $pane_id ]]; then
      echo "opencode-sandbox: ERROR: herdr workspace creation returned no pane id" >&2
      exit 1
    fi
  fi

  if [[ -n ${OPENCODE_HERDR_TEST_MODE:-} && $# -gt 0 ]]; then
    command=$(shell_quote "$1")
    shift
  else
    OPENCODE_HOME=$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")
    export OPENCODE_HOME
    setup_sandbox

    command="trap $(shell_quote "rm -rf -- $(shell_quote "$OPENCODE_HOME")") EXIT INT TERM;"
    command+=" $(shell_quote sandbox-exec) -f $(shell_quote "${OPENCODE_HOME}/.sandbox.sb")"
    command+=" env OPENCODE_NO_SANDBOX=1 OPENCODE_HERDR_CHILD=1 HOME=$(shell_quote "$OPENCODE_HOME")"
    command+=" HERDR_SESSION=$(shell_quote "$HERDR_SESSION")"
    command+=" HERDR_SOCKET_PATH=$(shell_quote "${OPENCODE_HOME}/.config/herdr/sessions/${HERDR_SESSION}/herdr.sock")"
    command+=" HERDR_PANE_ID=$(shell_quote "$pane_id")"
    command+=" bash $(shell_quote "$CHILD_WRAPPER") $(shell_quote "$PROJECT_DIR") $(shell_quote "$OPENCODE_BIN")"
  fi
  for arg in "$@"; do
    command+=" $(shell_quote "$arg")"
  done
  hcli pane run "$pane_id" "$command"

  for attempt in $(seq 1 20); do
    process_info=$(hcli pane process-info --pane "$pane_id" 2>/dev/null || true)
    if ! jq -e '.result.process_info as $p | $p.foreground_process_group_id == $p.shell_pid and $p.foreground_processes[0].pid == $p.shell_pid' \
      >/dev/null 2>&1 <<<"$process_info"; then
      break
    fi
    sleep 0.05
  done

  rmdir "$lock_dir"
  trap - EXIT INT TERM
  return 0
}

if [[ -z ${OPENCODE_HERDR_CHILD:-} && -n ${HERDR_ENV:-} ]]; then
  if launch_herdr_context "$@"; then
    exit 0
  fi
fi

run_direct "$@"
