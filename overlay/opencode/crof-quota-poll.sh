#!/usr/bin/env bash
# Crof.ai quota ポーリング (best-effort 表示用)
# ビルド時に quota-report.sh のストアパスが埋め込まれる
QUOTA_REPORT="__QUOTA_REPORT__"
if [[ ! -x $QUOTA_REPORT ]]; then
  QUOTA_REPORT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quota-report.sh"
fi

AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

render_quota() {
  local token=""
  token=$(jq -r '(.crof.key // .CrofAI.key // empty)' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://crof.ai/usage_api/" 2>/dev/null) || return

  local credits
  credits=$(echo "$json" | jq -r '(.credits | select(type == "number")) // empty' 2>/dev/null)

  if [[ -z $credits || $credits == "null" ]]; then
    return
  fi

  local fmt_credits
  fmt_credits=$(printf '%.2f' "$credits" 2>/dev/null || echo "$credits")

  "$QUOTA_REPORT" crof "n ${fmt_credits}"
}

render_quota

while true; do
  sleep 180
  render_quota
done
