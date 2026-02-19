# =============================================================================
# Variables
# =============================================================================

CLAUDE_CODE_BIN="${CLAUDE_CODE_BIN:-@claude-code-dir@/claude}"

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")"
CLAUDE_CONFIG="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"

# Share tree: repo が $HOME 配下なら最上位ディレクトリまで ro 公開
REAL_REPO="$(realpath "$REPO_ROOT")"
REAL_HOME="$(realpath "$HOME")"
if [[ $REAL_REPO == "$REAL_HOME/"* ]]; then
  rel="${REAL_REPO#"$REAL_HOME"/}"
  SHARE_TREE="${REAL_HOME}/${rel%%/*}"
else
  SHARE_TREE="$REAL_REPO"
fi

# =============================================================================
# Seatbelt プロファイル生成
# =============================================================================

build_seatbelt_profile() {
  cat <<'SEATBELT_EOF'
(version 1)

;; デフォルト全拒否
(deny default)

;; プロセス実行・フォーク・シグナル
(allow process-exec)
(allow process-fork)
(allow signal)

;; Mach IPC (macOS サービスに必要)
(allow mach-lookup)
(allow mach-register)

;; POSIX IPC
(allow ipc-posix-shm-read-data)
(allow ipc-posix-shm-write-data)
(allow ipc-posix-shm-read-metadata)
(allow ipc-posix-shm-write-create)
(allow ipc-posix-shm-write-unlink)
(allow ipc-posix-sem*)

;; sysctl 読み取り
(allow sysctl-read)

;; ネットワーク全許可
(allow network*)

;; システムパス読み取り
(allow file-read*
  (subpath "/usr")
  (subpath "/bin")
  (subpath "/sbin")
  (subpath "/Library")
  (subpath "/System")
  (subpath "/Applications")
  (subpath "/private/etc")
  (subpath "/dev")
  (subpath "/nix"))

;; temp 読み書き
(allow file-read* file-write*
  (subpath (param "TMPDIR"))
  (subpath "/private/tmp")
  (subpath "/private/var/folders"))

;; Nix ストア読み取り + デーモンソケット読み書き
(allow file-read* (subpath "/nix"))
(allow file-read* file-write*
  (subpath "/nix/var/nix/daemon-socket"))

;; プロジェクト: SHARE_TREE 読み取り
(allow file-read*
  (subpath (param "SHARE_TREE")))
;; REPO_ROOT 読み書き
(allow file-read* file-write*
  (subpath (param "REPO_ROOT")))

;; Claude 設定読み書き
(allow file-read* file-write*
  (subpath (param "CLAUDE_CONFIG")))
(allow file-read* file-write*
  (literal (param "CLAUDE_JSON")))

;; Git 設定読み取り
(allow file-read*
  (literal (param "GITCONFIG"))
  (subpath (param "GIT_CONFIG_DIR")))

;; GitHub CLI 読み取り
(allow file-read*
  (subpath (param "GH_CONFIG_DIR")))

;; SSH agent ソケット読み書き
(allow file-read* file-write*
  (literal (param "SSH_AUTH_SOCK")))

;; GPG 読み書き
(allow file-read* file-write*
  (subpath (param "GNUPG_DIR")))

;; IDE 連携読み取り
(allow file-read*
  (subpath (param "IDE_DIR")))

;; Chrome 拡張: ブリッジソケット読み書き
(allow file-read* file-write*
  (subpath (param "BRIDGE_DIR")))

;; ブラウザ NativeMessagingHosts 読み書き
(allow file-read* file-write*
  (subpath (param "NATIVE_MSG_0"))
  (subpath (param "NATIVE_MSG_1"))
  (subpath (param "NATIVE_MSG_2"))
  (subpath (param "NATIVE_MSG_3"))
  (subpath (param "NATIVE_MSG_4"))
  (subpath (param "NATIVE_MSG_5")))

;; HOME 直下の読み取り (dotfile アクセス等)
(allow file-read*
  (subpath (param "HOME")))
SEATBELT_EOF
}

# =============================================================================
# パラメータ収集
# =============================================================================

# Claude 設定ファイルの確保
mkdir -p "$CLAUDE_CONFIG"
[[ -f $CLAUDE_JSON ]] || touch "$CLAUDE_JSON"

# GPG: デーモン事前起動
gpgconf --launch gpg-agent 2>/dev/null || true
gpgconf --launch keyboxd 2>/dev/null || true
gpgconf --launch dirmngr 2>/dev/null || true

GNUPG_DIR="${HOME}/.gnupg"
mkdir -p "$GNUPG_DIR"

# Chrome 拡張: ブリッジソケットディレクトリ
BRIDGE_DIR="/private/tmp/claude-mcp-browser-bridge-${USER}"
mkdir -p "$BRIDGE_DIR"

# NativeMessagingHosts パス収集 (macOS のブラウザ設定パス)
NATIVE_MSG_PATHS=()
mac_browsers=("Google Chrome" "Chromium" "BraveSoftware/Brave-Browser" "Microsoft Edge" "Vivaldi" "Opera")
for browser in "${mac_browsers[@]}"; do
  host_dir="${HOME}/Library/Application Support/${browser}/NativeMessagingHosts"
  if [[ -d "${HOME}/Library/Application Support/${browser}" ]]; then
    mkdir -p "$host_dir"
    NATIVE_MSG_PATHS+=("$host_dir")
  fi
done
# 不足分を /dev/null で埋めて常に 6 スロット確保
while [[ ${#NATIVE_MSG_PATHS[@]} -lt 6 ]]; do
  NATIVE_MSG_PATHS+=("/dev/null")
done

# TMPDIR のデフォルト
SANDBOX_TMPDIR="${TMPDIR:-/private/tmp}"
# macOS の TMPDIR は末尾に / が付くことがあるので除去
SANDBOX_TMPDIR="${SANDBOX_TMPDIR%/}"

# IDE 連携ディレクトリ
IDE_DIR="${HOME}/.claude/ide"
mkdir -p "$IDE_DIR"

# =============================================================================
# サンドボックス実行
# =============================================================================

PROFILE_FILE="$(mktemp "${SANDBOX_TMPDIR}/claude-seatbelt-XXXXXXXX.sb")"
trap 'rm -f "$PROFILE_FILE"' EXIT INT TERM

build_seatbelt_profile >"$PROFILE_FILE"

exec sandbox-exec -f "$PROFILE_FILE" \
  -D "HOME=${HOME}" \
  -D "TMPDIR=${SANDBOX_TMPDIR}" \
  -D "SHARE_TREE=${SHARE_TREE}" \
  -D "REPO_ROOT=${REPO_ROOT}" \
  -D "CLAUDE_CONFIG=${CLAUDE_CONFIG}" \
  -D "CLAUDE_JSON=${CLAUDE_JSON}" \
  -D "GITCONFIG=${HOME}/.gitconfig" \
  -D "GIT_CONFIG_DIR=${HOME}/.config/git" \
  -D "GH_CONFIG_DIR=${HOME}/.config/gh" \
  -D "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-/dev/null}" \
  -D "GNUPG_DIR=${GNUPG_DIR}" \
  -D "IDE_DIR=${IDE_DIR}" \
  -D "BRIDGE_DIR=${BRIDGE_DIR}" \
  -D "NATIVE_MSG_0=${NATIVE_MSG_PATHS[0]}" \
  -D "NATIVE_MSG_1=${NATIVE_MSG_PATHS[1]}" \
  -D "NATIVE_MSG_2=${NATIVE_MSG_PATHS[2]}" \
  -D "NATIVE_MSG_3=${NATIVE_MSG_PATHS[3]}" \
  -D "NATIVE_MSG_4=${NATIVE_MSG_PATHS[4]}" \
  -D "NATIVE_MSG_5=${NATIVE_MSG_PATHS[5]}" \
  bash -c "cd '${PROJECT_DIR}' && exec '${CLAUDE_CODE_BIN}' --dangerously-skip-permissions"
