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
dir_name=$(printf '%s' "$(basename "$PROJECT_DIR")" | LC_ALL=C tr -c '[:alnum:]_-' '-')
dir_hash=$(printf '%s' "$PROJECT_DIR" | sha256sum | cut -c1-8)
HERDR_SESSION="opencode-${dir_name}-${dir_hash}"
HERDR_SOCKET_PATH="${REAL_HOME}/.config/herdr/sessions/${HERDR_SESSION}/herdr.sock"
HERDR_SESSION_DIR="$(dirname "$HERDR_SOCKET_PATH")"
LAUNCHER_STATE="${XDG_STATE_HOME:-${REAL_HOME}/.local/state}/herdr-launchers/${HERDR_SESSION}"
PANE_ID_FILE="${LAUNCHER_STATE}/pane-id"
LOCK_DIR="${LAUNCHER_STATE}/lock"
unset HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID

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

  if [[ -d $HERDR_SESSION_DIR ]]; then
    mkdir -p "${OPENCODE_HOME}/.config/herdr/sessions"
    ln -sfn "$HERDR_SESSION_DIR" "${OPENCODE_HOME}/.config/herdr/sessions/${HERDR_SESSION}"
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
    "${REAL_HOME}/.docker" \
    "$HERDR_SESSION_DIR"; do
    [[ -d $dir ]] && allow_writes+=("$dir")
  done
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
  printf "'%s'" "${1//\'/\'\\\'\'}"
}

start_server() {
  if herdr --session "$HERDR_SESSION" status 2>/dev/null | grep -q 'status: running'; then
    return
  fi

  nohup herdr --session "$HERDR_SESSION" server >"${LAUNCHER_STATE}/server.log" 2>&1 </dev/null &
  local server_pid=$! attempt
  for attempt in $(seq 1 200); do
    if herdr --session "$HERDR_SESSION" workspace list >/dev/null 2>&1; then
      return
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
      echo "opencode-sandbox: ERROR: herdr server failed to start" >&2
      return 1
    fi
    sleep 0.05
  done
  echo "opencode-sandbox: ERROR: timed out waiting for herdr server" >&2
  return 1
}

create_or_get_pane() {
  local pane_id="" created
  if [[ -f $PANE_ID_FILE ]]; then
    pane_id=$(<"$PANE_ID_FILE")
    if ! herdr --session "$HERDR_SESSION" pane get "$pane_id" >/dev/null 2>&1; then
      pane_id=""
    fi
  fi
  if [[ -z $pane_id ]]; then
    created=$(herdr --session "$HERDR_SESSION" workspace create \
      --cwd "$PROJECT_DIR" --label "$(basename "$PROJECT_DIR")" --no-focus)
    pane_id=$(jq -er '.result.root_pane.pane_id' <<<"$created")
    printf '%s\n' "$pane_id" >"${PANE_ID_FILE}.tmp"
    mv -f "${PANE_ID_FILE}.tmp" "$PANE_ID_FILE"
  fi
  printf '%s' "$pane_id"
}

pane_is_idle() {
  local info
  info=$(herdr --session "$HERDR_SESSION" pane process-info --pane "$1" 2>/dev/null) || return 1
  jq -e '.result.process_info as $p | $p.foreground_process_group_id == $p.shell_pid and $p.foreground_processes[0].pid == $p.shell_pid' \
    >/dev/null 2>&1 <<<"$info"
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

if [[ ! -t 0 || ! -t 1 || ! -t 2 ]]; then
  run_direct "$@"
fi

mkdir -p "$LAUNCHER_STATE" "$HERDR_SESSION_DIR"
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.05
done
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT INT TERM
start_server

pane_id=$(create_or_get_pane)
if pane_is_idle "$pane_id"; then
  if [[ -n ${OPENCODE_HERDR_TEST_MODE:-} && $# -gt 0 ]]; then
    command=$(shell_quote "$1")
    shift
    for arg in "$@"; do
      command+=" $(shell_quote "$arg")"
    done
    herdr --session "$HERDR_SESSION" pane run "$pane_id" "$command"
    rmdir "$LOCK_DIR"
    trap - EXIT INT TERM
    exec herdr --session "$HERDR_SESSION"
  fi

  OPENCODE_HOME=$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")
  export OPENCODE_HOME
  setup_sandbox

  command="$(shell_quote sandbox-exec) -f $(shell_quote "${OPENCODE_HOME}/.sandbox.sb")"
  command+=" env OPENCODE_NO_SANDBOX=1 HOME=$(shell_quote "$OPENCODE_HOME")"
  command+=" HERDR_SESSION=$(shell_quote "$HERDR_SESSION")"
  command+=" HERDR_SOCKET_PATH=$(shell_quote "${OPENCODE_HOME}/.config/herdr/sessions/${HERDR_SESSION}/herdr.sock")"
  command+=" HERDR_PANE_ID=$(shell_quote "$pane_id")"
  command+=" bash $(shell_quote "$CHILD_WRAPPER") $(shell_quote "$PROJECT_DIR") $(shell_quote "$OPENCODE_BIN")"
  for arg in "$@"; do
    command+=" $(shell_quote "$arg")"
  done
  herdr --session "$HERDR_SESSION" pane run "$pane_id" "$command"
fi

rmdir "$LOCK_DIR"
trap - EXIT INT TERM
exec herdr --session "$HERDR_SESSION"
