#!/usr/bin/env bash
set -u

PROJECT_DIR=$1
OPENCODE_BIN=$2
shift 2

cd "$PROJECT_DIR"

port="${OPENCODE_PORT:-4096}"
actual_port=$port
has_port=false
port_valid=false
grab_next=false
for arg in "$@"; do
  if $grab_next; then
    case "$arg" in
    -* | "") grab_next=false ;;
    *)
      actual_port=$arg
      port_valid=true
      grab_next=false
      ;;
    esac
    continue
  fi
  case "$arg" in
  --) break ;;
  --port=?*)
    has_port=true
    port_valid=true
    actual_port="${arg#--port=}"
    ;;
  --port=) has_port=true ;;
  --port)
    has_port=true
    grab_next=true
    ;;
  esac
done

if ! $has_port; then
  set -- "$@" --port "$port"
fi

if { ! $port_valid && $has_port; } || [[ $actual_port == 0 ]]; then
  actual_port=N/A
fi

if [[ -z ${HERDR_SESSION:-} || -z ${HERDR_PANE_ID:-} ]]; then
  exec "$OPENCODE_BIN" "$@"
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

(
  while true; do
    "@quota-report@" opencode_port "$actual_port" || true
    sleep 180
  done
) &
pids+=("$!")

"$OPENCODE_BIN" "$@"
status=$?
exit "$status"
