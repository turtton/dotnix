#!/usr/bin/env bash
set -euo pipefail

SENPI_BIN="${SENPI_BIN:-@senpi-dir@/senpi}"
CHILD_WRAPPER="${SENPI_HERDR_CHILD_WRAPPER:-@child-wrapper@}"
HERDR_BIN="${HERDR_BIN:-herdr}"

if [[ -z ${HERDR_ENV:-} ]]; then
  exec "$SENPI_BIN" "$@"
fi

echo "senpi-herdr is experimental; Shift+Enter and focus-events are known limitations" >&2

session=${HERDR_SESSION:?HERDR_SESSION must be set inside herdr}
socket_path=${HERDR_SOCKET_PATH:?HERDR_SOCKET_PATH must be set inside herdr}
CANON=$(pwd -P)
label="senpi-$(basename "$CANON" | LC_ALL=C sed 's/[^[:alnum:]_-]/-/g')"

hcli() {
  env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
    "$HERDR_BIN" --session "$session" "$@"
}

shell_quote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\"\'\"\'}"
}

pane_is_idle() {
  local pane_id=$1 process_info
  if ! process_info=$(hcli pane process-info --pane "$pane_id" 2>/dev/null); then
    return 1
  fi
  jq -e '.result.process_info as $p | $p.foreground_process_group_id == $p.shell_pid and $p.foreground_processes[0].pid == $p.shell_pid' \
    >/dev/null 2>&1 <<<"$process_info"
}

if ! workspace_json=$(hcli workspace list 2>/dev/null); then
  echo "senpi-herdr: warning: current herdr session is unavailable; running senpi directly" >&2
  exec "$SENPI_BIN" "$@"
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-launchers/${session}-${label}"
lock_dir="$state_dir/lock"
mkdir -p "$state_dir"

lock_acquired=false
for _ in $(seq 1 200); do
  if mkdir "$lock_dir" 2>/dev/null; then
    lock_acquired=true
    break
  fi
  sleep 0.05
done
if ! $lock_acquired; then
  echo "senpi-herdr: ERROR: timed out waiting for launcher lock: $lock_dir" >&2
  exit 1
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM

if ! workspace_json=$(hcli workspace list); then
  echo "senpi-herdr: warning: current herdr session became unavailable; running senpi directly" >&2
  rmdir "$lock_dir"
  trap - EXIT INT TERM
  exec "$SENPI_BIN" "$@"
fi
if ! pane_json=$(hcli pane list); then
  echo "senpi-herdr: ERROR: failed to list panes in current herdr session" >&2
  exit 1
fi

# 2インスタンス目以降は "<label>-N" を名乗るため、同一cwdの既存インスタンスを全数拾う
matches=$(jq -nr \
  --arg label "$label" \
  --arg cwd "$CANON" \
  --argjson workspaces "$workspace_json" \
  --argjson panes "$pane_json" '
    $workspaces.result.workspaces[]
    | select(.label == $label or (.label | test("^" + $label + "-[0-9]+$")))
    | .workspace_id as $wid
    | (first($panes.result.panes[] | select(.workspace_id == $wid and .cwd == $cwd)) // empty)
    | [$wid, .pane_id]
    | @tsv
  ')

match_count=0
if [[ -n $matches ]]; then
  match_count=$(wc -l <<<"$matches")
fi

pane_id=""
while IFS=$'\t' read -r candidate_wid candidate_pid; do
  [[ -n ${candidate_pid:-} ]] || continue
  if pane_is_idle "$candidate_pid"; then
    workspace_id=$candidate_wid
    pane_id=$candidate_pid
    break
  fi
done <<<"$matches"

if [[ -n $pane_id ]]; then
  hcli workspace focus "$workspace_id" >/dev/null
else
  new_label=$label
  if ((match_count > 0)); then
    new_label="${label}-$((match_count + 1))"
  fi
  created=$(hcli workspace create --cwd "$CANON" --label "$new_label" --focus)
  pane_id=$(jq -r '.result.root_pane.pane_id // empty' <<<"$created")
  if [[ -z $pane_id ]]; then
    echo "senpi-herdr: ERROR: herdr workspace creation returned no pane id" >&2
    exit 1
  fi
fi

# herdr の既知エージェント表に senpi は無く、ヒントが無いと claude-sdk-oauth の auth probe を Claude Code と誤認する
command="env SENPI_HERDR_CHILD=1 HERDR_AGENT=pi HERDR_SESSION=$(shell_quote "$session") HERDR_SOCKET_PATH=$(shell_quote "$socket_path") HERDR_PANE_ID=$(shell_quote "$pane_id") $(shell_quote "$CHILD_WRAPPER") $(shell_quote "$CANON") $(shell_quote "$SENPI_BIN")"
for arg in "$@"; do
  command+=" $(shell_quote "$arg")"
done
hcli pane run "$pane_id" "$command"
for _ in $(seq 1 20); do
  if ! pane_is_idle "$pane_id"; then
    break
  fi
  sleep 0.05
done

rmdir "$lock_dir"
trap - EXIT INT TERM
