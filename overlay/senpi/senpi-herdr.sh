#!/usr/bin/env bash
set -euo pipefail

SENPI_BIN="${SENPI_BIN:-@senpi-dir@/senpi}"
CHILD_WRAPPER="${SENPI_HERDR_CHILD_WRAPPER:-@child-wrapper@}"
HERDR_BIN="${HERDR_BIN:-herdr}"

echo "senpi-herdr is experimental; Shift+Enter and focus-events are known limitations" >&2

if [[ ! -t 0 || ! -t 1 || ! -t 2 ]]; then
  exec "$SENPI_BIN" "$@"
fi

PROJECT_DIR=$(pwd -P)

shell_quote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\"\'\"\'}"
}

pane_is_idle() {
  local process_info
  process_info=$("$HERDR_BIN" --session "$session" pane process-info --pane "$pane_id" 2>/dev/null || true)
  jq -e '.result.process_info as $p | $p.foreground_process_group_id == $p.shell_pid and $p.foreground_processes[0].pid == $p.shell_pid' \
    >/dev/null 2>&1 <<<"$process_info"
}

base=$(basename "$PROJECT_DIR" | LC_ALL=C sed 's/[^[:alnum:]_-]/-/g')
hash=$(printf '%s' "$PROJECT_DIR" | sha256sum | cut -c1-8)
session="senpi-${base}-${hash}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-launchers/$session"
lock_dir="$state_dir/lock"
pane_file="$state_dir/pane-id"
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

status_output=$("$HERDR_BIN" --session "$session" status 2>/dev/null || true)
if ! grep -q 'status: running' <<<"$status_output"; then
  if [[ $(uname -s) == Darwin ]]; then
    nohup "$HERDR_BIN" --session "$session" server </dev/null >"$state_dir/server.log" 2>&1 &
  else
    setsid "$HERDR_BIN" --session "$session" server </dev/null >"$state_dir/server.log" 2>&1 &
  fi
  for _ in $(seq 1 200); do
    if "$HERDR_BIN" --session "$session" workspace list >/dev/null 2>&1; then
      break
    fi
    sleep 0.05
  done
  if ! "$HERDR_BIN" --session "$session" workspace list >/dev/null 2>&1; then
    echo "senpi-herdr: ERROR: herdr server did not become ready for $session" >&2
    exit 1
  fi
  status_output=$("$HERDR_BIN" --session "$session" status 2>/dev/null || true)
fi

socket_path=$(sed -n 's/^[[:space:]]*socket:[[:space:]]*//p' <<<"$status_output" | tail -n 1)
if [[ -z $socket_path ]]; then
  socket_path="$HOME/.config/herdr/sessions/$session/herdr.sock"
fi

pane_id=""
inject=false
if [[ -s $pane_file ]]; then
  pane_id=$(<"$pane_file")
  if ! "$HERDR_BIN" --session "$session" pane get "$pane_id" >/dev/null 2>&1; then
    pane_id=""
    rm -f "$pane_file"
  else
    if pane_is_idle; then
      inject=true
    fi
  fi
fi

if [[ -z $pane_id ]]; then
  created=$("$HERDR_BIN" --session "$session" workspace create --cwd "$PROJECT_DIR" --label "$session" --no-focus)
  pane_id=$(jq -r '.result.root_pane.pane_id // empty' <<<"$created")
  if [[ -z $pane_id ]]; then
    echo "senpi-herdr: ERROR: herdr workspace creation returned no pane id" >&2
    exit 1
  fi
  printf '%s\n' "$pane_id" >"$pane_file"
  inject=true
fi

if $inject; then
  command="env SENPI_HERDR_CHILD=1 HERDR_SESSION=$(shell_quote "$session") HERDR_SOCKET_PATH=$(shell_quote "$socket_path") HERDR_PANE_ID=$(shell_quote "$pane_id") $(shell_quote "$CHILD_WRAPPER") $(shell_quote "$PROJECT_DIR") $(shell_quote "$SENPI_BIN")"
  for arg in "$@"; do
    command+=" $(shell_quote "$arg")"
  done
  "$HERDR_BIN" --session "$session" pane run "$pane_id" "$command"
  for _ in $(seq 1 20); do
    if ! pane_is_idle; then
      break
    fi
    sleep 0.05
  done
fi

rmdir "$lock_dir"
trap - EXIT INT TERM
unset HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID
export HERDR_SESSION="$session" HERDR_SOCKET_PATH="$socket_path"
exec "$HERDR_BIN" --session "$session"
