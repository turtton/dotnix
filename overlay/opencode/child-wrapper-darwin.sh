#!/usr/bin/env bash

set -u

project_dir=$1
shift
opencode_bin=$1
shift

poller_pids=()
registry_file=""

cleanup() {
  local pid
  for pid in "${poller_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  if [[ -n $registry_file && -f $registry_file ]] &&
    jq -e --argjson pid $$ '.pid == $pid' "$registry_file" >/dev/null 2>&1; then
    rm -f "$registry_file"
  fi
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

attach_mode=false
if [[ ${1:-} == attach ]]; then
  attach_mode=true
fi

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

  # サブコマンド起動時は TUI のサーバーが立たないため登録しない (opencode CLI のサブコマンド一覧に依存)
  case ${1:-} in
  attach | run | serve | web | acp | mcp | debug | providers | auth | agent | upgrade | uninstall | models | stats | export | import | github | pr | session | plugin | plug | db | completion) ;;
  *)
    if [[ $actual_port =~ ^[0-9]+$ ]]; then
      # isolated_home の symlink 経由で実ホームの state dir に届く
      registry_dir="$HOME/.local/state/opencode/herdr-servers"
      registry_file="$registry_dir/$(printf %s "$project_dir" | sha1sum | cut -d' ' -f1).json"
      (
        for _ in $(seq 1 100); do
          if curl -sf -m 1 "http://127.0.0.1:${actual_port}/global/health" >/dev/null 2>&1; then
            mkdir -p "$registry_dir"
            jq -n --arg url "http://127.0.0.1:${actual_port}" --arg cwd "$project_dir" --argjson pid $$ \
              '{url: $url, cwd: $cwd, pid: $pid}' >"$registry_file.tmp"
            mv "$registry_file.tmp" "$registry_file"
            break
          fi
          sleep 0.1
        done
      ) &
      poller_pids+=("$!")
    fi
    ;;
  esac
fi

cd "$project_dir"
"$opencode_bin" "$@"
exit_code=$?
exit "$exit_code"
