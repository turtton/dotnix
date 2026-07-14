#!/usr/bin/env bash
# OpenAI quota ポーリング (OpenAI backend-api/wham/usage; best-effort 表示用)
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"
AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

# OpenAI の公開 OAuth client_id (JWT 内で固定)
OPENAI_OAUTH_CLIENT_ID="app_EMoamEEZ73f0CkXaXp7hrann"

# アクセストークンをリフレッシュして新しいトークンを返す
# 失敗した場合は空文字を返す
refresh_access_token() {
  local refresh_token
  refresh_token=$(jq -r '.openai.refresh // empty' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $refresh_token ]]; then
    echo "" >&2
    return
  fi

  local resp
  resp=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=refresh_token&refresh_token=${refresh_token}&client_id=${OPENAI_OAUTH_CLIENT_ID}" \
    "https://auth.openai.com/oauth/token" 2>/dev/null) || {
    echo "" >&2
    return
  }

  local new_token
  new_token=$(echo "$resp" | jq -r '.access_token // empty' 2>/dev/null)
  echo "$new_token"
}

render_quota() {
  local token
  # まず保存されているトークンを試す
  token=$(jq -r '.openai.access // empty' "$AUTH_FILE" 2>/dev/null)

  if [[ -n $token ]]; then
    # 保存トークンで一度試す
    local test_json
    test_json=$(curl -s --connect-timeout 5 --max-time 10 \
      -H "Authorization: Bearer $token" -H "Accept: application/json" \
      "https://chatgpt.com/backend-api/wham/usage" 2>/dev/null)

    if echo "$test_json" | jq -e '.rate_limit.primary_window.used_percent | type == "number"' >/dev/null 2>&1; then
      # 成功 → このトークンで続行
      local json="$test_json"
    else
      # 失敗 → リフレッシュを試みる
      local new_token
      new_token=$(refresh_access_token)
      if [[ -z $new_token ]]; then
        : >"$OUTPUT_FILE"
        return
      fi
      token="$new_token"
    fi
  else
    # 保存トークンがない → リフレッシュを試みる
    token=$(refresh_access_token)
    if [[ -z $token ]]; then
      : >"$OUTPUT_FILE"
      return
    fi
  fi

  # リフレッシュした場合は新しいトークンでAPI呼び出し
  if [[ -z ${json+x} ]]; then
    json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
      -H "Authorization: Bearer $token" -H "Accept: application/json" \
      "https://chatgpt.com/backend-api/wham/usage" 2>/dev/null) || {
      : >"$OUTPUT_FILE"
      return
    }
  fi

  local primary_pct secondary_pct
  primary_pct=$(echo "$json" | jq -r '(.rate_limit.primary_window.used_percent // 0) | floor' 2>/dev/null)
  # secondary_window は 5h limit 廃止後 null になる (API が null を返す)
  secondary_pct=$(echo "$json" | jq -r 'if .rate_limit.secondary_window == null then "" else (.rate_limit.secondary_window.used_percent // 0) | floor end' 2>/dev/null)

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
