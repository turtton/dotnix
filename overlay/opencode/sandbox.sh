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
  # XDG_RUNTIME_DIR: Wayland, podman rootless ソケット等が依存
  local xdg_vars=(XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME XDG_RUNTIME_DIR)
  for var in "${xdg_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done
}

# プロジェクトマウント: 親ツリーは ro、リポジトリルートは rw
# worktree サポート: git-common-dir が git-dir と異なる場合 (linked worktree)、
# メインリポジトリを先に ro マウントし、REPO_ROOT の rw バインドで上書きする
project_mount() {
  if [[ $SHARE_TREE != "$REPO_ROOT" ]]; then
    BWRAP_ARGS+=(--ro-bind "$SHARE_TREE" "$SHARE_TREE")
  fi

  # --path-format=absolute: サブディレクトリ実行時の相対パス返却を回避
  local git_dir git_common_dir main_repo_root
  git_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-dir 2>/dev/null)"
  git_common_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  if [[ -n $git_dir && -n $git_common_dir && $git_common_dir != "$git_dir" ]]; then
    main_repo_root="$(realpath "${git_common_dir}/.." 2>/dev/null)"
    # 失敗時・SHARE_TREE 配下なら既存マウントで到達可能なため追加不要
    if [[ -n $main_repo_root && -d $main_repo_root ]] &&
      [[ $main_repo_root != "$SHARE_TREE" && $main_repo_root != "$REPO_ROOT" ]] &&
      [[ $main_repo_root != "$SHARE_TREE/"* ]]; then
      BWRAP_ARGS+=(--ro-bind "$main_repo_root" "$main_repo_root")
    fi
  fi

  # REPO_ROOT は最後にマウントして rw 権限を確保
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
# サンドボックス内では --unshare-all によりコンテナランタイムの直接実行は不可能なため、
# CONTAINER_HOST を設定してホスト側デーモンへのリモート接続を有効化する
container_socket() {
  local container_host=""

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
    container_host="unix://${rootless_podman}"
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

  if [[ -n $container_host ]]; then
    BWRAP_ARGS+=(--setenv CONTAINER_HOST "$container_host")
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
        # WAYLAND_SOCKET (FD番号) が漏れ込んで別ソケットを参照するのを防ぐ
        --unsetenv WAYLAND_SOCKET
      )
    fi
  fi
}

# ターミナル環境の転送
terminal_env() {
  if [[ -n ${TERM:-} ]]; then
    BWRAP_ARGS+=(--setenv TERM "$TERM")
  fi

  # TERMINFO: sandbox内で見えないパスを指す場合は転送しない
  # (TERMINFO_DIRS より優先されるため、誤ったパスだとterminfoが見つからなくなる)
  if [[ -n ${TERMINFO:-} ]] && [[ -d $TERMINFO ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO "$TERMINFO")
  fi

  # TERMINFO_DIRS: ホスト側パス (~/.nix-profile等) はsandbox内で無効なため、
  # sandbox内からアクセス可能なシステムterminfoを先頭に挿入する
  # (opencode attach が tmux-256color 等を描画するために必要)
  local system_terminfo="/run/current-system/sw/share/terminfo"
  local effective_dirs=""
  if [[ -d $system_terminfo ]]; then
    effective_dirs="${system_terminfo}"
  fi
  if [[ -n ${TERMINFO_DIRS:-} ]]; then
    if [[ -n $effective_dirs ]]; then
      effective_dirs="${effective_dirs}:${TERMINFO_DIRS}"
    else
      effective_dirs="${TERMINFO_DIRS}"
    fi
  fi
  if [[ -n $effective_dirs ]]; then
    BWRAP_ARGS+=(--setenv TERMINFO_DIRS "$effective_dirs")
  fi
}

# OMO用ポート検出: sandbox内opencodeが使う空きポートを検出し OPENCODE_PORT に設定する
# ホスト側で別のopencodeが4096を使っていても競合せず、OMOも正しいサーバーに接続できる
opencode_port() {
  if [[ -n ${OPENCODE_PORT:-} ]]; then
    BWRAP_ARGS+=(--setenv OPENCODE_PORT "$OPENCODE_PORT")
    return
  fi

  if ! command -v ss &>/dev/null || ! command -v grep &>/dev/null; then
    echo "opencode-sandbox: WARNING: ss or grep not found, skipping port detection" >&2
    return
  fi

  local free_port
  for port in $(seq 4097 4200); do
    if ! ss -tlnH "sport = :${port}" 2>/dev/null | grep -q .; then
      free_port=$port
      break
    fi
  done

  if [[ -n $free_port ]]; then
    BWRAP_ARGS+=(--setenv OPENCODE_PORT "$free_port")
  else
    echo "opencode-sandbox: WARNING: no free port found in range 4097-4200; OMO may connect to wrong server" >&2
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
opencode_port

# プロジェクト固有のサンドボックス拡張: .opencode/sandbox-extra.sh があれば読み込む
SANDBOX_EXTRA="${REPO_ROOT}/.opencode/sandbox-extra.sh"
if [[ -f $SANDBOX_EXTRA ]]; then
  # shellcheck source=/dev/null
  source "$SANDBOX_EXTRA"
fi

TMUX_CONF_PATH="${OPENCODE_HOME}/.tmux.conf"
QUOTA_OUTPUT_PATH="${OPENCODE_HOME}/.copilot-quota"
QUOTA_SCRIPT_PATH="${OPENCODE_HOME}/.copilot-quota-poll.sh"
PORT_OUTPUT_PATH="${OPENCODE_HOME}/.opencode-port"

printf '%s\n' "N/A" >"$QUOTA_OUTPUT_PATH"
printf '%s' "N/A" >"$PORT_OUTPUT_PATH"
cp "@quota-script@" "$QUOTA_SCRIPT_PATH"
sed -i "s|__OUTPUT_PATH__|${HOME}/.copilot-quota|g" "$QUOTA_SCRIPT_PATH"
chmod +x "$QUOTA_SCRIPT_PATH"
cp "@tmux-conf@" "$TMUX_CONF_PATH"
sed -i "s|__QUOTA_FILE__|${HOME}/.copilot-quota|g" "$TMUX_CONF_PATH"
sed -i "s|__PORT_FILE__|${HOME}/.opencode-port|g" "$TMUX_CONF_PATH"

# サンドボックス内で実行するスクリプトの組み立て
# TTY がある場合は tmux セッション内で起動 (OMO の tmux ペイン分割を有効化)
# --port: OMO がサブエージェントペインで `opencode attach` するために HTTP API の TCP リスナーが必要
#         デフォルト --port 0 ではリスナーが起動せず、OMO の isServerRunning() ヘルスチェックが失敗する
# 非対話環境 (パイプ等) では直接実行
INNER_SCRIPT='
cd "$1"; shift

port="${OPENCODE_PORT:-4096}"
bin=$1; shift

# ユーザー引数から --port 値を抽出 (-- 以降は位置引数なので打ち切る)
# 複数指定時は最後の有効な値を採用する (opencode CLI と同じ挙動)
actual_port="$port"
has_port=false
port_valid=false
grab_next=false
for arg in "$@"; do
  if $grab_next; then
    case "$arg" in
      -*) grab_next=false ;;
      "") grab_next=false ;;
      *)  actual_port="$arg"; port_valid=true; grab_next=false ;;
    esac
    continue
  fi
  case "$arg" in
    --) break ;;
    --port=?*) has_port=true; port_valid=true; actual_port="${arg#--port=}" ;;
    --port=)   has_port=true ;;
    --port)    has_port=true; grab_next=true ;;
  esac
done

if ! $has_port; then
  set -- "$@" --port "$port"
fi
set -- "$bin" "$@"

# port 0 = listener 無効、has_port かつ値が取れなかった場合も N/A
if ! $port_valid && $has_port; then
  printf '%s' "N/A" > "$HOME/.opencode-port"
elif [ "$actual_port" = "0" ]; then
  printf '%s' "N/A" > "$HOME/.opencode-port"
else
  printf '%s' "$actual_port" > "$HOME/.opencode-port"
fi

if [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
  if gh auth status >/dev/null 2>&1; then
    "$HOME/.copilot-quota-poll.sh" &
    quota_pid=$!
  fi
  tmux -f "$HOME/.tmux.conf" new-session -s opencode -- "$@"
  exit_code=$?
  if [ -n "${quota_pid:-}" ]; then
    kill "$quota_pid" 2>/dev/null; wait "$quota_pid" 2>/dev/null
  fi
  exit $exit_code
fi

exec "$@"
'

exec bwrap "${BWRAP_ARGS[@]}" \
  bash -c "$INNER_SCRIPT" bash "$PROJECT_DIR" "$OPENCODE_BIN" "$@"
