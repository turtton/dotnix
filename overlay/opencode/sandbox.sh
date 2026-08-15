# =============================================================================
# Variables
# =============================================================================

OPENCODE_BIN="${OPENCODE_BIN:-@opencode-dir@/opencode}"

if [[ -n ${OPENCODE_NO_SANDBOX:-} && -z ${OPENCODE_HERDR_CHILD:-} ]]; then
  exec "$OPENCODE_BIN" "$@"
fi

PROJECT_DIR="$(pwd)"
CANONICAL_PROJECT_DIR="$(pwd -P)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"

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

launch_herdr_context() {
  local label state_dir lock_dir workspace_json panes_json created process_info
  local workspace_id="" pane_id="" command attempt candidate arg

  label="opencode-$(basename "$CANONICAL_PROJECT_DIR" | LC_ALL=C sed 's/[^[:alnum:]]/-/g')"
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
    pane_id=$(jq -r --arg wid "$candidate" --arg cwd "$CANONICAL_PROJECT_DIR" \
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
    created=$(hcli workspace create --cwd "$CANONICAL_PROJECT_DIR" --label "$label" --focus)
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
    command="env OPENCODE_NO_SANDBOX= OPENCODE_HERDR_CHILD=1 HERDR_SESSION=$(shell_quote "$HERDR_SESSION") HERDR_SOCKET_PATH=$(shell_quote "$HERDR_SOCKET_PATH") HERDR_PANE_ID=$(shell_quote "$pane_id") OPENCODE_BIN=$(shell_quote "$OPENCODE_BIN") $(shell_quote "${BASH_SOURCE[0]}")"
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

# attach に中継できるフラグは `opencode attach --help` から実行時に導出する
# (静的リストは CLI 更新から取り残されるため)。パース失敗時はフラグ付き起動を
# すべて herdr フローに回す安全側フォールバック
attach_flag_table() {
  local bin_id cache_dir cache parsed
  bin_id=$(readlink -f "$OPENCODE_BIN" | sha1sum | cut -d' ' -f1)
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
  cache="$cache_dir/attach-flags-$bin_id"
  if [[ ! -f $cache ]]; then
    # yargs は端末幅でオプション行を折り返すため COLUMNS を固定し、
    # opencode の help は stderr に出るため 2>&1 で拾う
    parsed=$(COLUMNS=1000 "$OPENCODE_BIN" attach --help 2>&1 | awk '
      function flush() {
        if (has) {
          if (cur == "") cur = "b"
          if (s != "") print cur ":" s
          if (l != "") print cur ":" l
        }
        has = 0; s = ""; l = ""; cur = ""
      }
      /^ +(-[a-z], |--)/ {
        flush()
        has = 1
        if (match($0, /-[a-z],/)) s = substr($0, RSTART, 2)
        if (match($0, /--[a-z][a-z-]*/)) l = substr($0, RSTART, RLENGTH)
        if ($0 ~ /\[(string|number|array)\]/) cur = "v"
        else if ($0 ~ /\[boolean\]/) cur = "b"
        next
      }
      # 型マーカー ([string] 等) だけが折り返された継続行を前行のオプションに帰属させる
      /^ +\[/ {
        if (has && cur == "") {
          if ($0 ~ /\[(string|number|array)\]/) cur = "v"
          else if ($0 ~ /\[boolean\]/) cur = "b"
        }
        next
      }
      { flush() }
      END { flush() }')
    [[ -n $parsed ]] || return 1
    mkdir -p "$cache_dir"
    printf '%s\n' "$parsed" >"$cache.$$"
    mv "$cache.$$" "$cache"
  fi
  cat "$cache"
}

flag_known() { grep -qFx "b:$1" <<<"$attach_flags" || grep -qFx "v:$1" <<<"$attach_flags"; }
flag_takes_value() { grep -qFx "v:$1" <<<"$attach_flags"; }

ATTACH_URL=""
skip_herdr=false
if [[ -z ${OPENCODE_HERDR_CHILD:-} && -n ${HERDR_ENV:-} ]]; then
  attach_flags=$(attach_flag_table || true)
  is_plain_tui=true
  expect_value=false
  for arg in "$@"; do
    if $expect_value; then
      expect_value=false
      continue
    fi
    case $arg in
    # help/version は pane 移動せずその場で出力する
    -h | --help | -v | --version) skip_herdr=true ;;
    --*=*) flag_known "${arg%%=*}" || is_plain_tui=false ;;
    -*)
      if flag_takes_value "$arg"; then
        expect_value=true
      elif ! flag_known "$arg"; then
        is_plain_tui=false
      fi
      ;;
    *) is_plain_tui=false ;;
    esac
  done
  if $is_plain_tui && ! $skip_herdr; then
    server_registry="${HOME}/.local/state/opencode/herdr-servers/$(printf %s "$CANONICAL_PROJECT_DIR" | sha1sum | cut -d' ' -f1).json"
    if [[ -f $server_registry ]]; then
      shared_url=$(jq -r '.url // empty' "$server_registry" 2>/dev/null || true)
      if [[ -n $shared_url ]] && curl -sf -m 2 "$shared_url/global/health" >/dev/null 2>&1; then
        ATTACH_URL=$shared_url
        # OMO が正しいサーバーに接続できるよう共有サーバーのポートを引き継ぐ
        OPENCODE_PORT=${ATTACH_URL##*:}
      fi
    fi
  fi
fi

if [[ -z ${OPENCODE_HERDR_CHILD:-} && -n ${HERDR_ENV:-} && -z $ATTACH_URL ]] && ! $skip_herdr; then
  if launch_herdr_context "$@"; then
    exit 0
  fi
fi

# メモリ節約: /var/tmp (ディスク) を優先し、失敗時のみ tmpfs にフォールバック
if ! OPENCODE_HOME="$(mktemp -d /var/tmp/opencodebox-XXXXXXXX 2>/dev/null)"; then
  OPENCODE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")"
fi
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
if [[ -n ${OPENCODE_CONFIG_DIR:-} && ${OPENCODE_CONFIG_DIR:0:1} != "/" ]]; then
  echo "opencode-sandbox: ERROR: OPENCODE_CONFIG_DIR must be an absolute path" >&2
  exit 1
fi
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

  if [[ -n ${HERDR_SOCKET_PATH:-} ]]; then
    local socket_dir
    socket_dir=$(dirname "$HERDR_SOCKET_PATH")
    if [[ $socket_dir == "$REAL_HOME"/* ]]; then
      mkdir -p "${OPENCODE_HOME}${socket_dir#"$REAL_HOME"}"
      BWRAP_ARGS+=(--bind "$socket_dir" "$socket_dir")
    fi
  fi

  # OpenCode 設定ディレクトリ全体をマウント (opencode.json, AGENTS.md等)
  if [[ -d $OPENCODE_CONFIG ]]; then
    local target_dir="${HOME}${OPENCODE_CONFIG#"$REAL_HOME"}"
    mkdir -p "${OPENCODE_HOME}${OPENCODE_CONFIG#"$REAL_HOME"}"
    BWRAP_ARGS+=(--bind "$OPENCODE_CONFIG" "$target_dir")
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

  # OMO 設定・状態ディレクトリ (omo.jsonc と codegraph/lsp-daemon 等のランタイム)
  local omo_dir="${HOME}/.omo"
  if [[ -d $omo_dir ]]; then
    mkdir -p "${OPENCODE_HOME}/.omo"
    BWRAP_ARGS+=(--bind "$omo_dir" "${HOME}/.omo")
  fi

  # Claude Code 認証情報 (claude-quota-poll.sh が ~/.claude/.credentials.json を
  # 参照し、リフレッシュ時に新トークンを書き戻すため読み書きで公開)
  local claude_dir="${HOME}/.claude"
  if [[ -d $claude_dir ]]; then
    mkdir -p "${OPENCODE_HOME}/.claude"
    BWRAP_ARGS+=(--bind "$claude_dir" "${HOME}/.claude")
  fi

  # Rust ツールチェーン: rustup + cargo を読み書きで公開
  if [[ -d "${HOME}/.rustup" ]]; then
    mkdir -p "${OPENCODE_HOME}/.rustup"
    BWRAP_ARGS+=(--bind "${HOME}/.rustup" "${HOME}/.rustup")
  fi
  if [[ -d "${HOME}/.cargo" ]]; then
    mkdir -p "${OPENCODE_HOME}/.cargo"
    BWRAP_ARGS+=(--bind "${HOME}/.cargo" "${HOME}/.cargo")
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

  local herdr_vars=(HERDR_SESSION HERDR_SOCKET_PATH HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID)
  for var in "${herdr_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done

  # XDG Base Directory 変数の転送 (opencode は XDG 準拠)
  # XDG_RUNTIME_DIR: Wayland, podman rootless ソケット等が依存
  local xdg_vars=(XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME XDG_RUNTIME_DIR)
  for var in "${xdg_vars[@]}"; do
    if [[ -n ${!var:-} ]]; then
      BWRAP_ARGS+=(--setenv "$var" "${!var}")
    fi
  done

  # OPENCODE_CONFIG_DIR の転送: alt プロファイル等のカスタム設定ディレクトリ指定用
  if [[ -n ${OPENCODE_CONFIG_DIR:-} ]]; then
    local target_dir="${HOME}${OPENCODE_CONFIG#"$REAL_HOME"}"
    BWRAP_ARGS+=(--setenv OPENCODE_CONFIG_DIR "$target_dir")
  fi
}

# プロジェクトマウント: 親ツリーは ro、リポジトリルートは rw
# worktree サポート: git-common-dir が git-dir と異なる場合 (linked worktree)、
# メインリポジトリを先に ro マウントし、REPO_ROOT の rw バインドで上書きする
project_mount() {
  if [[ $SHARE_TREE != "$REPO_ROOT" ]]; then
    BWRAP_ARGS+=(--ro-bind "$SHARE_TREE" "$SHARE_TREE")
  fi

  # --path-format=absolute: サブディレクトリ実行時の相対パス返却を回避
  # || true: git リポジトリ外では rev-parse が 128 で失敗し、
  # writeShellApplication の errexit でスクリプト全体が中断するのを防ぐ
  local git_dir git_common_dir main_repo_root
  git_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
  git_common_dir="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [[ -n $git_dir && -n $git_common_dir && $git_common_dir != "$git_dir" ]]; then
    main_repo_root="$(realpath "${git_common_dir}/.." 2>/dev/null)"
    # 失敗時・SHARE_TREE 配下なら既存マウントで到達可能なため追加不要
    if [[ -n $main_repo_root && -d $main_repo_root ]] &&
      [[ $main_repo_root != "$SHARE_TREE" && $main_repo_root != "$REPO_ROOT" ]] &&
      [[ $main_repo_root != "$SHARE_TREE/"* ]]; then
      BWRAP_ARGS+=(--ro-bind "$main_repo_root" "$main_repo_root")
    fi
    # worktree の git 操作は共通 .git への書き込みを要するため、ro マウント後に rw で上書きする
    BWRAP_ARGS+=(--bind "$git_common_dir" "$git_common_dir")
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

# isolated_home が bind mount する前提のため先に作る (attach サーバー登録の置き場)
mkdir -p "${HOME}/.local/state/opencode"

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

if [[ -n $ATTACH_URL ]]; then
  set -- attach "$ATTACH_URL" "$@"
fi

exec bwrap "${BWRAP_ARGS[@]}" \
  bash "@child-wrapper@" "$PROJECT_DIR" "$OPENCODE_BIN" "$@"
