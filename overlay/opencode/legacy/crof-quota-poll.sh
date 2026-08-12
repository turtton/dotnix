#!/usr/bin/env bash
# Crof.ai quota ポーリング (best-effort 表示用)
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"

AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

render_quota() {
  local token=""
  token=$(jq -r '(.crof.key // .CrofAI.key // empty)' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://crof.ai/usage_api/" 2>/dev/null) || {
    : >"$OUTPUT_FILE"
    return
  }

  local credits
  credits=$(echo "$json" | jq -r '(.credits | select(type == "number")) // empty' 2>/dev/null)

  if [[ -z $credits || $credits == "null" ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local fmt_credits
  fmt_credits=$(printf '%.2f' "$credits" 2>/dev/null || echo "$credits")

  echo "#[bg=#181825,fg=#cdd6f4] │ #[bg=#181825,fg=#4e56c8] n ${fmt_credits} #[bg=#181825,fg=#4e56c8]" >"$OUTPUT_FILE"
}

render_quota

while true; do
  sleep 180
  render_quota
done
