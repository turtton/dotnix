#!/usr/bin/env bash
set -u

PROJECT_DIR=$1
SENPI_BIN=$2
shift 2

cd "$PROJECT_DIR"

if [[ -z ${HERDR_SESSION:-} || -z ${HERDR_PANE_ID:-} ]]; then
  exec "$SENPI_BIN" "$@"
fi

pids=()
cleanup() {
  local pid
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if gh auth status >/dev/null 2>&1; then
  bash "@quota-script@" &
  pids+=("$!")
fi
bash "@openai-quota-script@" &
pids+=("$!")
bash "@crof-quota-script@" &
pids+=("$!")
bash "@openrouter-quota-script@" &
pids+=("$!")
bash "@claude-quota-script@" &
pids+=("$!")
bash "@kimi-quota-script@" &
pids+=("$!")

"$SENPI_BIN" "$@"
status=$?
exit "$status"
