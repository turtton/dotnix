#!/usr/bin/env bash
# OpenRouter quota ポーリング (openrouter.ai/api/v1/key; best-effort 表示用)
# ビルド時に quota-report.sh のストアパスが埋め込まれる
QUOTA_REPORT="__QUOTA_REPORT__"
if [[ ! -x $QUOTA_REPORT ]]; then
  QUOTA_REPORT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quota-report.sh"
fi

AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

render_quota() {
  local token=""
  token=$(jq -r '(.openrouter.key // .OpenRouter.key // empty)' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://openrouter.ai/api/v1/key" 2>/dev/null) || return

  # limit_remaining: 制限付きキーの残クレジット。無制限キーでは null になるため
  # その場合は今月の使用量 (usage_monthly) を代わりに表示する
  local remaining monthly
  remaining=$(echo "$json" | jq -r '(.data.limit_remaining | select(type == "number")) // empty' 2>/dev/null)
  monthly=$(echo "$json" | jq -r '(.data.usage_monthly | select(type == "number")) // empty' 2>/dev/null)

  local text
  if [[ -n $remaining ]]; then
    text="\$$(printf '%.2f' "$remaining" 2>/dev/null || echo "$remaining") left"
  elif [[ -n $monthly ]]; then
    text="\$$(printf '%.2f' "$monthly" 2>/dev/null || echo "$monthly")/mo"
  else
    return
  fi

  "$QUOTA_REPORT" openrouter "$text"
}

render_quota

while true; do
  sleep 180
  render_quota
done
