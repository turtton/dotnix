# =============================================================================
# Variables
# =============================================================================

OPENCODE_BIN="${OPENCODE_BIN:-@opencode-dir@/opencode}"

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"
OPENCODE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")"
OPENCODE_CONFIG="${HOME}/.config/opencode"
OPENCODE_JSON="${OPENCODE_CONFIG}/opencode.json"
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

# 隔離ホームディレクトリ: 一時ホームに OpenCode 設定をマウント
isolated_home() {
  BWRAP_ARGS+=(
    --perms 1777 --tmpfs /tmp
    --bind "$OPENCODE_HOME" "$HOME"
  )

  # OpenCode 設定ディレクトリ全体をマウント (opencode.json, AGENTS.md等)
  if [[ -d $OPENCODE_CONFIG ]]; then
    mkdir -p "${OPENCODE_HOME}/.config/opencode"
    BWRAP_ARGS+=(--bind "$OPENCODE_CONFIG" "${HOME}/.config/opencode")
  fi

  # OpenCode データディレクトリ (auth.json等を含む) をマウント
  local opencode_data="${HOME}/.local/share/opencode"
  if [[ -d $opencode_data ]]; then
    mkdir -p "${OPENCODE_HOME}/.local/share/opencode"
    BWRAP_ARGS+=(--bind "$opencode_data" "${HOME}/.local/share/opencode")
  fi

  # OpenCode キャッシュディレクトリ (プラグインの node_modules, models.json等)
  local opencode_cache="${HOME}/.cache/opencode"
  if [[ -d $opencode_cache ]]; then
    mkdir -p "${OPENCODE_HOME}/.cache/opencode"
    BWRAP_ARGS+=(--bind "$opencode_cache" "${HOME}/.cache/opencode")
  fi

  # OpenCode 状態ディレクトリ (frecency, model選択, プロンプト履歴)
  local opencode_state="${HOME}/.local/state/opencode"
  if [[ -d $opencode_state ]]; then
    mkdir -p "${OPENCODE_HOME}/.local/state/opencode"
    BWRAP_ARGS+=(--bind "$opencode_state" "${HOME}/.local/state/opencode")
  fi
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
    # tmux: ホスト側の TMUX 変数を消す (ネスト検出を防ぎ、サンドボックス内で独立した tmux サーバーを起動)
    --unsetenv TMUX
    --unsetenv TMUX_PANE
    --unsetenv TMUX_TMPDIR
    # opencode: サンドボックスのネストを防ぐ (OMO の subagent 起動時に再度サンドボックスが起動しないように)
    --setenv OPENCODE_NO_SANDBOX 1
  )

  # XDG Base Directory 変数の転送 (opencode は XDG 準拠)
  local xdg_vars=(XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME)
  for var in "${xdg_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done
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
    mkdir -p "${OPENCODE_HOME}/.config"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/git" "${HOME}/.config/git")
  fi
}

# GitHub CLI: ~/.config/gh/ を読み取り専用で公開
gh_cli() {
  if [[ -d "${HOME}/.config/gh" ]]; then
    mkdir -p "${OPENCODE_HOME}/.config"
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
    mkdir -m 700 -p "${OPENCODE_HOME}/.gnupg"
    BWRAP_ARGS+=(--bind "${HOME}/.gnupg" "${HOME}/.gnupg")
  fi
}

# コンテナソケット: Docker/Podman CLI からデーモンに接続可能にする
container_socket() {
  # Docker: 標準ソケット
  local docker_sock="/var/run/docker.sock"
  if [[ -S $docker_sock ]]; then
    BWRAP_ARGS+=(--bind "$docker_sock" "$docker_sock")
  fi

  # Docker: Rootless (XDG_RUNTIME_DIR/docker.sock)
  local rootless_docker="${XDG_RUNTIME}/docker.sock"
  if [[ -S $rootless_docker ]]; then
    BWRAP_ARGS+=(--bind "$rootless_docker" "$rootless_docker")
  fi

  # Docker 設定 (~/.docker) を公開
  if [[ -d "${HOME}/.docker" ]]; then
    mkdir -p "${OPENCODE_HOME}/.docker"
    BWRAP_ARGS+=(--bind "${HOME}/.docker" "${HOME}/.docker")
  fi

  # Podman: Rootful ソケット
  local podman_sock="/run/podman/podman.sock"
  if [[ -S $podman_sock ]]; then
    BWRAP_ARGS+=(--bind "$podman_sock" "$podman_sock")
  fi

  # Podman: Rootless ソケット (XDG_RUNTIME_DIR/podman/podman.sock)
  local rootless_podman="${XDG_RUNTIME}/podman/podman.sock"
  if [[ -S $rootless_podman ]]; then
    BWRAP_ARGS+=(--bind "$(dirname "$rootless_podman")" "$(dirname "$rootless_podman")")
  fi

  # Podman/Buildah 設定 (~/.config/containers/) を公開
  if [[ -d "${HOME}/.config/containers" ]]; then
    mkdir -p "${OPENCODE_HOME}/.config/containers"
    BWRAP_ARGS+=(--ro-bind "${HOME}/.config/containers" "${HOME}/.config/containers")
  fi

  # Podman データ (~/.local/share/containers/) を公開
  if [[ -d "${HOME}/.local/share/containers" ]]; then
    mkdir -p "${OPENCODE_HOME}/.local/share/containers"
    BWRAP_ARGS+=(--bind "${HOME}/.local/share/containers" "${HOME}/.local/share/containers")
  fi
}

# Waylandクリップボード: コンポジターソケットをバインドして wl-copy/wl-paste をホスト側に届ける
# X11 は入力注入等のリスクがあるため公開しない
display_clipboard() {
  if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    # WAYLAND_DISPLAY が絶対パスの場合はそのまま、相対名なら XDG_RUNTIME_DIR 配下に解決
    local wayland_socket
    if [[ ${WAYLAND_DISPLAY} == /* ]]; then
      wayland_socket="${WAYLAND_DISPLAY}"
    else
      wayland_socket="${XDG_RUNTIME}/${WAYLAND_DISPLAY}"
    fi
    if [[ -S $wayland_socket ]]; then
      BWRAP_ARGS+=(
        --ro-bind "$wayland_socket" "$wayland_socket"
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
        --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME"
        # WAYLAND_SOCKET (FD番号) が漏れ込んで別ソケットを参照するのを防ぐ
        --unsetenv WAYLAND_SOCKET
      )
    fi
  fi
}

# ターミナル環境の転送
terminal_env() {
  # TERM を転送
  if [[ -n ${TERM:-} ]]; then
    BWRAP_ARGS+=(--setenv TERM "$TERM")
  fi

  # TERMINFO / TERMINFO_DIRS を転送 (NixOS のterminfo検索に必要)
  if [[ -n ${TERMINFO:-} ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO "$TERMINFO")
  fi
  if [[ -n ${TERMINFO_DIRS:-} ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO_DIRS "$TERMINFO_DIRS")
  fi
}

# =============================================================================
# セットアップ & 起動
# =============================================================================

# 一時ホームのクリーンアップ (mktemp -d で作成済み)
trap 'rm -rf "$OPENCODE_HOME"' EXIT INT TERM

# OpenCode 設定ディレクトリの確保
mkdir -p "$OPENCODE_CONFIG"

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
gpg_agent
container_socket
terminal_env
display_clipboard

# プロジェクト固有のサンドボックス拡張: .opencode/sandbox-extra.sh があれば読み込む
SANDBOX_EXTRA="${REPO_ROOT}/.opencode/sandbox-extra.sh"
if [[ -f $SANDBOX_EXTRA ]]; then
  # shellcheck source=/dev/null
  source "$SANDBOX_EXTRA"
fi

# サンドボックス内で実行するスクリプトの組み立て
# TTY がある場合は tmux セッション内で起動 (OMO の tmux ペイン分割を有効化)
# 非対話環境 (パイプ等) では直接実行
INNER_SCRIPT='
cd "$1"; shift
if [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
  tmux new-session -s opencode -- "$@" && exit $?
fi
exec "$@"
'

exec bwrap "${BWRAP_ARGS[@]}" \
  bash -c "$INNER_SCRIPT" bash "$PROJECT_DIR" "$OPENCODE_BIN" "$@"
