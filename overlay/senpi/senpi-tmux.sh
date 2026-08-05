#!/usr/bin/env bash
# senpi を tmux セッション内で起動し、status-right に各種 LLM プロバイダの
# quota を表示するラッパー (overlay/opencode/sandbox.sh の tmux 部分の簡略版)。
# bwrap サンドボックスは行わない。
set -euo pipefail

SENPI_BIN="@senpi-dir@/senpi"

# バイパス条件: SENPI_NO_TMUX=1、非 TTY (パイプ/activation 等)
if [ -n "${SENPI_NO_TMUX:-}" ] || [ ! -t 0 ] || [ ! -t 1 ]; then
  exec "$SENPI_BIN" "$@"
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/senpi-tmux"
mkdir -p "$STATE_DIR"

pids=()

# quota ポーリングスクリプトをデプロイしてバックグラウンド起動する。
# スクリプトは overlay/opencode/ 配下のものを共用 (__OUTPUT_PATH__ を置換)。
start_poll() {
  local name="$1" src="$2"
  local out="$STATE_DIR/$name-quota"
  local script="$STATE_DIR/$name-quota-poll.sh"
  [ -f "$out" ] || : >"$out"
  install -m 755 "$src" "$script"
  sed -i "s|__OUTPUT_PATH__|$out|g" "$script"
  "$script" &
  pids+=($!)
}

start_poll copilot "@quota-script@"
start_poll openai "@openai-quota-script@"
start_poll crof "@crof-quota-script@"
start_poll openrouter "@openrouter-quota-script@"
start_poll claude "@claude-quota-script@"
start_poll kimi "@kimi-quota-script@"

TMUX_CONF="$STATE_DIR/tmux.conf"
install -m 644 "@tmux-conf@" "$TMUX_CONF"
sed -i "s|__QUOTA_FILE__|$STATE_DIR/copilot-quota|g" "$TMUX_CONF"
for name in openai crof openrouter claude kimi; do
  upper=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')
  sed -i "s|__${upper}_QUOTA_FILE__|$STATE_DIR/$name-quota|g" "$TMUX_CONF"
done

# ネスト検出を防ぐためホスト側の tmux 環境変数を消す
unset TMUX TMUX_PANE || true

# senpi プロセス配下で senpi が再起動された場合に tmux ラッパーが二重に走らないよう、
# バイパスフラグを伝播する (opencode の OPENCODE_NO_SANDBOX と同じパターン)
export SENPI_NO_TMUX=1

# セッション名を起動元ディレクトリから導出する。同じディレクトリからの
# 起動は同じセッションにアタッチされ、別ディレクトリなら別セッションになる。
# tmux はセッション名に . と : を受け付けないためサニタイズし、
# 同名ディレクトリの衝突はパスのハッシュで区別する
dir_name=$(basename "$PWD" | tr -c '[:alnum:]_\n-' '-')
dir_hash=$(printf '%s' "$PWD" | sha256sum | cut -c1-8)
tmux -f "$TMUX_CONF" new-session -A -s "senpi-$dir_name-$dir_hash" -- "$SENPI_BIN" "$@"

for pid in "${pids[@]}"; do
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
done
