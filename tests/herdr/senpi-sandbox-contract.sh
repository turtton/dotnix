#!/usr/bin/env bash
# Usage: senpi-sandbox-contract.sh <sandbox-script>
# Contract for overlay/senpi/sandbox.sh (Linux bwrap launcher for senpi):
#   - SENPI_NO_SANDBOX=1 execs SENPI_BIN directly; bwrap is never invoked
#   - default run: exactly one bwrap call with the sandbox mounts and the tail
#     `bash @child-wrapper@ <project_dir> <senpi_bin> <args...>`
#   - a repo under $HOME gets its parent share-tree ro-bound before the repo bind
#   - HERDR_SESSION/HERDR_SOCKET_PATH/HERDR_PANE_ID are forwarded (--setenv)
#     and the herdr socket directory is bound
#   - arguments with spaces/quotes/$/semicolons reach the bwrap tail verbatim
# A fake bwrap (first in PATH) records argv one-arg-per-line; SENPI_BIN is a
# stub that records direct execution. Exit 0 iff all assertions pass.
set -u

LAUNCHER=$(readlink -f "$1")

WORK=$(mktemp -d)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

export HOME="$WORK/home"
mkdir -p "$HOME/.senpi"

BASH_BIN=$(command -v bash)
FAKE_BIN="$WORK/bin"
mkdir -p "$FAKE_BIN"

# fake bwrap: 呼び出しごとに連番ファイルへ 1 引数 1 行で記録して終了する
BWRAP_RECORD_DIR="$WORK/bwrap-record"
mkdir -p "$BWRAP_RECORD_DIR"
cat >"$FAKE_BIN/bwrap" <<EOF
#!$BASH_BIN
n=0
while [[ -e "$BWRAP_RECORD_DIR/\$n" ]]; do n=\$((n + 1)); done
printf '%s\n' "\$@" >"$BWRAP_RECORD_DIR/\$n"
EOF
chmod +x "$FAKE_BIN/bwrap"
export PATH="$FAKE_BIN:$PATH"

# SENPI_BIN スタブ: サンドボックスを介さない直接 exec を記録する
SENPI_CALLED="$WORK/senpi-called"
SENPI_STUB="$WORK/senpi-stub"
cat >"$SENPI_STUB" <<EOF
#!$BASH_BIN
printf '%s\n' "\$@" >"$SENPI_CALLED"
EOF
chmod +x "$SENPI_STUB"
export SENPI_BIN="$SENPI_STUB"

tests=0 fails=0
ok() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}
not_ok() {
  tests=$((tests + 1))
  fails=$((fails + 1))
  printf 'not ok %d - %s\n' "$tests" "$1"
  dump_bwrap
}
dump_bwrap() {
  local f line name
  for f in "$BWRAP_RECORD_DIR"/*; do
    [[ -e $f ]] || continue
    name=${f##*/}
    while IFS= read -r line; do
      printf '  bwrap[%s]: %s\n' "$name" "$line"
    done <"$f"
  done
}
reset_bwrap() { rm -f "$BWRAP_RECORD_DIR"/*; }

bwrap_count() {
  local n=0 f
  for f in "$BWRAP_RECORD_DIR"/*; do
    [[ -e $f ]] && n=$((n + 1))
  done
  printf '%d' "$n"
}

clear_sandbox_env() {
  unset SENPI_NO_SANDBOX HERDR_ENV HERDR_SESSION HERDR_SOCKET_PATH HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID
}

run_sandbox() {
  local dir=$1
  shift
  (cd "$dir" && timeout 20 bash "$LAUNCHER" "$@" </dev/null >/dev/null 2>&1)
  return 0
}

# 記録ファイル内で連続した引数列が最初に現れる行番号 (0 起点) を出力する
seq_index() {
  local file=$1
  shift
  local -a want=("$@") got
  [[ -f $file ]] || return 1
  mapfile -t got <"$file"
  local i j
  for ((i = 0; i + ${#want[@]} <= ${#got[@]}; i++)); do
    for ((j = 0; j < ${#want[@]}; j++)); do
      [[ ${got[$((i + j))]} == "${want[$j]}" ]] || break
    done
    if [[ $j -eq ${#want[@]} ]]; then
      printf '%d' "$i"
      return 0
    fi
  done
  return 1
}

has_seq() { seq_index "$@" >/dev/null; }

# `--bind <src> <dest>` の dest に一致するエントリの有無
has_bind_to() {
  local file=$1 dest=$2 i
  local -a got
  [[ -f $file ]] || return 1
  mapfile -t got <"$file"
  for ((i = 0; i + 2 < ${#got[@]}; i++)); do
    if [[ ${got[$i]} == --bind && ${got[$((i + 2))]} == "$dest" ]]; then
      return 0
    fi
  done
  return 1
}

printf '# sandbox launcher under test: %s\n' "$LAUNCHER"

# 1: SENPI_NO_SANDBOX=1 → SENPI_BIN を直接 exec し、bwrap は呼ばない
dir_a="$WORK/proj-alpha"
mkdir -p "$dir_a"
clear_sandbox_env
reset_bwrap
rm -f "$SENPI_CALLED"
export SENPI_NO_SANDBOX=1
run_sandbox "$dir_a" alpha 'a b'
unset SENPI_NO_SANDBOX
if [[ -f $SENPI_CALLED && $(bwrap_count) -eq 0 ]] && grep -qFx 'a b' "$SENPI_CALLED"; then
  ok "SENPI_NO_SANDBOX=1: SENPI_BIN exec'd directly (args passed), bwrap not invoked"
else
  not_ok "SENPI_NO_SANDBOX=1: expected direct SENPI_BIN exec and zero bwrap calls (bwrap=$(bwrap_count))"
fi

# 2: デフォルト実行 → マウント群と child-wrapper テイルを持つ bwrap が 1 回だけ
clear_sandbox_env
reset_bwrap
run_sandbox "$dir_a"
log="$BWRAP_RECORD_DIR/0"
missing=""
[[ $(bwrap_count) -eq 1 ]] || missing+="exactly-one-bwrap-call(got=$(bwrap_count)) "
if [[ -f $log ]]; then
  has_seq "$log" --unshare-all || missing+="--unshare-all "
  has_seq "$log" --share-net || missing+="--share-net "
  has_seq "$log" --ro-bind /nix /nix || missing+="--ro-bind-/nix "
  has_seq "$log" --bind "$dir_a" "$dir_a" || missing+="repo-bind "
  has_seq "$log" --setenv SENPI_NO_SANDBOX 1 || missing+="setenv-SENPI_NO_SANDBOX "
  has_seq "$log" --bind "$HOME/.senpi" "$HOME/.senpi" || missing+="senpi-dir-bind "
  if ! has_seq "$log" --tmpfs /tmp && ! has_bind_to "$log" "$HOME"; then
    missing+="tmpfs-/tmp-or-temp-home "
  fi
  has_seq "$log" bash @child-wrapper@ "$dir_a" "$SENPI_BIN" || missing+="child-wrapper-tail "
fi
if [[ -z $missing ]]; then
  ok "default run: one bwrap call with sandbox mounts and child-wrapper tail"
else
  not_ok "default run: missing ${missing}"
fi

# 3: $HOME 配下のリポジトリ → 親 share-tree の ro-bind がリポジトリ bind より先
home_repo="$HOME/work/repo"
mkdir -p "$home_repo"
clear_sandbox_env
reset_bwrap
run_sandbox "$home_repo"
log="$BWRAP_RECORD_DIR/0"
share_tree="$(realpath "$HOME")/work"
share_idx=$(seq_index "$log" --ro-bind "$share_tree" "$share_tree" || true)
repo_idx=$(seq_index "$log" --bind "$home_repo" "$home_repo" || true)
if [[ -n $share_idx && -n $repo_idx && $share_idx -lt $repo_idx ]]; then
  ok 'repo under $HOME: share-tree ro-bind precedes the repo rw bind'
else
  not_ok "repo under \$HOME: expected --ro-bind $share_tree before --bind $home_repo (share=${share_idx:-none} repo=${repo_idx:-none})"
fi

# 4: HERDR_* 環境 → ソケットディレクトリの bind と --setenv 転送
clear_sandbox_env
reset_bwrap
sock_dir="$HOME/.config/herdr/sessions/contract-session"
mkdir -p "$sock_dir"
export HERDR_SESSION=contract-session
export HERDR_SOCKET_PATH="$sock_dir/herdr.sock"
export HERDR_PANE_ID=w1:p1
run_sandbox "$dir_a"
log="$BWRAP_RECORD_DIR/0"
missing=""
has_seq "$log" --bind "$sock_dir" "$sock_dir" || missing+="herdr-socket-dir-bind "
has_seq "$log" --setenv HERDR_SESSION contract-session || missing+="setenv-HERDR_SESSION "
has_seq "$log" --setenv HERDR_SOCKET_PATH "$HERDR_SOCKET_PATH" || missing+="setenv-HERDR_SOCKET_PATH "
has_seq "$log" --setenv HERDR_PANE_ID w1:p1 || missing+="setenv-HERDR_PANE_ID "
clear_sandbox_env
if [[ -z $missing ]]; then
  ok "herdr env: socket directory bound and HERDR_* forwarded"
else
  not_ok "herdr env: missing ${missing}"
fi

# 5: 空白/引用符/$/セミコロンを含む引数が bwrap テイルへ verbatim で届く
clear_sandbox_env
reset_bwrap
run_sandbox "$dir_a" 'a b' '"quoted"' '$HOME' 'x;rm -rf /' "it's"
log="$BWRAP_RECORD_DIR/0"
want_args=('a b' '"quoted"' '$HOME' 'x;rm -rf /' "it's")
got=()
[[ -f $log ]] && mapfile -t got <"$log"
start=$(seq_index "$log" bash @child-wrapper@ "$dir_a" "$SENPI_BIN" || true)
match=1
if [[ -z $start ]]; then
  match=0
else
  for i in "${!want_args[@]}"; do
    [[ ${got[$((start + 4 + i))]:-} == "${want_args[$i]}" ]] || match=0
  done
fi
if [[ $match -eq 1 ]]; then
  ok "special-character arguments survive verbatim into the bwrap tail"
else
  not_ok "argument survival failed (recorded argv: $(printf '<%s> ' "${got[@]:-}"))"
fi

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
