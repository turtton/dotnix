#!/usr/bin/env bash
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
cat >"$child" <<'EOF'
#!/usr/bin/env bash
project=$1
senpi=$2
shift 2
cd "$project"
exec "$senpi" "$@"
EOF
chmod +x "$child"
export SENPI_HERDR_CHILD_WRAPPER="$child"
export SENPI_BIN=/bin/true

tests=0 fails=0
ok() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}
not_ok() {
  tests=$((tests + 1))
  fails=$((fails + 1))
  printf 'not ok %d - %s\n' "$tests" "$1"
  sed 's/^/  fake-herdr log: /' "$FAKE_HERDR_LOG"
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
}

sessions_logged() { sed -n 's/^session=\([^ ]*\).*/\1/p' "$FAKE_HERDR_LOG" | sort -u; }
pane_run_count() { grep -c ' pane run ' "$FAKE_HERDR_LOG"; }
expected_session() {
  local dir=$1 base hash
  base=$(basename "$dir" | LC_ALL=C sed 's/[^[:alnum:]_-]/-/g')
  hash=$(cd "$dir" && printf '%s' "$(pwd -P)" | sha256sum | cut -c1-8)
  printf 'senpi-%s-%s' "$base" "$hash"
}

printf '# launcher under test: %s\n' "$LAUNCHER"

dir_a="$WORK/proj alpha"
mkdir -p "$dir_a"
reset_log
run_tty "$dir_a"
run_tty "$dir_a"
mapfile -t sessions < <(sessions_logged)
want=$(expected_session "$dir_a")
if [[ ${#sessions[@]} -eq 1 && ${sessions[0]} == "$want" ]]; then
  ok "same directory reuses sanitized canonical session $want"
else
  not_ok "same directory must reuse session $want"
fi

mkdir -p "$WORK/x/samebase" "$WORK/y/samebase"
reset_log
run_tty "$WORK/x/samebase"
run_tty "$WORK/y/samebase"
mapfile -t sessions < <(sessions_logged)
sx=$(expected_session "$WORK/x/samebase")
sy=$(expected_session "$WORK/y/samebase")
if [[ ${#sessions[@]} -eq 2 && " ${sessions[*]} " == *" $sx "* && " ${sessions[*]} " == *" $sy "* && $sx != "$sy" ]]; then
  ok "same basename in different parents yields distinct sessions"
else
  not_ok "same basename must yield distinct sessions $sx / $sy"
fi

dir_b="$WORK/proj-busy"
mkdir -p "$dir_b"
export SENPI_BIN=sleep
reset_log
run_tty "$dir_b" 3
run_tty "$dir_b" 3
count=$(pane_run_count)
if [[ $count -eq 1 ]]; then
  ok "reattach to busy pane does not reinject"
else
  not_ok "busy reattach expected 1 pane run, got $count"
fi
sleep 4
run_tty "$dir_b" 3
count=$(pane_run_count)
if [[ $count -eq 2 ]]; then
  ok "idle shell after senpi exit allows reinjection"
else
  not_ok "idle reinjection expected 2 pane runs, got $count"
fi

dir_c="$WORK/proj-race"
mkdir -p "$dir_c"
reset_log
run_tty "$dir_c" 5 &
p1=$!
run_tty "$dir_c" 5 &
p2=$!
wait "$p1" "$p2"
count=$(pane_run_count)
if [[ $count -eq 1 ]]; then
  ok "concurrent launches inject exactly once"
else
  not_ok "concurrent launches expected 1 pane run, got $count"
fi

reset_log
export SENPI_BIN=/bin/true
run_notty "$dir_a" --version
if [[ ! -s $FAKE_HERDR_LOG ]]; then
  ok "non-TTY invocation bypasses herdr"
else
  not_ok "non-TTY invocation must not invoke herdr"
fi

recorder="$WORK/argv-recorder.sh"
argv_out="$WORK/argv.out"
cat >"$recorder" <<'EOF'
#!/usr/bin/env bash
out=$1
shift
printf '%s\n' "$@" >"$out"
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
