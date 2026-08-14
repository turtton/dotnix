#!/usr/bin/env bash

SENPI_BIN="${SENPI_BIN:-@senpi-dir@/senpi}"
CHILD_WRAPPER="@child-wrapper@"

if [[ -n ${SENPI_NO_SANDBOX:-} ]]; then
  exec "$SENPI_BIN" "$@"
fi

PROJECT_DIR="$(pwd -P)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"

REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"

if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

isolated_home() {
  local source target
  for source in \
    "${REAL_HOME}/.senpi" \
    "${REAL_HOME}/.local/share/opencode" \
    "${REAL_HOME}/.cache/opencode" \
    "${REAL_HOME}/.local/state/opencode" \
    "${REAL_HOME}/.omo" \
    "${REAL_HOME}/.config/git" \
    "${REAL_HOME}/.config/gh"; do
    if [[ -d $source ]]; then
      target="${SENPI_HOME}${source#"$REAL_HOME"}"
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
      ln -sfn "$source" "${SENPI_HOME}/${source##*/}"
    fi
  done

  if [[ -f "${REAL_HOME}/.gitconfig" ]]; then
    cp "${REAL_HOME}/.gitconfig" "${SENPI_HOME}/.gitconfig"
  fi

  if [[ -n ${HERDR_SOCKET_PATH:-} && -n ${HERDR_SESSION:-} && -d $(dirname "$HERDR_SOCKET_PATH") ]]; then
    local herdr_session_dir
    herdr_session_dir=$(dirname "$HERDR_SOCKET_PATH")
    mkdir -p "${SENPI_HOME}/.config/herdr/sessions"
    ln -sfn "$herdr_session_dir" "${SENPI_HOME}/.config/herdr/sessions/${HERDR_SESSION}"
  fi
  if [[ -f "${REAL_HOME}/.config/herdr/config.toml" ]]; then
    mkdir -p "${SENPI_HOME}/.config/herdr"
    ln -sfn "${REAL_HOME}/.config/herdr/config.toml" "${SENPI_HOME}/.config/herdr/config.toml"
  fi
}

gpg_agent() {
  gpgconf --launch gpg-agent 2>/dev/null || true
  gpgconf --launch keyboxd 2>/dev/null || true
  gpgconf --launch dirmngr 2>/dev/null || true
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

build_sandbox_profile() {
  sbpl_escape() {
    local value=$1
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
  }

  local allow_writes=(
    "$SENPI_HOME"
    "$REAL_REPO"
    "/tmp"
    "/private/tmp"
    "/private/var/folders"
    "/var/folders"
  )
  local dir
  for dir in \
    "${REAL_HOME}/.senpi" \
    "${REAL_HOME}/.local/share/opencode" \
    "${REAL_HOME}/.cache/opencode" \
    "${REAL_HOME}/.local/state/opencode" \
    "${REAL_HOME}/.omo" \
    "${REAL_HOME}/.config/git" \
    "${REAL_HOME}/.config/gh" \
    "${REAL_HOME}/.rustup" \
    "${REAL_HOME}/.cargo" \
    "${REAL_HOME}/.ssh" \
    "${REAL_HOME}/.gnupg" \
    "${REAL_HOME}/.docker"; do
    [[ -d $dir ]] && allow_writes+=("$dir")
  done
  if [[ -n ${HERDR_SOCKET_PATH:-} && -d $(dirname "$HERDR_SOCKET_PATH") ]]; then
    allow_writes+=("$(dirname "$HERDR_SOCKET_PATH")")
  fi

  printf '%s\n' '(version 1)' '(allow default)'
  printf '(deny file-write* (subpath "%s"))\n' "$(sbpl_escape "$REAL_HOME")"
  if [[ $SHARE_TREE != "$REAL_REPO" ]]; then
    # Linux 側の share-tree ro-bind に相当。REAL_HOME の deny で実害は無いが、
    # 消すと SHARE_TREE が未使用になり shellcheck が落ちる
    printf '(deny file-write* (subpath "%s"))\n' "$(sbpl_escape "$SHARE_TREE")"
  fi
  echo '(allow file-write*'
  for dir in "${allow_writes[@]}"; do
    printf '  (subpath "%s")\n' "$(sbpl_escape "$dir")"
  done
  echo ')'
}

setup_sandbox() {
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

  local sandbox_extra="${REPO_ROOT}/.senpi/sandbox-extra.sh"
  if [[ -f $sandbox_extra ]]; then
    # shellcheck source=/dev/null
    source "$sandbox_extra"
  fi

  build_sandbox_profile >"${SENPI_HOME}/.sandbox.sb"
}

SENPI_HOME=$(mktemp -d "${TMPDIR:-/tmp}/senpibox-XXXXXXXX")
export SENPI_HOME
trap 'rm -rf "$SENPI_HOME"' EXIT INT TERM
setup_sandbox
exec sandbox-exec -f "${SENPI_HOME}/.sandbox.sb" \
  env SENPI_NO_SANDBOX=1 "SENPI_HERDR_CHILD=${SENPI_HERDR_CHILD:-}" HOME="$SENPI_HOME" \
  bash "$CHILD_WRAPPER" "$PROJECT_DIR" "$SENPI_BIN" "$@"
