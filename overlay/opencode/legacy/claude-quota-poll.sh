#!/usr/bin/env bash
# Claude quota ポーリング (api.anthropic.com/api/oauth/usage; best-effort 表示用)
# Claude Code の OAuth 認証情報 (~/.claude/.credentials.json) を利用する。
# macOS 版 Claude Code は Keychain 保存のためこのスクリプトは Linux 専用。
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"
CREDENTIALS_FILE="${HOME}/.claude/.credentials.json"

# Claude Code の公開 OAuth client_id
CLAUDE_OAUTH_CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
USAGE_URL="https://api.anthropic.com/api/oauth/usage"
# 2026-06 に console.anthropic.com から platform.claude.com へ移行。
# 互換のため旧 URL もフォールバックとして試す
TOKEN_URLS=("https://platform.claude.com/v1/oauth/token" "https://console.anthropic.com/v1/oauth/token")

# usage API 呼び出し ($1: アクセストークン)。レスポンス body を stdout に返す
fetch_usage() {
  curl -s --connect-timeout 5 --max-time 10 \
    -H "Authorization: Bearer $1" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "User-Agent: claude-code/2.1.80" \
    -H "Accept: application/json" \
    "$USAGE_URL" 2>/dev/null
}

# usage レスポンスが有効か判定
is_valid_usage() {
  echo "$1" | jq -e '.five_hour.utilization | type == "number"' >/dev/null 2>&1
}

# リフレッシュトークンで新しいアクセストークンを取得する
# 成功時: 新しいトークンを credentials に書き戻した上でアクセストークンを返す
# 失敗時: 空文字を返す
refresh_access_token() {
  local refresh_token
  refresh_token=$(jq -r '.claudeAiOauth.refreshToken // empty' "$CREDENTIALS_FILE" 2>/dev/null)
  if [[ -z $refresh_token ]]; then
    echo ""
    return
  fi

  local body
  body=$(jq -nc --arg rt "$refresh_token" --arg cid "$CLAUDE_OAUTH_CLIENT_ID" \
    '{grant_type: "refresh_token", refresh_token: $rt, client_id: $cid}')

  local resp="" url
  for url in "${TOKEN_URLS[@]}"; do
    resp=$(curl -s --connect-timeout 5 --max-time 10 \
      -H "Content-Type: application/json" \
      -d "$body" "$url" 2>/dev/null)
    if echo "$resp" | jq -e '.access_token | type == "string"' >/dev/null 2>&1; then
      break
    fi
    resp=""
  done
  if [[ -z $resp ]]; then
    echo ""
    return
  fi

  local new_access new_refresh expires_in
  new_access=$(echo "$resp" | jq -r '.access_token')
  new_refresh=$(echo "$resp" | jq -r '.refresh_token // empty')
  expires_in=$(echo "$resp" | jq -r '.expires_in // 28800')

  # リフレッシュトークンは使い捨てのため、新しいものを保存し直す必要がある。
  # ただし Claude Code 本体が先に認証情報を更新していた場合は上書きしない
  # (ファイル内の refreshToken が消費したものと一致する場合のみ書き戻す)
  if [[ -n $new_refresh && -w $CREDENTIALS_FILE ]]; then
    local current_rt
    current_rt=$(jq -r '.claudeAiOauth.refreshToken // empty' "$CREDENTIALS_FILE" 2>/dev/null)
    if [[ $current_rt == "$refresh_token" ]]; then
      local expires_at tmp
      expires_at=$(($(date +%s) * 1000 + expires_in * 1000))
      tmp="${CREDENTIALS_FILE}.tmp.$$"
      if jq --arg at "$new_access" --arg rt "$new_refresh" --argjson ea "$expires_at" \
        '.claudeAiOauth.accessToken = $at
         | .claudeAiOauth.refreshToken = $rt
         | .claudeAiOauth.expiresAt = $ea' \
        "$CREDENTIALS_FILE" >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$CREDENTIALS_FILE"
      else
        rm -f "$tmp"
      fi
    fi
  fi

  echo "$new_access"
}

render_quota() {
  local token json
  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDENTIALS_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  json=$(fetch_usage "$token")

  if ! is_valid_usage "$json"; then
    # レートリミットは一時的なものなのでリフレッシュは試みず諦める
    if echo "$json" | jq -e '.error.type == "rate_limit_error"' >/dev/null 2>&1; then
      : >"$OUTPUT_FILE"
      return
    fi

    # アクセストークン期限切れ等 → リフレッシュして再試行
    local new_token
    new_token=$(refresh_access_token)
    if [[ -n $new_token ]]; then
      json=$(fetch_usage "$new_token")
    fi

    # それでも駄目なら Claude Code 本体が認証情報を更新した可能性を考慮して読み直す
    if ! is_valid_usage "$json"; then
      local reread
      reread=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDENTIALS_FILE" 2>/dev/null)
      if [[ -n $reread && $reread != "$token" ]]; then
        json=$(fetch_usage "$reread")
      fi
    fi

    if ! is_valid_usage "$json"; then
      : >"$OUTPUT_FILE"
      return
    fi
  fi

  local primary_pct secondary_pct
  primary_pct=$(echo "$json" | jq -r '(.five_hour.utilization // 0) | floor' 2>/dev/null)
  # seven_day はプランによって null になる
  secondary_pct=$(echo "$json" | jq -r 'if .seven_day == null then "" else (.seven_day.utilization // 0) | floor end' 2>/dev/null)

  if [[ -z $primary_pct || $primary_pct == "null" ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local bar=" │ "

  local filled5=$((primary_pct / 10))
  [[ $filled5 -gt 10 ]] && filled5=10
  [[ $filled5 -lt 0 ]] && filled5=0
  local empty5=$((10 - filled5))

  bar+="#[bg=#181825,fg=#fab387] 󰛄 "
  if [[ $filled5 -gt 0 ]]; then
    bar+="#[bg=#fab387,fg=#11111b]"
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

    bar+="#[bg=#181825,fg=#f9e2af] 󰃭 "
    if [[ $filledw -gt 0 ]]; then
      bar+="#[bg=#f9e2af,fg=#11111b]"
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
