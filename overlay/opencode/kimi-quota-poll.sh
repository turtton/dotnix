#!/usr/bin/env bash
# Kimi For Coding quota ポーリング (api.kimi.com/coding/v1/usages; best-effort 表示用)
# ビルド時に quota-report.sh のストアパスが埋め込まれる
QUOTA_REPORT="__QUOTA_REPORT__"
if [[ ! -x $QUOTA_REPORT ]]; then
  QUOTA_REPORT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quota-report.sh"
fi
AUTH_FILE="${HOME}/.local/share/opencode/auth.json"

# 使用率を計算する jq フィルタ (値は "100" のような文字列で返るため数値化する)
# used があればそのまま使い、なければ limit - remaining から算出
PCT_FILTER='
def num: if type == "number" then . else (tonumber? // 0) end;
def pct($d):
  if $d == null then ""
  else
    ($d.limit | num) as $l
    | (if ($d.used // null) != null then ($d.used | num)
       else ($l - ($d.remaining | num)) end) as $u
    | if $l > 0 then ([($u * 100 / $l | floor), 0] | max | tostring) else "" end
  end;
'

render_quota() {
  local token
  token=$(jq -r '."kimi-for-coding".key // empty' "$AUTH_FILE" 2>/dev/null)
  if [[ -z $token ]]; then
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://api.kimi.com/coding/v1/usages" 2>/dev/null) || return

  # usage = 週次クォータ, limits[0] = 5時間ウィンドウ (window.duration: 300min)
  if ! echo "$json" | jq -e '.usage.limit != null' >/dev/null 2>&1; then
    return
  fi

  local session_pct weekly_pct
  session_pct=$(echo "$json" | jq -r "${PCT_FILTER} pct(.limits[0].detail)" 2>/dev/null)
  weekly_pct=$(echo "$json" | jq -r "${PCT_FILTER} pct(.usage)" 2>/dev/null)

  # 5h と weekly を両方出すと表示幅が足りないため、使用率が大きい方のみ出す
  local value=""
  if [[ -n $weekly_pct && $weekly_pct != "null" ]]; then
    if [[ -z $session_pct || $session_pct == "null" ]] || ((weekly_pct > session_pct)); then
      value="week ${weekly_pct}%"
    else
      value="5h ${session_pct}%"
    fi
  elif [[ -n $session_pct && $session_pct != "null" ]]; then
    value="5h ${session_pct}%"
  fi

  if [[ -z $value ]]; then
    return
  fi

  "$QUOTA_REPORT" kimi "$value"
}

render_quota

while true; do
  sleep 180
  render_quota
done
