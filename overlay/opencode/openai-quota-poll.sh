#!/usr/bin/env bash
# OpenAI quota ポーリング (OpenAI backend-api/wham/usage; best-effort 表示用)
# ビルド時に quota-report.sh のストアパスが埋め込まれる
QUOTA_REPORT="__QUOTA_REPORT__"
if [[ ! -x $QUOTA_REPORT ]]; then
  QUOTA_REPORT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quota-report.sh"
fi
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
        return
      fi
      token="$new_token"
    fi
  else
    # 保存トークンがない → リフレッシュを試みる
    token=$(refresh_access_token)
    if [[ -z $token ]]; then
      return
    fi
  fi

  # リフレッシュした場合は新しいトークンでAPI呼び出し
  if [[ -z ${json+x} ]]; then
    json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
      -H "Authorization: Bearer $token" -H "Accept: application/json" \
      "https://chatgpt.com/backend-api/wham/usage" 2>/dev/null) || return
  fi

  local primary_pct secondary_pct
  primary_pct=$(echo "$json" | jq -r '(.rate_limit.primary_window.used_percent // 0) | floor' 2>/dev/null)
  # secondary_window は 5h limit 廃止後 null になる (API が null を返す)
  secondary_pct=$(echo "$json" | jq -r 'if .rate_limit.secondary_window == null then "" else (.rate_limit.secondary_window.used_percent // 0) | floor end' 2>/dev/null)

  if [[ -z $primary_pct || $primary_pct == "null" ]]; then
    return
  fi

  local value="5h ${primary_pct}%"
  if [[ -n $secondary_pct && $secondary_pct != "null" ]]; then
    value+=" / week ${secondary_pct}%"
  fi

  "$QUOTA_REPORT" openai "$value"
}

render_quota

while true; do
  sleep 180
  render_quota
done
