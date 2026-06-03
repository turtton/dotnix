#!/usr/bin/env bash
# OpenAI quota ポーリング (OpenAI backend-api/wham/usage; best-effort 表示用)
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"
AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

render_quota() {
  local token
  token=$(jq -r '.openai.access // empty' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://chatgpt.com/backend-api/wham/usage" 2>/dev/null) || {
    : >"$OUTPUT_FILE"
    return
  }

  local primary_pct secondary_pct
  primary_pct=$(echo "$json" | jq -r '(.rate_limit.primary_window.used_percent // 0) | floor' 2>/dev/null)
  secondary_pct=$(echo "$json" | jq -r '(.rate_limit.secondary_window.used_percent // 0) | floor' 2>/dev/null)

  if [[ -z $primary_pct || $primary_pct == "null" ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local bar=" │ "

  local filled5=$((primary_pct / 10))
  [[ $filled5 -gt 10 ]] && filled5=10
  [[ $filled5 -lt 0 ]] && filled5=0
  local empty5=$((10 - filled5))

  bar+="#[bg=#181825,fg=#89b4fa] 󰚩 "
  if [[ $filled5 -gt 0 ]]; then
    bar+="#[bg=#89b4fa,fg=#11111b]"
    for ((i = 0; i < filled5; i++)); do bar+="█"; done
  fi
  if [[ $empty5 -gt 0 ]]; then
    bar+="#[bg=#313244,fg=#585b70]"
    for ((i = 0; i < empty5; i++)); do bar+="░"; done
  fi
  bar+="#[bg=#181825,fg=#cdd6f4] ${primary_pct}% "

  if [[ -n $secondary_pct && $secondary_pct != "null" ]]; then
    local filledw=$((secondary_pct / 10))
    [[ $filledw -gt 10 ]] && filledw=10
    [[ $filledw -lt 0 ]] && filledw=0
    local emptyw=$((10 - filledw))

    bar+="#[bg=#181825,fg=#cba6f7] 󰃭 "
    if [[ $filledw -gt 0 ]]; then
      bar+="#[bg=#cba6f7,fg=#11111b]"
      for ((i = 0; i < filledw; i++)); do bar+="█"; done
    fi
    if [[ $emptyw -gt 0 ]]; then
      bar+="#[bg=#313244,fg=#585b70]"
      for ((i = 0; i < emptyw; i++)); do bar+="░"; done
    fi
    bar+="#[bg=#181825,fg=#cdd6f4] ${secondary_pct}%"
  fi

  echo "$bar" >"$OUTPUT_FILE"
}

render_quota

while true; do
  sleep 180
  render_quota
done
