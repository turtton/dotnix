#!/usr/bin/env bash
# Copilot quota ポーリング (copilot_internal は非公開 API; best-effort 表示用)
# __OUTPUT_PATH__ はセットアップ時に sed で実パスに置換される
OUTPUT_FILE="__OUTPUT_PATH__"

render_quota() {
  local json
  json=$(gh api copilot_internal/user 2>/dev/null) || {
    echo "N/A" >"$OUTPUT_FILE"
    return
  }

  local entitlement remaining
  entitlement=$(echo "$json" | jq -r '.quota_snapshots.premium_interactions.entitlement // 0')
  remaining=$(echo "$json" | jq -r '.quota_snapshots.premium_interactions.remaining // 0')

  if [[ $entitlement -eq 0 ]]; then
    echo "N/A" >"$OUTPUT_FILE"
    return
  fi

  local used=$((entitlement - remaining))
  if [[ $used -lt 0 ]]; then used=0; fi
  if [[ $used -gt $entitlement ]]; then used=$entitlement; fi
  local pct=$((used * 100 / entitlement))

  local filled=$((pct / 10))
  if [[ $filled -gt 10 ]]; then filled=10; fi
  if [[ $filled -lt 0 ]]; then filled=0; fi
  local empty=$((10 - filled))
  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done

  echo "${bar} ${used}/${entitlement}" >"$OUTPUT_FILE"
}

render_quota

while true; do
  sleep 180
  render_quota
done
