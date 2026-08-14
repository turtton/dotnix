#!/usr/bin/env bash
set -u

PROJECT_DIR=$1
OPENCODE_BIN=$2
shift 2

cd "$PROJECT_DIR"

attach_mode=false
if [[ ${1:-} == attach ]]; then
  attach_mode=true
fi

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

# attach には --port オプションが無いため付与しない
if ! $attach_mode && ! $has_port; then
  set -- "$@" --port "$port"
fi

if { ! $port_valid && $has_port; } || [[ $actual_port == 0 ]]; then
  actual_port=N/A
fi

if $attach_mode; then
  actual_port=${2##*:}
  actual_port=${actual_port%%/*}
fi

if [[ -z ${HERDR_SESSION:-} || -z ${HERDR_PANE_ID:-} ]]; then
  exec "$OPENCODE_BIN" "$@"
fi

pids=()
registry_file=""
cleanup() {
  local pid
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  if [[ -n $registry_file && -f $registry_file ]] &&
    jq -e --argjson pid $$ '.pid == $pid' "$registry_file" >/dev/null 2>&1; then
    rm -f "$registry_file"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# サブコマンド起動時は TUI のサーバーが立たないため登録しない (opencode CLI のサブコマンド一覧に依存)
case ${1:-} in
attach | run | serve | web | acp | mcp | debug | providers | auth | agent | upgrade | uninstall | models | stats | export | import | github | pr | session | plugin | plug | db | completion) ;;
*)
  if [[ $actual_port =~ ^[0-9]+$ ]]; then
    registry_dir="$HOME/.local/state/opencode/herdr-servers"
    registry_file="$registry_dir/$(printf %s "$(pwd -P)" | sha1sum | cut -d' ' -f1).json"
    (
      for _ in $(seq 1 100); do
        if curl -sf -m 1 "http://127.0.0.1:${actual_port}/global/health" >/dev/null 2>&1; then
          mkdir -p "$registry_dir"
          jq -n --arg url "http://127.0.0.1:${actual_port}" --arg cwd "$(pwd -P)" --argjson pid $$ \
            '{url: $url, cwd: $cwd, pid: $pid}' >"$registry_file.tmp"
          mv "$registry_file.tmp" "$registry_file"
          break
        fi
        sleep 0.1
      done
    ) &
    pids+=("$!")
  fi
  ;;
esac

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
