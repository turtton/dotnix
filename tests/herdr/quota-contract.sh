#!/usr/bin/env bash
# Usage: quota-contract.sh <poller-script> [provider]
# Contract for herdr quota pollers. Fixture seams (no poller edits required):
#   - `curl` is shimmed on PATH; FAKE_API_RESPONSE_FILE holds the API body,
#     deleting it simulates an unreachable endpoint (shim exits 7 like curl)
#   - credentials come from an isolated $HOME/.local/share/opencode/auth.json
#   - the poller's herdr target arrives via HERDR_SESSION / HERDR_PANE_ID
# Exits 0 iff all assertions pass.
set -u

POLLER=$(readlink -f "$1")
PROVIDER="${2:-kimi}"
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FAKE_HERDR_SRC="${FAKE_HERDR:-$SELF_DIR/fake-herdr.sh}"

WORK=$(mktemp -d)
cleanup() {
  local f
  for f in "$WORK"/herdr-state/sessions/*/server.pid; do
    [[ -f $f ]] && kill "$(<"$f")" 2>/dev/null
  done
  [[ -n ${poller_pid:-} ]] && kill "$poller_pid" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

export HOME="$WORK/home"
export XDG_STATE_HOME="$WORK/xdg-state"
export FAKE_HERDR_STATE="$WORK/herdr-state"
export FAKE_HERDR_LOG="$WORK/herdr.log"
export FAKE_API_RESPONSE_FILE="$WORK/api-response.json"
mkdir -p "$HOME/.local/share/opencode" "$XDG_STATE_HOME" "$FAKE_HERDR_STATE"
: >"$FAKE_HERDR_LOG"

# プロバイダごとの認証情報と API レスポンス fixture
API_FIXTURE=""
case "$PROVIDER" in
kimi)
  printf '{"kimi-for-coding":{"key":"fake-token"}}' >"$HOME/.local/share/opencode/auth.json"
  API_FIXTURE='{"usage":{"limit":100,"remaining":40},"limits":[{"detail":{"limit":100,"used":25},"window":{"duration":300}}]}'
  ;;
openai)
  printf '{"openai":{"access":"fake-token"}}' >"$HOME/.local/share/opencode/auth.json"
  API_FIXTURE='{"rate_limit":{"primary_window":{"used_percent":42},"secondary_window":{"used_percent":17}}}'
  ;;
crof)
  printf '{"crof":{"key":"fake-token"}}' >"$HOME/.local/share/opencode/auth.json"
  API_FIXTURE='{"credits":12.345}'
  ;;
openrouter)
  printf '{"openrouter":{"key":"fake-token"}}' >"$HOME/.local/share/opencode/auth.json"
  API_FIXTURE='{"data":{"limit_remaining":5.5}}'
  ;;
claude)
  mkdir -p "$HOME/.claude"
  printf '{"claudeAiOauth":{"accessToken":"fake-token"}}' >"$HOME/.claude/.credentials.json"
  API_FIXTURE='{"five_hour":{"utilization":33},"seven_day":{"utilization":12}}'
  ;;
copilot)
  API_FIXTURE='{"quota_snapshots":{"premium_interactions":{"entitlement":300,"remaining":117}}}'
  ;;
*)
  echo "unknown provider: $PROVIDER" >&2
  exit 2
  ;;
esac

FAKE_BIN="$WORK/bin"
mkdir -p "$FAKE_BIN"
BASH_BIN=$(command -v bash)
cp "$FAKE_HERDR_SRC" "$FAKE_BIN/herdr"
printf '#!%s\n' "$BASH_BIN" >"$FAKE_BIN/curl"
cat >>"$FAKE_BIN/curl" <<'EOF'
echo "curl $*" >>"$FAKE_CURL_LOG"
[[ -f $FAKE_API_RESPONSE_FILE ]] || exit 7
cat "$FAKE_API_RESPONSE_FILE"
EOF
sed -i "1s|^#!.*|#!$BASH_BIN|" "$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr" "$FAKE_BIN/curl"
if [[ $PROVIDER == copilot ]]; then
  printf '#!%s\n' "$BASH_BIN" >"$FAKE_BIN/gh"
  cat >>"$FAKE_BIN/gh" <<'EOF'
echo "gh $*" >>"$FAKE_CURL_LOG"
[[ -f $FAKE_API_RESPONSE_FILE ]] || exit 1
cat "$FAKE_API_RESPONSE_FILE"
EOF
  chmod +x "$FAKE_BIN/gh"
fi
export FAKE_CURL_LOG="$WORK/curl.log"
: >"$FAKE_CURL_LOG"
export PATH="$FAKE_BIN:$PATH"

export HERDR_SESSION="quota-contract-session"
herdr --session "$HERDR_SESSION" server >/dev/null 2>&1 &
for _ in $(seq 1 100); do
  herdr --session "$HERDR_SESSION" workspace list >/dev/null 2>&1 && break
  sleep 0.05
done
created=$(herdr --session "$HERDR_SESSION" workspace create --cwd "$WORK" --label quota --no-focus)
export HERDR_PANE_ID
HERDR_PANE_ID=$(jq -r '.result.root_pane.pane_id' <<<"$created")
METADATA_LOG="$FAKE_HERDR_STATE/sessions/$HERDR_SESSION/metadata.log"

printf '%s\n' "$API_FIXTURE" >"$FAKE_API_RESPONSE_FILE"

tests=0 fails=0
ok() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}
not_ok() {
  tests=$((tests + 1))
  fails=$((fails + 1))
  printf 'not ok %d - %s\n' "$tests" "$1"
  if [[ -s $FAKE_HERDR_LOG ]]; then
    grep -v ' server$\| workspace \| pane get \| pane process-info ' "$FAKE_HERDR_LOG" | sed 's/^/  fake-herdr log: /' || true
  else
    echo "  fake-herdr log: <empty — no herdr invocations logged>"
  fi
}

poller_pid=""
run_one_poll_cycle() {
  : >"$FAKE_CURL_LOG"
  (cd "$WORK" && bash "$POLLER") >/dev/null 2>&1 &
  poller_pid=$!
  local i
  for i in $(seq 1 50); do
    [[ -s $FAKE_CURL_LOG ]] && break
    sleep 0.1
  done
  sleep 0.5
  kill "$poller_pid" 2>/dev/null
  wait "$poller_pid" 2>/dev/null
  poller_pid=""
}

printf '# poller under test: %s (provider: %s)\n' "$POLLER" "$PROVIDER"

run_one_poll_cycle

# 1: poller reports via pane report-metadata with explicit session and pane
report_lines=$(grep -c ' pane report-metadata ' "$FAKE_HERDR_LOG")
if [[ $report_lines -ge 1 ]]; then
  ok "poller invokes pane report-metadata"
else
  not_ok "poller must invoke pane report-metadata (got $report_lines invocations)"
fi
if grep -q "^session=$HERDR_SESSION pane report-metadata $HERDR_PANE_ID " "$FAKE_HERDR_LOG"; then
  ok "report-metadata carries explicit --session and explicit pane id"
else
  not_ok "report-metadata must use --session $HERDR_SESSION and pane $HERDR_PANE_ID"
fi
if grep -q -- "--source quota:$PROVIDER" "$FAKE_HERDR_LOG"; then
  ok "source is quota:$PROVIDER"
else
  not_ok "source must be quota:$PROVIDER"
fi
if grep -q -- "--ttl-ms 200000" "$FAKE_HERDR_LOG"; then
  ok "ttl-ms is 200000"
else
  not_ok "ttl-ms must be 200000"
fi

# 2: token value is plain text — no control chars, no tmux #[...], ≤80 chars
if [[ -s $METADATA_LOG ]]; then
  bad=0
  while IFS=$'\t' read -r m_pane m_source m_token m_ttl; do
    [[ $m_source == "quota:$PROVIDER" ]] || continue
    [[ $m_token == "$PROVIDER="* ]] || bad=1
    value="${m_token#"$PROVIDER"=}"
    [[ ${#m_token} -le 80 ]] || bad=1
    [[ $value != *'#['* ]] || bad=1
    if LC_ALL=C grep -q '[^[:print:]]' <<<"$value"; then bad=1; fi
  done <"$METADATA_LOG"
  if [[ $bad -eq 0 ]]; then
    ok "token values are plain text ≤80 chars without tmux format codes"
  else
    not_ok "token values violate plain-text/length contract"
    sed 's/^/  metadata: /' "$METADATA_LOG"
  fi
else
  not_ok "token values (no metadata recorded)"
fi

# 3: API failure must not emit report-metadata with error bodies
: >"$FAKE_HERDR_LOG"
rm -f "$METADATA_LOG"
rm -f "$FAKE_API_RESPONSE_FILE"
run_one_poll_cycle
if grep -q ' pane report-metadata ' "$FAKE_HERDR_LOG" || [[ -s $METADATA_LOG ]]; then
  not_ok "API failure must not produce report-metadata"
  [[ -s $METADATA_LOG ]] && sed 's/^/  metadata: /' "$METADATA_LOG"
else
  ok "unreachable API produces no report-metadata"
fi

printf '# %d/%d assertions failed\n' "$fails" "$tests"
[[ $fails -eq 0 ]]
