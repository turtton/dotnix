#!/usr/bin/env bash
# Usage: launcher-contract.sh <launcher-script>
# Contract for the herdr opencode launcher. Runs the launcher under test ($1)
# with fake-herdr on PATH and asserts against FAKE_HERDR_LOG. Exit 0 iff all
# assertions pass. TTY is simulated with util-linux `script`; launcher exit
# codes are ignored on purpose — only herdr-side effects are asserted.
set -u

LAUNCHER=$(readlink -f "$1")
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
export OPENCODE_BIN=/bin/true
mkdir -p "$HOME" "$XDG_STATE_HOME" "$FAKE_HERDR_STATE"
: >"$FAKE_HERDR_LOG"

FAKE_BIN="$WORK/bin"
mkdir -p "$FAKE_BIN"
BASH_BIN=$(command -v bash)
cp "$FAKE_HERDR_SRC" "$FAKE_BIN/herdr"
sed -i "1s|^#!.*|#!$BASH_BIN|" "$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr"
export PATH="$FAKE_BIN:$PATH"

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
    printf '#!%s\ncd %q || exit 1\nexec bash %q' "$BASH_BIN" "$dir" "$LAUNCHER"
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
  (cd "$dir" && timeout 20 bash "$LAUNCHER" "$@" </dev/null >/dev/null 2>&1)
  return 0
}

sessions_logged() { sed -n 's/^session=\([^ ]*\).*/\1/p' "$FAKE_HERDR_LOG" | sort -u; }
pane_run_count() { grep -c ' pane run ' "$FAKE_HERDR_LOG"; }

expected_session() {
  local dir=$1 base hash
  base=$(basename "$dir")
  hash=$(cd "$dir" && printf '%s' "$(pwd -P)" | sha256sum | cut -c1-8)
  printf 'opencode-%s-%s' "$base" "$hash"
}

printf '# launcher under test: %s\n' "$LAUNCHER"

# 1: same directory → same session name, opencode-<base>-<hash8> of canonical pwd
dir_a="$WORK/proj-alpha"
mkdir -p "$dir_a"
reset_log
run_tty "$dir_a" /bin/true
run_tty "$dir_a" /bin/true
mapfile -t sessions < <(sessions_logged)
want=$(expected_session "$dir_a")
if [[ ${#sessions[@]} -eq 1 && ${sessions[0]} == "$want" ]]; then
  ok "same directory reuses session $want"
else
  not_ok "same directory → one session $want (got: ${sessions[*]:-none})"
fi

# 2: different directories with same basename → different session names
mkdir -p "$WORK/x/samebase" "$WORK/y/samebase"
reset_log
run_tty "$WORK/x/samebase" /bin/true
run_tty "$WORK/y/samebase" /bin/true
mapfile -t sessions < <(sessions_logged)
sx=$(expected_session "$WORK/x/samebase")
sy=$(expected_session "$WORK/y/samebase")
if [[ ${#sessions[@]} -eq 2 && " ${sessions[*]} " == *" $sx "* && " ${sessions[*]} " == *" $sy "* && $sx != "$sy" ]]; then
  ok "same basename in different parents yields distinct sessions"
else
  not_ok "same basename → distinct sessions $sx / $sy (got: ${sessions[*]:-none})"
fi

# 3+4: busy pane blocks reinjection; idle shell after agent exit allows it
dir_b="$WORK/proj-busy"
mkdir -p "$dir_b"
reset_log
run_tty "$dir_b" sleep 3
run_tty "$dir_b" sleep 3
count=$(pane_run_count)
if [[ $count -eq 1 ]]; then
  ok "busy pane: exactly one pane run across two launches"
else
  not_ok "busy pane: expected 1 pane run, got $count"
fi
sleep 4
run_tty "$dir_b" sleep 3
count=$(pane_run_count)
if [[ $count -eq 2 ]]; then
  ok "idle shell after agent exit: reinjection allowed"
else
  not_ok "idle shell after agent exit: expected 2 pane runs total, got $count"
fi

# 5: concurrent launches → exactly one injection
dir_c="$WORK/proj-race"
mkdir -p "$dir_c"
reset_log
run_tty "$dir_c" sleep 5 &
p1=$!
run_tty "$dir_c" sleep 5 &
p2=$!
wait "$p1" "$p2"
count=$(pane_run_count)
if [[ $count -eq 1 ]]; then
  ok "concurrent launches: exactly one injection"
else
  not_ok "concurrent launches: expected 1 pane run, got $count"
fi

# 6: non-TTY → herdr never invoked
reset_log
run_notty "$dir_a" /bin/true --version
if [[ ! -s $FAKE_HERDR_LOG ]]; then
  ok "non-TTY invocation never touches herdr"
else
  not_ok "non-TTY invocation must not invoke herdr"
fi

# 7: arguments with spaces/quotes/dollar/semicolons survive to the pane intact
recorder="$WORK/argv-recorder.sh"
argv_out="$WORK/argv.out"
{
  printf '#!%s\n' "$BASH_BIN"
  cat <<'EOF'
out=$1; shift
printf '%s\n' "$@" >"$out"
EOF
} >"$recorder"
chmod +x "$recorder"
reset_log
run_tty "$dir_a" "$recorder" "$argv_out" 'a b' '"quoted"' '$HOME' 'x;rm -rf /' "it's"
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
  ok "special-character arguments survive to the pane command"
else
  if [[ ! -s $FAKE_HERDR_LOG ]]; then
    not_ok "argument survival (no pane run recorded)"
  else
    not_ok "argument survival (pane argv: $(printf '<%s> ' "${got[@]:-}"))"
  fi
fi

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
