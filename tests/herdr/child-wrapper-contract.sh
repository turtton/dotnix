#!/usr/bin/env bash
# Usage: child-wrapper-contract.sh <child-wrapper-script>
# Contract for the child wrapper:
#   - TUI mode appends --port <OPENCODE_PORT>
#   - attach mode never appends --port
# (The per-cwd shared-server registry was removed; every launch now gets its
# own server, so nothing keys behavior off registry files anymore.)
# Exit 0 iff all assertions pass.
set -u

CHILD=$(readlink -f "$1")
WORK=$(mktemp -d)
TEST_PORT=44568
child_pid=""
cleanup() {
  [[ -n $child_pid ]] && kill -TERM -- -"$child_pid" 2>/dev/null
  pkill -f "$WORK/fake-opencode" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

export HOME="$WORK/home"
mkdir -p "$HOME"

projdir="$WORK/proj"
mkdir -p "$projdir"

FAKE_OC="$WORK/fake-opencode"
export FAKE_OC_LOG="$WORK/fake-oc.args"
# nix ビルドのサンドボックスには /usr/bin/env が無いため bash の実パスを使う
printf '#!%s\n' "$(command -v bash)" >"$FAKE_OC"
cat >>"$FAKE_OC" <<'EOF'
printf '%s\n' "$@" >"$FAKE_OC_LOG"
sleep infinity
EOF
chmod +x "$FAKE_OC"

tests=0 fails=0
ok() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}
not_ok() {
  tests=$((tests + 1))
  fails=$((fails + 1))
  printf 'not ok %d - %s\n' "$tests" "$1"
  [[ -s $WORK/child.err ]] && sed 's/^/  child stderr: /' "$WORK/child.err"
}

wait_for_argv() {
  for _ in $(seq 1 100); do
    [[ -s $FAKE_OC_LOG ]] && return 0
    sleep 0.1
  done
  return 1
}

printf '# child wrapper under test: %s\n' "$CHILD"

# 1: the wrapper appends --port <OPENCODE_PORT> for the embedded server
# setsid でプロセスグループを分け、pane 終了時の道連れ終了をグループ kill で再現する
setsid env HERDR_SESSION=t HERDR_PANE_ID=1 OPENCODE_PORT=$TEST_PORT \
  bash "$CHILD" "$projdir" "$FAKE_OC" >/dev/null 2>"$WORK/child.err" &
child_pid=$!

wait_for_argv
if grep -qx -- "--port" "$FAKE_OC_LOG" && grep -qx "$TEST_PORT" "$FAKE_OC_LOG"; then
  ok "tui mode: appends --port for the embedded server"
else
  not_ok "tui mode: expected --port $TEST_PORT in fake argv ($(paste -sd' ' "$FAKE_OC_LOG" 2>/dev/null))"
fi
kill -TERM -- -"$child_pid" 2>/dev/null
child_pid=""

# 2: attach mode never appends --port
rm -f "$FAKE_OC_LOG"
setsid env HERDR_SESSION=t HERDR_PANE_ID=1 OPENCODE_PORT=$TEST_PORT \
  bash "$CHILD" "$projdir" "$FAKE_OC" attach "http://127.0.0.1:$TEST_PORT" >/dev/null 2>&1 &
child_pid=$!
wait_for_argv
if [[ $(head -n1 "$FAKE_OC_LOG" 2>/dev/null) == attach ]] && ! grep -qx -- "--port" "$FAKE_OC_LOG"; then
  ok "attach mode: no --port appended"
else
  not_ok "attach mode: expected no --port (argv: $(paste -sd' ' "$FAKE_OC_LOG" 2>/dev/null))"
fi
kill -TERM -- -"$child_pid" 2>/dev/null
child_pid=""

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
