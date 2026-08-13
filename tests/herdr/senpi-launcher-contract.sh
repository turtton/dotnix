#!/usr/bin/env bash
# Usage: senpi-launcher-contract.sh <launcher-script-or-binary>
# Contract for the herdr-context senpi launcher (senpi-herdr):
#   - outside herdr (no HERDR_ENV) it must never invoke herdr (execs senpi-bare)
#   - inside herdr it opens/reuses a per-directory workspace in the CURRENT
#     session (never starts a server, never attaches a nested TUI)
# Exit 0 iff all assertions pass.
set -u

LAUNCHER=$(readlink -f "$1")
LAUNCHER_ARG=$1
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FAKE_HERDR_SRC="${FAKE_HERDR:-$SELF_DIR/fake-herdr.sh}"

WORK=$(mktemp -d)
cleanup() {
  local f
  for f in "$WORK"/herdr-state/sessions/*/server.pid; do
    [[ -f $f ]] && kill "$(<"$f")" 2>/dev/null
  done
  rm -rf "$WORK"
}
trap cleanup EXIT

export HOME="$WORK/home"
export XDG_STATE_HOME="$WORK/xdg-state"
export FAKE_HERDR_STATE="$WORK/herdr-state"
export FAKE_HERDR_LOG="$WORK/herdr.log"
mkdir -p "$HOME" "$XDG_STATE_HOME" "$FAKE_HERDR_STATE"
: >"$FAKE_HERDR_LOG"

FAKE_BIN="$WORK/bin"
mkdir -p "$FAKE_BIN"
BASH_BIN=$(command -v bash)
cp "$FAKE_HERDR_SRC" "$FAKE_BIN/herdr"
sed -i "1s|^#!.*|#!$BASH_BIN|" "$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr"
export PATH="$FAKE_BIN:$PATH"
export HERDR_BIN="$FAKE_BIN/herdr"

child="$WORK/child-wrapper.sh"
cat >"$child" <<EOF
#!$BASH_BIN
project=\$1
senpi=\$2
shift 2
cd "\$project"
exec "\$senpi" "\$@"
EOF
chmod +x "$child"
export SENPI_HERDR_CHILD_WRAPPER="$child"
export SENPI_BIN=/bin/true

TEST_SESSION="contract-session"

tests=0 fails=0
ok() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}
not_ok() {
  tests=$((tests + 1))
  fails=$((fails + 1))
  printf 'not ok %d - %s\n' "$tests" "$1"
  dump_log
}
dump_log() {
  if [[ -s $FAKE_HERDR_LOG ]]; then
    sed 's/^/  fake-herdr log: /' "$FAKE_HERDR_LOG"
  else
    echo "  fake-herdr log: <empty — no herdr invocations logged>"
  fi
}
reset_log() { : >"$FAKE_HERDR_LOG"; }

run_tty() {
  local dir=$1
  shift
  local runner
  runner=$(mktemp "$WORK/runner.XXXXXX.sh")
  {
    printf '#!%s\ncd %q || exit 1\n' "$BASH_BIN" "$dir"
    if [[ -x $LAUNCHER_ARG && $LAUNCHER_ARG == */bin/* ]]; then
      printf 'exec %q' "$LAUNCHER_ARG"
    else
      printf 'exec bash %q' "$LAUNCHER"
    fi
    printf ' %q' "$@"
    printf '\n'
  } >"$runner"
  chmod +x "$runner"
  timeout 20 script -qec "$runner" /dev/null >/dev/null 2>&1
  return 0
}

run_notty() {
  local dir=$1
  shift
  if [[ -x $LAUNCHER_ARG && $LAUNCHER_ARG == */bin/* ]]; then
    (cd "$dir" && timeout 20 "$LAUNCHER_ARG" "$@" </dev/null >/dev/null 2>&1)
  else
    (cd "$dir" && timeout 20 bash "$LAUNCHER" "$@" </dev/null >/dev/null 2>&1)
  fi
  return 0
}

create_count() { grep -c ' workspace create ' "$FAKE_HERDR_LOG"; }
run_count() { grep -c ' pane run ' "$FAKE_HERDR_LOG"; }
focus_count() { grep -c ' workspace focus ' "$FAKE_HERDR_LOG"; }
server_count() { grep -c ' server$' "$FAKE_HERDR_LOG"; }
attach_count() { grep -xc "session=$TEST_SESSION" "$FAKE_HERDR_LOG"; }

start_fake_server() {
  (exec herdr --session "$TEST_SESSION" server) >/dev/null 2>&1 &
  local i
  for i in $(seq 1 100); do
    herdr --session "$TEST_SESSION" workspace list >/dev/null 2>&1 && break
    sleep 0.05
  done
}

herdr_env() {
  export HERDR_ENV=1
  export HERDR_SESSION="$TEST_SESSION"
  export HERDR_SOCKET_PATH="$HOME/.config/herdr/sessions/$TEST_SESSION/herdr.sock"
}

clear_herdr_env() {
  unset HERDR_ENV HERDR_SESSION HERDR_SOCKET_PATH HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID
}

expected_label() {
  local dir=$1
  printf 'senpi-%s' "$(basename "$dir" | LC_ALL=C sed 's/[^[:alnum:]_-]/-/g')"
}

printf '# launcher under test: %s\n' "$LAUNCHER"

# 1: outside herdr (no HERDR_ENV) → zero herdr invocations, even on a TTY
dir_a="$WORK/proj-alpha"
mkdir -p "$dir_a"
clear_herdr_env
reset_log
run_tty "$dir_a"
if [[ ! -s $FAKE_HERDR_LOG ]]; then
  ok "outside herdr: never invokes herdr"
else
  not_ok "outside herdr: must not invoke herdr"
fi

# 2: inside herdr, first launch → labeled workspace create + one injection,
#    no server start, no nested TUI attach
start_fake_server
herdr_env
reset_log
export SENPI_BIN=sleep
run_tty "$dir_a" 3
want_label=$(expected_label "$dir_a")
if [[ $(create_count) -eq 1 && $(run_count) -eq 1 && $(server_count) -eq 0 && $(attach_count) -eq 0 ]] &&
  grep -q -- "--label $want_label" "$FAKE_HERDR_LOG"; then
  ok "inside herdr: creates workspace $want_label and injects once (no server, no attach)"
else
  not_ok "inside herdr: expected 1 create + 1 pane run, 0 server, 0 attach (create=$(create_count) run=$(run_count) server=$(server_count) attach=$(attach_count))"
fi

# 3: reattach while pane busy → focus existing workspace, no second injection
run_tty "$dir_a" 3
if [[ $(run_count) -eq 1 && $(create_count) -eq 1 && $(focus_count) -ge 1 ]]; then
  ok "busy pane: focuses existing workspace without reinjecting"
else
  not_ok "busy pane: expected run=1 create=1 focus>=1 (run=$(run_count) create=$(create_count) focus=$(focus_count))"
fi

# 4: idle shell after senpi exit → reinjection allowed on next launch
sleep 4
run_tty "$dir_a" 3
if [[ $(run_count) -eq 2 && $(create_count) -eq 1 ]]; then
  ok "idle shell after senpi exit: reinjection allowed"
else
  not_ok "idle reinjection: expected run=2 create=1 (run=$(run_count) create=$(create_count))"
fi

# 5: concurrent launches in the same directory → exactly one injection
dir_c="$WORK/proj-race"
mkdir -p "$dir_c"
reset_log
run_tty "$dir_c" 5 &
p1=$!
run_tty "$dir_c" 5 &
p2=$!
wait "$p1" "$p2"
if [[ $(run_count) -eq 1 && $(create_count) -eq 1 ]]; then
  ok "concurrent launches: exactly one injection"
else
  not_ok "concurrent launches: expected run=1 create=1 (run=$(run_count) create=$(create_count))"
fi

# 6: same basename in different parents → separate workspaces by cwd match;
#    revisiting the first directory reuses its workspace
mkdir -p "$WORK/x/samebase" "$WORK/y/samebase"
reset_log
export SENPI_BIN=/bin/true
run_tty "$WORK/x/samebase"
run_tty "$WORK/y/samebase"
run_tty "$WORK/x/samebase"
if [[ $(create_count) -eq 2 && $(run_count) -eq 3 ]]; then
  ok "same basename: distinct cwd gets own workspace; matching cwd reuses it"
else
  not_ok "same basename: expected create=2 run=3 (create=$(create_count) run=$(run_count))"
fi

# 7: arguments with spaces/quotes/dollar/semicolons survive to the pane intact
recorder="$WORK/argv-recorder.sh"
argv_out="$WORK/argv.out"
cat >"$recorder" <<EOF
#!$BASH_BIN
out=\$1
shift
printf '%s\n' "\$@" >"\$out"
EOF
chmod +x "$recorder"
export SENPI_BIN="$recorder"
reset_log
run_tty "$dir_a" "$argv_out" 'a b' '"quoted"' '$HOME' 'x;rm -rf /' "it's"
for _ in $(seq 1 50); do
  [[ -f $argv_out ]] && break
  sleep 0.1
done
got=()
[[ -f $argv_out ]] && mapfile -t got <"$argv_out"
want_args=('a b' '"quoted"' '$HOME' 'x;rm -rf /' "it's")
match=1
[[ ${#got[@]} -eq ${#want_args[@]} ]] || match=0
for i in "${!want_args[@]}"; do
  [[ ${got[$i]:-} == "${want_args[$i]}" ]] || match=0
done
if [[ $match -eq 1 ]]; then
  ok "special-character arguments survive pane injection"
else
  not_ok "argument survival failed: $(printf '<%s> ' "${got[@]:-}")"
fi

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
