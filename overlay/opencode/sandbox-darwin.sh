# =============================================================================
# Variables
# =============================================================================

OPENCODE_BIN="${OPENCODE_BIN:-@opencode-dir@/opencode}"

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"
OPENCODE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/opencodebox-XXXXXXXX")"
OPENCODE_CONFIG="${HOME}/.config/opencode"

# HOME 変更前に実パスを確定 (後で HOME を OPENCODE_HOME に切り替えるため)
REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"

# Share tree: repo が $HOME 配下なら最上位ディレクトリまで公開
if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

# =============================================================================
# 各責務の関数
# =============================================================================

# 隔離ホームディレクトリ: 必要な設定を symlink でマウントエミュレーション
# macOS はユーザー空間 bind mount 不可のため symlink を使用する
# sandbox-exec の subpath マッチャーはシンボリックリンクを辿った実パスで評価するため、
# リンク先の実ディレクトリも SBPL プロファイルで書き込み許可する必要がある
isolated_home() {
  # OpenCode 設定ディレクトリ全体をマウント (opencode.json, AGENTS.md 等)
  if [[ -d $OPENCODE_CONFIG ]]; then
    mkdir -p "${OPENCODE_HOME}/.config"
    ln -sfn "$OPENCODE_CONFIG" "${OPENCODE_HOME}/.config/opencode"
  fi

  # OpenCode データディレクトリ (auth.json 等)
  local opencode_data="${REAL_HOME}/.local/share/opencode"
  if [[ -d $opencode_data ]]; then
    mkdir -p "${OPENCODE_HOME}/.local/share"
    ln -sfn "$opencode_data" "${OPENCODE_HOME}/.local/share/opencode"
  fi

  # OpenCode キャッシュ (プラグインの node_modules, models.json 等)
  local opencode_cache="${REAL_HOME}/.cache/opencode"
  if [[ -d $opencode_cache ]]; then
    mkdir -p "${OPENCODE_HOME}/.cache"
    ln -sfn "$opencode_cache" "${OPENCODE_HOME}/.cache/opencode"
  fi

  # OpenCode 状態 (frecency, model 選択, プロンプト履歴)
  local opencode_state="${REAL_HOME}/.local/state/opencode"
  if [[ -d $opencode_state ]]; then
    mkdir -p "${OPENCODE_HOME}/.local/state"
    ln -sfn "$opencode_state" "${OPENCODE_HOME}/.local/state/opencode"
  fi

  # Rust ツールチェーン: rustup + cargo
  if [[ -d "${REAL_HOME}/.rustup" ]]; then
    ln -sfn "${REAL_HOME}/.rustup" "${OPENCODE_HOME}/.rustup"
  fi
  if [[ -d "${REAL_HOME}/.cargo" ]]; then
    ln -sfn "${REAL_HOME}/.cargo" "${OPENCODE_HOME}/.cargo"
  fi
}

# Git 設定: ~/.gitconfig と ~/.config/git/ を読み取り専用で公開
git_config() {
  if [[ -f "${REAL_HOME}/.gitconfig" ]]; then
    cp "${REAL_HOME}/.gitconfig" "${OPENCODE_HOME}/.gitconfig"
  fi
  if [[ -d "${REAL_HOME}/.config/git" ]]; then
    mkdir -p "${OPENCODE_HOME}/.config"
    ln -sfn "${REAL_HOME}/.config/git" "${OPENCODE_HOME}/.config/git"
  fi
}

# GitHub CLI: ~/.config/gh/ を公開
gh_cli() {
  if [[ -d "${REAL_HOME}/.config/gh" ]]; then
    mkdir -p "${OPENCODE_HOME}/.config"
    ln -sfn "${REAL_HOME}/.config/gh" "${OPENCODE_HOME}/.config/gh"
  fi
}

# GPG エージェント: macOS では gnupg ディレクトリを symlink で公開
# macOS の GPG ソケットは ~/.gnupg/ 内にあるため、ディレクトリ全体を symlink する
gpg_agent() {
  gpgconf --launch gpg-agent 2>/dev/null || true

  if [[ -d "${REAL_HOME}/.gnupg" ]]; then
    ln -sfn "${REAL_HOME}/.gnupg" "${OPENCODE_HOME}/.gnupg"
  fi
}

# コンテナ設定: Docker/OrbStack の設定ディレクトリを公開
# ソケット自体 (/var/run/docker.sock) は $HOME 外にあるため sandbox-exec で自動許可
container_socket() {
  if [[ -d "${REAL_HOME}/.docker" ]]; then
    ln -sfn "${REAL_HOME}/.docker" "${OPENCODE_HOME}/.docker"
  fi
}

# OMO 用ポート検出: macOS では lsof を使用 (Linux の ss に相当)
opencode_port() {
  if [[ -n ${OPENCODE_PORT:-} ]]; then
    return
  fi

  local free_port=""
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

# sandbox-exec SBPL プロファイルを生成して stdout に出力する
#
# セキュリティモデル:
#   - (allow default): 全操作をデフォルト許可 (読み込み制限なし)
#   - (deny file-write* REAL_HOME): ホームへの書き込みを拒否
#   - (allow file-write* ...): opencode が必要とするパスのみ書き込み許可
#
# 注: Linux bwrap と異なり読み込みは制限しない (macOS ユーザー空間では実現困難)
# sandbox-exec は proc ツリー全体に適用されるため、子プロセス (tmux, opencode) も保護対象
build_sandbox_profile() {
  local allow_writes=()

  # 常に許可: 隔離ホーム・プロジェクト・一時ディレクトリ
  allow_writes+=("$OPENCODE_HOME")
  allow_writes+=("$REAL_REPO")
  allow_writes+=("/tmp")
  allow_writes+=("/private/tmp")
  # macOS の NSTemporaryDirectory は /private/var/folders 以下
  # /var/folders は /private/var/folders へのシンボリックリンク
  allow_writes+=("/private/var/folders")
  allow_writes+=("/var/folders")

  # opencode 固有ディレクトリ
  # symlink 越しのアクセスは sandbox-exec が実パスで評価するため、リンク先も許可必須
  local rw_dirs=(
    "${REAL_HOME}/.config/opencode"
    "${REAL_HOME}/.local/share/opencode"
    "${REAL_HOME}/.cache/opencode"
    "${REAL_HOME}/.local/state/opencode"
    "${REAL_HOME}/.cargo"
    "${REAL_HOME}/.rustup"
    "${REAL_HOME}/.docker"
  )
  for dir in "${rw_dirs[@]}"; do
    [[ -d $dir ]] && allow_writes+=("$dir")
  done

  {
    echo "(version 1)"
    echo ""
    echo "; デフォルト: 全操作を許可"
    echo "(allow default)"
    echo ""
    echo "; ホームディレクトリへの書き込みを拒否"
    printf '(deny file-write* (subpath "%s"))\n' "${REAL_HOME}"
    echo ""
    echo "; opencode が必要とするパスへの書き込みを許可"
    echo "(allow file-write*"
    for path in "${allow_writes[@]}"; do
      printf '  (subpath "%s")\n' "$path"
    done
    echo ")"
  }
}

# =============================================================================
# セットアップ & 起動
# =============================================================================

trap 'rm -rf "$OPENCODE_HOME"' EXIT INT TERM

# OpenCode 設定ディレクトリの確保
mkdir -p "$OPENCODE_CONFIG"

# 各関数を順に呼び出してセットアップ
isolated_home
git_config
gh_cli
gpg_agent
container_socket

# プロジェクト固有のサンドボックス拡張: .opencode/sandbox-extra.sh があれば読み込む
SANDBOX_EXTRA="${REPO_ROOT}/.opencode/sandbox-extra.sh"
if [[ -f $SANDBOX_EXTRA ]]; then
  # shellcheck source=/dev/null
  source "$SANDBOX_EXTRA"
fi

# sandbox-exec プロファイルを生成
build_sandbox_profile >"${OPENCODE_HOME}/.sandbox.sb"

# OMO 用ポート検出 (環境変数 OPENCODE_PORT に設定)
opencode_port

# HOME を隔離ホームに切り替え (以降の $HOME は OPENCODE_HOME を指す)
export HOME="$OPENCODE_HOME"
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
export OPENCODE_NO_SANDBOX=1
export TMPDIR="${TMPDIR:-/tmp}"
export USER="${USER:-$(id -un)}"
# tmux: ホスト側の TMUX 変数を消す (ネスト検出を防ぎ、独立した tmux セッションを起動)
unset TMUX
unset TMUX_PANE
unset TMUX_TMPDIR

# tmux 設定・quota 関連ファイルのセットアップ
# HOME がすでに OPENCODE_HOME に切り替わっているため、${HOME}/... = OPENCODE_HOME/...
printf '%s\n' "N/A" >"${HOME}/.copilot-quota"
printf '%s' "N/A" >"${HOME}/.opencode-port"
cp "@quota-script@" "${HOME}/.copilot-quota-poll.sh"
# macOS: BSD sed は -i '' が必要 (GNU sed と異なる)
sed -i '' "s|__OUTPUT_PATH__|${HOME}/.copilot-quota|g" "${HOME}/.copilot-quota-poll.sh"
chmod +x "${HOME}/.copilot-quota-poll.sh"
cp "@tmux-conf@" "${HOME}/.tmux.conf"
sed -i '' "s|__QUOTA_FILE__|${HOME}/.copilot-quota|g" "${HOME}/.tmux.conf"
sed -i '' "s|__PORT_FILE__|${HOME}/.opencode-port|g" "${HOME}/.tmux.conf"

# サンドボックス内で実行するスクリプトの組み立て (Linux 版と同一ロジック)
# --port: OMO がサブエージェントペインで `opencode attach` するために HTTP API の TCP リスナーが必要
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

exec sandbox-exec -f "${OPENCODE_HOME}/.sandbox.sb" \
  bash -c "$INNER_SCRIPT" bash "$PROJECT_DIR" "$OPENCODE_BIN" "$@"
