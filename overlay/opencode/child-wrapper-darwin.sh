#!/usr/bin/env bash

set -u

project_dir=$1
shift
opencode_bin=$1
shift

poller_pids=()

cleanup() {
  local pid
  for pid in "${poller_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  rm -rf "$HOME"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

report_port() {
  local port=$1
  "@quota-report@" opencode_port "$port" >/dev/null 2>&1 || true
}

poll_port() {
  local port=$1
  while true; do
    report_port "$port"
    sleep 180
  done
}

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

if [[ -n ${HERDR_SESSION:-} && -n ${HERDR_PANE_ID:-} ]]; then
  if [[ -n ${GH_TOKEN:-} ]] || gh auth status >/dev/null 2>&1; then
    bash "@quota-script@" &
    poller_pids+=("$!")
  fi
  bash "@openai-quota-script@" &
  poller_pids+=("$!")
  bash "@crof-quota-script@" &
  poller_pids+=("$!")
  bash "@openrouter-quota-script@" &
  poller_pids+=("$!")
  bash "@kimi-quota-script@" &
  poller_pids+=("$!")
  poll_port "$actual_port" &
  poller_pids+=("$!")
fi

cd "$project_dir"
"$opencode_bin" "$@"
exit_code=$?
exit "$exit_code"
