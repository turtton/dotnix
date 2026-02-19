# =============================================================================
# Variables
# =============================================================================

CLAUDE_CODE_BIN="${CLAUDE_CODE_BIN:-@claude-code-dir@/claude}"

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"
CLAUDE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/claudebox-XXXXXXXX")"
CLAUDE_CONFIG="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"
XDG_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Share tree: repo が $HOME 配下なら最上位ディレクトリまで ro 公開
REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"
if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

# bwrap 引数を蓄積する配列
BWRAP_ARGS=()

# =============================================================================
# 各責務の関数 (bwrap 引数を BWRAP_ARGS に追加する)
# =============================================================================

# 基本ファイルシステム: OS のルート構造を読み取り専用で公開
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

# /run の選択的マウント: XDG_RUNTIME_DIR 全体は避け、必要なものだけ
selective_run_mounts() {
  BWRAP_ARGS+=(
    --ro-bind-try /run/systemd/resolve /run/systemd/resolve # DNS resolver
    --ro-bind-try /run/current-system /run/current-system
    --ro-bind-try /run/booted-system /run/booted-system
    --ro-bind-try /run/opengl-driver /run/opengl-driver
    --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
    --ro-bind-try /run/nixos /run/nixos
    --ro-bind-try /run/wrappers /run/wrappers
  )
}

# Nix store: ストアは読み取り専用、デーモンソケットは読み書き
nix_store() {
  BWRAP_ARGS+=(
    --ro-bind /nix /nix
    --bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket
  )
}

# 隔離ホームディレクトリ: 一時ホームに Claude 設定をマウント
isolated_home() {
  BWRAP_ARGS+=(
    --tmpfs /tmp
    --bind "$CLAUDE_HOME" "$HOME"
    --bind "$CLAUDE_CONFIG" "${HOME}/.claude"
    --bind "$CLAUDE_JSON" "${HOME}/.claude.json"
  )
}

# 名前空間の隔離とネットワーク共有 + 環境変数の設定
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
  )
}

# プロジェクトマウント: 親ツリーは ro、リポジトリルートは rw
project_mount() {
  if [[ $SHARE_TREE != "$REPO_ROOT" ]]; then
    BWRAP_ARGS+=(--ro-bind "$SHARE_TREE" "$SHARE_TREE")
  fi
  BWRAP_ARGS+=(--bind "$REPO_ROOT" "$REPO_ROOT")
}

# Git 設定: ~/.gitconfig と ~/.config/git/ を読み取り専用で公開
git_config() {
  if [[ -f "${HOME}/.gitconfig" ]]; then
    BWRAP_ARGS+=(--ro-bind "${HOME}/.gitconfig" "${HOME}/.gitconfig")
  fi
  if [[ -d "${HOME}/.config/git" ]]; then
    mkdir -p "${CLAUDE_HOME}/.config"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/git" "${HOME}/.config/git")
  fi
}

# GitHub CLI: ~/.config/gh/ を読み取り専用で公開
gh_cli() {
  if [[ -d "${HOME}/.config/gh" ]]; then
    mkdir -p "${CLAUDE_HOME}/.config"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/gh" "${HOME}/.config/gh")
  fi
}

# D-Bus セッションバス: キーリングアクセス等に必要
dbus_session() {
  local socket_path=""

  # DBUS_SESSION_BUS_ADDRESS から Unix ソケットパスを抽出
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    socket_path="$(echo "$DBUS_SESSION_BUS_ADDRESS" | sed -n 's/^unix:path=\([^,]*\).*/\1/p')"
  fi

  # フォールバック: XDG_RUNTIME_DIR/bus
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

# SSH エージェント: SSH_AUTH_SOCK を読み取り専用で公開
ssh_agent() {
  if [[ -n ${SSH_AUTH_SOCK:-} && -e $SSH_AUTH_SOCK ]]; then
    BWRAP_ARGS+=(
      --ro-bind "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK"
      --setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
    )
  fi
}

# GPG エージェント: ソケットディレクトリ + ~/.gnupg を公開
# 事前にデーモンを起動しておく (PID namespace 内では自動起動不可のため)
gpg_agent() {
  # デーモン事前起動
  gpgconf --launch gpg-agent 2>/dev/null || true
  gpgconf --launch keyboxd 2>/dev/null || true
  gpgconf --launch dirmngr 2>/dev/null || true

  # XDG runtime 内の gnupg ソケットディレクトリ
  local gpg_socket_dir="${XDG_RUNTIME}/gnupg"
  if [[ -d $gpg_socket_dir ]]; then
    BWRAP_ARGS+=(--bind "$gpg_socket_dir" "$gpg_socket_dir")
  fi

  # ~/.gnupg (鍵輪と設定)
  if [[ -d "${HOME}/.gnupg" ]]; then
    mkdir -m 700 -p "${CLAUDE_HOME}/.gnupg"
    BWRAP_ARGS+=(--bind "${HOME}/.gnupg" "${HOME}/.gnupg")
  fi
}

# IDE 連携: ~/.claude/ide を ro 公開し、auth token を FD 経由で渡す
# PID namespace により IDE lock file が stale 扱いされるのを回避
ide_integration() {
  local ide_dir="${HOME}/.claude/ide"
  if [[ -d $ide_dir ]]; then
    BWRAP_ARGS+=(--ro-bind "$ide_dir" "${HOME}/.claude/ide")
  fi

  # auth token の読み取り (lock ファイルから最新のものを取得)
  IDE_AUTH_TOKEN=""
  if [[ -d $ide_dir ]]; then
    local latest
    latest="$(ls -t "$ide_dir"/*.lock "$ide_dir"/[0-9]* 2>/dev/null | head -1 || true)"
    if [[ -n $latest && -f $latest ]]; then
      local token
      token="$(jq -r '.authToken // empty' "$latest" 2>/dev/null || true)"
      if [[ -n $token ]]; then
        IDE_AUTH_TOKEN="$token"
        local auth_file="${CLAUDE_HOME}/.ide-auth-token"
        printf '%s' "$token" >"$auth_file"
        chmod 600 "$auth_file"
      fi
    fi
  fi
}

# Chrome 拡張連携: ブラウザブリッジソケットと NativeMessagingHosts を公開
chrome_integration() {
  # ブリッジ用 Unix ソケットディレクトリ
  local bridge_dir="/tmp/claude-mcp-browser-bridge-${USER}"
  mkdir -p "$bridge_dir"
  BWRAP_ARGS+=(--bind "$bridge_dir" "$bridge_dir")

  # Chromium 系ブラウザの NativeMessagingHosts ディレクトリ
  local browsers=(google-chrome chromium BraveSoftware microsoft-edge vivaldi opera)
  for browser in "${browsers[@]}"; do
    local browser_root="${HOME}/.config/${browser}"
    [[ -d $browser_root ]] || continue

    local host_dir="${browser_root}/NativeMessagingHosts"
    mkdir -p "$host_dir"
    mkdir -p "${CLAUDE_HOME}/.config/${browser}/NativeMessagingHosts"
    BWRAP_ARGS+=(--bind "$host_dir" "$host_dir")
  done
}

# =============================================================================
# セットアップ & 起動
# =============================================================================

# 一時ホームのクリーンアップ (mktemp -d で作成済み)
trap 'rm -rf "$CLAUDE_HOME"' EXIT INT TERM

# Claude 設定ファイルの確保
mkdir -p "$CLAUDE_CONFIG"
[[ -f $CLAUDE_JSON ]] || touch "$CLAUDE_JSON"

# 各関数を順に呼び出して BWRAP_ARGS を構築
base_filesystem
selective_run_mounts
nix_store
isolated_home
namespace_and_env
project_mount
git_config
gh_cli
dbus_session
ssh_agent
gpg_agent
ide_integration
chrome_integration

# サンドボックス内で実行するスクリプトの組み立て
if [[ -n ${IDE_AUTH_TOKEN:-} ]]; then
  INNER_SCRIPT="$(
    cat <<-SCRIPT
		exec 3< '${HOME}/.ide-auth-token'
		rm -f '${HOME}/.ide-auth-token'
		export CLAUDE_CODE_WEBSOCKET_AUTH_FILE_DESCRIPTOR=3
		cd '${PROJECT_DIR}'
		exec '${CLAUDE_CODE_BIN}' --dangerously-skip-permissions
		SCRIPT
  )"
else
  INNER_SCRIPT="$(
    cat <<-SCRIPT
		cd '${PROJECT_DIR}'
		exec '${CLAUDE_CODE_BIN}' --dangerously-skip-permissions
		SCRIPT
  )"
fi

exec bwrap "${BWRAP_ARGS[@]}" bash -c "$INNER_SCRIPT"
