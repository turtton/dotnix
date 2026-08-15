#!/usr/bin/env bash

SENPI_BIN="${SENPI_BIN:-@senpi-dir@/senpi}"

if [[ -n ${SENPI_NO_SANDBOX:-} && -z ${SENPI_HERDR_CHILD:-} ]]; then
  exec "$SENPI_BIN" "$@"
fi

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"

# メモリ節約: /var/tmp (ディスク) を優先し、失敗時のみ tmpfs にフォールバック
if ! SENPI_HOME="$(mktemp -d /var/tmp/senpibox-XXXXXXXX 2>/dev/null)"; then
  SENPI_HOME="$(mktemp -d "${TMPDIR:-/tmp}/senpibox-XXXXXXXX")"
fi
XDG_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"
if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

BWRAP_ARGS=()

base_filesystem() {
  BWRAP_ARGS+=(
    --dev /dev
    --proc /proc
    --ro-bind-try /usr /usr
    --ro-bind-try /bin /bin
    --ro-bind-try /lib /lib
    --ro-bind-try /lib64 /lib64
    --ro-bind /etc /etc
  )
}

selective_run_mounts() {
  BWRAP_ARGS+=(
    --ro-bind-try /run/systemd/resolve /run/systemd/resolve
    --ro-bind-try /run/current-system /run/current-system
    --ro-bind-try /run/booted-system /run/booted-system
    --ro-bind-try /run/opengl-driver /run/opengl-driver
    --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
    --ro-bind-try /run/nixos /run/nixos
    --ro-bind-try /run/wrappers /run/wrappers
  )
}

nix_store() {
  BWRAP_ARGS+=(
    --ro-bind /nix /nix
    --bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket
  )
}

isolated_home() {
  BWRAP_ARGS+=(
    --perms 1777 --tmpfs /tmp
    --bind "$SENPI_HOME" "$HOME"
  )

  if [[ -n ${HERDR_SOCKET_PATH:-} ]]; then
    local socket_dir
    socket_dir=$(dirname "$HERDR_SOCKET_PATH")
    if [[ $socket_dir == "$REAL_HOME"/* ]]; then
      mkdir -p "${SENPI_HOME}${socket_dir#"$REAL_HOME"}"
      BWRAP_ARGS+=(--bind "$socket_dir" "$socket_dir")
    fi
  fi

  local senpi_dir="${HOME}/.senpi"
  if [[ -d $senpi_dir ]]; then
    mkdir -p "${SENPI_HOME}/.senpi"
    BWRAP_ARGS+=(--bind "$senpi_dir" "$senpi_dir")
  fi

  local opencode_config="${HOME}/.config/opencode"
  if [[ -d $opencode_config ]]; then
    mkdir -p "${SENPI_HOME}/.config/opencode"
    BWRAP_ARGS+=(--bind "$opencode_config" "$opencode_config")
  fi

  local opencode_data="${HOME}/.local/share/opencode"
  if [[ -d $opencode_data ]]; then
    mkdir -p "${SENPI_HOME}/.local/share/opencode"
    BWRAP_ARGS+=(--bind "$opencode_data" "$opencode_data")
  fi

  local opencode_cache="${HOME}/.cache/opencode"
  if [[ -d $opencode_cache ]]; then
    mkdir -p "${SENPI_HOME}/.cache/opencode"
    BWRAP_ARGS+=(--bind "$opencode_cache" "$opencode_cache")
  fi

  local opencode_state="${HOME}/.local/state/opencode"
  if [[ -d $opencode_state ]]; then
    mkdir -p "${SENPI_HOME}/.local/state/opencode"
    BWRAP_ARGS+=(--bind "$opencode_state" "$opencode_state")
  fi

  local omo_dir="${HOME}/.omo"
  if [[ -d $omo_dir ]]; then
    mkdir -p "${SENPI_HOME}/.omo"
    BWRAP_ARGS+=(--bind "$omo_dir" "$omo_dir")
  fi

  local claude_dir="${HOME}/.claude"
  if [[ -d $claude_dir ]]; then
    mkdir -p "${SENPI_HOME}/.claude"
    BWRAP_ARGS+=(--bind "$claude_dir" "$claude_dir")
  fi

  if [[ -d "${HOME}/.rustup" ]]; then
    mkdir -p "${SENPI_HOME}/.rustup"
    BWRAP_ARGS+=(--bind "${HOME}/.rustup" "${HOME}/.rustup")
  fi
  if [[ -d "${HOME}/.cargo" ]]; then
    mkdir -p "${SENPI_HOME}/.cargo"
    BWRAP_ARGS+=(--bind "${HOME}/.cargo" "${HOME}/.cargo")
  fi
}

namespace_and_env() {
  BWRAP_ARGS+=(
    --unshare-all
    --share-net
    --setenv HOME "$HOME"
    --setenv USER "$USER"
    --setenv PATH "$PATH"
    --setenv TMPDIR /tmp
    --setenv TEMPDIR /tmp
    --setenv TEMP /tmp
    --setenv TMP /tmp
    --unsetenv TMUX
    --unsetenv TMUX_PANE
    --unsetenv TMUX_TMPDIR
    --setenv SENPI_NO_SANDBOX 1
  )

  local herdr_vars=(HERDR_SESSION HERDR_SOCKET_PATH HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID)
  local var
  for var in "${herdr_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done

  local xdg_vars=(XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME XDG_RUNTIME_DIR)
  for var in "${xdg_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done
}

# worktree の main repository は先に ro、作業中の repository は最後に rw で公開する
project_mount() {
  if [[ $SHARE_TREE != "$REPO_ROOT" ]]; then
    BWRAP_ARGS+=(--ro-bind "$SHARE_TREE" "$SHARE_TREE")
  fi

  local git_dir git_common_dir main_repo_root
  git_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
  git_common_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [[ -n $git_dir && -n $git_common_dir && $git_common_dir != "$git_dir" ]]; then
    main_repo_root="$(realpath "${git_common_dir}/.." 2>/dev/null || true)"
    if [[ -n $main_repo_root && -d $main_repo_root ]] &&
      [[ $main_repo_root != "$SHARE_TREE" && $main_repo_root != "$REPO_ROOT" ]] &&
      [[ $main_repo_root != "$SHARE_TREE/"* ]]; then
      BWRAP_ARGS+=(--ro-bind "$main_repo_root" "$main_repo_root")
    fi
    # worktree の git 操作は共通 .git への書き込みを要するため、ro マウント後に rw で上書きする
    BWRAP_ARGS+=(--bind "$git_common_dir" "$git_common_dir")
  fi

  BWRAP_ARGS+=(--bind "$REPO_ROOT" "$REPO_ROOT")
}

git_config() {
  if [[ -f "${HOME}/.gitconfig" ]]; then
    BWRAP_ARGS+=(--ro-bind "${HOME}/.gitconfig" "${HOME}/.gitconfig")
  fi
  if [[ -d "${HOME}/.config/git" ]]; then
    mkdir -p "${SENPI_HOME}/.config"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/git" "${HOME}/.config/git")
  fi
}

gh_cli() {
  if [[ -d "${HOME}/.config/gh" ]]; then
    mkdir -p "${SENPI_HOME}/.config"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/gh" "${HOME}/.config/gh")
  fi
}

dbus_session() {
  local socket_path=""
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    socket_path="$(sed -n 's/^unix:path=\([^,]*\).*/\1/p' <<<"$DBUS_SESSION_BUS_ADDRESS")"
  fi
  if [[ -z $socket_path ]]; then
    socket_path="${XDG_RUNTIME}/bus"
  fi
  if [[ -S $socket_path ]]; then
    BWRAP_ARGS+=(
      --ro-bind "$socket_path" "$socket_path"
      --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=${socket_path}"
    )
  fi
}

gpg_agent() {
  gpgconf --launch gpg-agent 2>/dev/null || true
  gpgconf --launch keyboxd 2>/dev/null || true
  gpgconf --launch dirmngr 2>/dev/null || true

  local gpg_socket_dir="${XDG_RUNTIME}/gnupg"
  if [[ -d $gpg_socket_dir ]]; then
    BWRAP_ARGS+=(--bind "$gpg_socket_dir" "$gpg_socket_dir")
  fi
  if [[ -d "${HOME}/.gnupg" ]]; then
    mkdir -p "${SENPI_HOME}/.gnupg"
    chmod 700 "${SENPI_HOME}/.gnupg"
    BWRAP_ARGS+=(--bind "${HOME}/.gnupg" "${HOME}/.gnupg")
  fi
}

container_socket() {
  local container_host=""
  local docker_sock="/var/run/docker.sock"
  if [[ -S $docker_sock ]]; then
    BWRAP_ARGS+=(--bind "$docker_sock" "$docker_sock")
  fi

  local rootless_docker="${XDG_RUNTIME}/docker.sock"
  if [[ -S $rootless_docker ]]; then
    BWRAP_ARGS+=(--bind "$rootless_docker" "$rootless_docker")
  fi
  if [[ -d "${HOME}/.docker" ]]; then
    mkdir -p "${SENPI_HOME}/.docker"
    BWRAP_ARGS+=(--bind "${HOME}/.docker" "${HOME}/.docker")
  fi

  local podman_sock="/run/podman/podman.sock"
  if [[ -S $podman_sock ]]; then
    BWRAP_ARGS+=(--bind "$podman_sock" "$podman_sock")
  fi

  local rootless_podman="${XDG_RUNTIME}/podman/podman.sock"
  if [[ -S $rootless_podman ]]; then
    BWRAP_ARGS+=(--bind "$(dirname "$rootless_podman")" "$(dirname "$rootless_podman")")
    container_host="unix://${rootless_podman}"
  fi

  if [[ -d "${HOME}/.config/containers" ]]; then
    mkdir -p "${SENPI_HOME}/.config/containers"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/containers" "${HOME}/.config/containers")
  fi
  if [[ -d "${HOME}/.local/share/containers" ]]; then
    mkdir -p "${SENPI_HOME}/.local/share/containers"
    BWRAP_ARGS+=(--bind "${HOME}/.local/share/containers" "${HOME}/.local/share/containers")
  fi
  if [[ -n $container_host ]]; then
    BWRAP_ARGS+=(--setenv CONTAINER_HOST "$container_host")
  fi
}

terminal_env() {
  if [[ -n ${TERM:-} ]]; then
    BWRAP_ARGS+=(--setenv TERM "$TERM")
  fi
  if [[ -n ${TERMINFO:-} && -d $TERMINFO ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO "$TERMINFO")
  fi

  local system_terminfo="/run/current-system/sw/share/terminfo"
  local effective_dirs=""
  if [[ -d $system_terminfo ]]; then
    effective_dirs="$system_terminfo"
  fi
  if [[ -n ${TERMINFO_DIRS:-} ]]; then
    if [[ -n $effective_dirs ]]; then
      effective_dirs="${effective_dirs}:${TERMINFO_DIRS}"
    else
      effective_dirs="$TERMINFO_DIRS"
    fi
  fi
  if [[ -n $effective_dirs ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO_DIRS "$effective_dirs")
  fi
}

display_clipboard() {
  if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    local wayland_socket
    if [[ $WAYLAND_DISPLAY == /* ]]; then
      wayland_socket="$WAYLAND_DISPLAY"
    else
      wayland_socket="${XDG_RUNTIME}/${WAYLAND_DISPLAY}"
    fi
    if [[ -S $wayland_socket ]]; then
      BWRAP_ARGS+=(
        --ro-bind "$wayland_socket" "$wayland_socket"
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
        --unsetenv WAYLAND_SOCKET
      )
    fi
  fi
}

trap 'rm -rf "$SENPI_HOME"' EXIT INT TERM

base_filesystem
selective_run_mounts
nix_store
isolated_home
namespace_and_env
project_mount
git_config
gh_cli
dbus_session
gpg_agent
container_socket
terminal_env
display_clipboard

SANDBOX_EXTRA="${REPO_ROOT}/.senpi/sandbox-extra.sh"
if [[ -f $SANDBOX_EXTRA ]]; then
  # shellcheck source=/dev/null
  source "$SANDBOX_EXTRA"
fi

exec bwrap "${BWRAP_ARGS[@]}" bash "@child-wrapper@" "$PROJECT_DIR" "$SENPI_BIN" "$@"
