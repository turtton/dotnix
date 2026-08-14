#!/usr/bin/env bash
# Usage: child-wrapper-contract.sh <child-wrapper-script>
# Contract for the child wrapper's shared-server registry:
#   - TUI mode registers the embedded server URL under
#     ~/.local/state/opencode/herdr-servers/<sha1(cwd)>.json once healthy
#   - the entry is removed when the wrapper exits
#   - attach mode never registers and never appends --port
# Exit 0 iff all assertions pass.
set -u

CHILD=$(readlink -f "$1")
WORK=$(mktemp -d)
TEST_PORT=44568
child_pid=""
cleanup() {
  [[ -n $child_pid ]] && kill -TERM -- -"$child_pid" 2>/dev/null
  pkill -f "http.server $TEST_PORT" 2>/dev/null
  pkill -f "$WORK/fake-opencode" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

export HOME="$WORK/home"
mkdir -p "$HOME"

projdir="$WORK/proj"
mkdir -p "$projdir"
canon=$(cd "$projdir" && pwd -P)
key=$(printf %s "$canon" | sha1sum | cut -d' ' -f1)
registry="$HOME/.local/state/opencode/herdr-servers/$key.json"

FAKE_OC="$WORK/fake-opencode"
export FAKE_OC_LOG="$WORK/fake-oc.args"
# nix ビルドのサンドボックスには /usr/bin/env が無いため bash の実パスを使う
printf '#!%s\n' "$(command -v bash)" >"$FAKE_OC"
cat >>"$FAKE_OC" <<'EOF'
printf '%s\n' "$@" >"$FAKE_OC_LOG"
port=""
prev=""
for a in "$@"; do
  if [[ $prev == --port ]]; then port=$a; fi
  prev=$a
done
if [[ -n $port ]]; then
  docroot=$(mktemp -d)
  mkdir -p "$docroot/global"
  printf '{"healthy":true}' >"$docroot/global/health"
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$docroot" >/dev/null 2>&1 &
fi
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

printf '# child wrapper under test: %s\n' "$CHILD"

# 1: TUI mode registers the server once /global/health answers
# setsid でプロセスグループを分け、pane 終了時の道連れ終了をグループ kill で再現する
setsid env HERDR_SESSION=t HERDR_PANE_ID=1 OPENCODE_PORT=$TEST_PORT \
  bash "$CHILD" "$projdir" "$FAKE_OC" >/dev/null 2>"$WORK/child.err" &
child_pid=$!

found=false
for _ in $(seq 1 150); do
  [[ -f $registry ]] && {
    found=true
    break
  }
  sleep 0.1
done
if $found && jq -e --arg url "http://127.0.0.1:$TEST_PORT" --arg cwd "$canon" \
  '.url == $url and .cwd == $cwd' "$registry" >/dev/null 2>&1; then
  ok "tui mode: registers server url keyed by cwd"
else
  not_ok "tui mode: registry missing or wrong content (registry=$registry found=$found)"
fi

# 2: the wrapper appends --port <OPENCODE_PORT> for the embedded server
if grep -qx -- "--port" "$FAKE_OC_LOG" && grep -qx "$TEST_PORT" "$FAKE_OC_LOG"; then
  ok "tui mode: appends --port for the embedded server"
else
  not_ok "tui mode: expected --port $TEST_PORT in fake argv ($(paste -sd' ' "$FAKE_OC_LOG"))"
fi

# 3: exiting the wrapper removes the registry entry
kill -TERM -- -"$child_pid" 2>/dev/null
removed=false
for _ in $(seq 1 100); do
  [[ ! -f $registry ]] && {
    removed=true
    break
  }
  sleep 0.1
done
child_pid=""
if $removed; then
  ok "wrapper exit: registry entry removed"
else
  not_ok "wrapper exit: registry entry still present"
fi

# 4: attach mode neither registers nor appends --port
setsid env HERDR_SESSION=t HERDR_PANE_ID=1 OPENCODE_PORT=$TEST_PORT \
  bash "$CHILD" "$projdir" "$FAKE_OC" attach "http://127.0.0.1:$TEST_PORT" >/dev/null 2>&1 &
child_pid=$!
sleep 3
if [[ ! -f $registry ]] && ! grep -qx -- "--port" "$FAKE_OC_LOG"; then
  ok "attach mode: no registry, no --port"
else
  not_ok "attach mode: registry=$(test -f "$registry" && echo present || echo absent) argv=$(paste -sd' ' "$FAKE_OC_LOG")"
fi
kill -TERM -- -"$child_pid" 2>/dev/null
child_pid=""

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
