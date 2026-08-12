#!/usr/bin/env bash
# Kimi For Coding quota ポーリング (api.kimi.com/coding/v1/usages; best-effort 表示用)
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"
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
    : >"$OUTPUT_FILE"
    return
  fi

  local json
  json=$(curl -s --connect-timeout 5 --max-time 10 --fail-with-body \
    -H "Authorization: Bearer $token" -H "Accept: application/json" \
    "https://api.kimi.com/coding/v1/usages" 2>/dev/null) || {
    : >"$OUTPUT_FILE"
    return
  }

  # usage = 週次クォータ, limits[0] = 5時間ウィンドウ (window.duration: 300min)
  if ! echo "$json" | jq -e '.usage.limit != null' >/dev/null 2>&1; then
    : >"$OUTPUT_FILE"
    return
  fi

  local session_pct weekly_pct
  session_pct=$(echo "$json" | jq -r "${PCT_FILTER} pct(.limits[0].detail)" 2>/dev/null)
  weekly_pct=$(echo "$json" | jq -r "${PCT_FILTER} pct(.usage)" 2>/dev/null)

  if [[ -z $session_pct && -z $weekly_pct ]]; then
    : >"$OUTPUT_FILE"
    return
  fi

  local bar=" │ "

  if [[ -n $session_pct && $session_pct != "null" ]]; then
    local filled5=$((session_pct / 10))
    [[ $filled5 -gt 10 ]] && filled5=10
    [[ $filled5 -lt 0 ]] && filled5=0
    local empty5=$((10 - filled5))

    bar+="#[bg=#181825,fg=#89dceb] 󰖔 "
    if [[ $filled5 -gt 0 ]]; then
      bar+="#[bg=#89dceb,fg=#11111b]"
      for ((i = 0; i < filled5; i++)); do bar+="█"; done
    fi
    if [[ $empty5 -gt 0 ]]; then
      bar+="#[bg=#313244,fg=#585b70]"
      for ((i = 0; i < empty5; i++)); do bar+="░"; done
    fi
    bar+="#[bg=#181825,fg=#cdd6f4] ${session_pct}% "
  fi

  if [[ -n $weekly_pct && $weekly_pct != "null" ]]; then
    local filledw=$((weekly_pct / 10))
    [[ $filledw -gt 10 ]] && filledw=10
    [[ $filledw -lt 0 ]] && filledw=0
    local emptyw=$((10 - filledw))

    bar+="#[bg=#181825,fg=#a6e3a1] 󰃭 "
    if [[ $filledw -gt 0 ]]; then
      bar+="#[bg=#a6e3a1,fg=#11111b]"
      for ((i = 0; i < filledw; i++)); do bar+="█"; done
    fi
    if [[ $emptyw -gt 0 ]]; then
      bar+="#[bg=#313244,fg=#585b70]"
      for ((i = 0; i < emptyw; i++)); do bar+="░"; done
    fi
    bar+="#[bg=#181825,fg=#cdd6f4] ${weekly_pct}%"
  fi

  echo "$bar" >"$OUTPUT_FILE"
}

render_quota

while true; do
  sleep 180
  render_quota
done
