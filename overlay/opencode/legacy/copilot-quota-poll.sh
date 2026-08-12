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

  local bar="" suffix=""

  if [[ $used -le $entitlement ]]; then
    local pct=$((used * 100 / entitlement))
    local filled=$((pct / 10))
    [[ $filled -gt 10 ]] && filled=10
    [[ $filled -lt 0 ]] && filled=0
    local empty=$((10 - filled))
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
  else
    local overage=$((used - entitlement))
    local overage_pct=$((overage * 100 / entitlement))
    local overage_lap=$((overage_pct / 100))
    local in_lap=$((overage_pct % 100))

    local lap_colors=("#f38ba8" "#f9e2af" "#cba6f7" "#a6e3a1")
    local num_colors=${#lap_colors[@]}
    local current_idx=$((overage_lap % num_colors))
    local prev_color="#cdd6f4"
    if [[ $overage_lap -gt 0 ]]; then
      prev_color="${lap_colors[$(((overage_lap - 1) % num_colors))]}"
    fi

    local overlay_filled=$((in_lap / 10))
    [[ $overlay_filled -lt 1 && $in_lap -gt 0 ]] && overlay_filled=1
    [[ $in_lap -eq 0 ]] && overlay_filled=0
    [[ $overlay_filled -gt 10 ]] && overlay_filled=10
    local prev_remaining=$((10 - overlay_filled))

    if [[ $overlay_filled -gt 0 ]]; then
      bar+="#[fg=${lap_colors[$current_idx]}]"
      for ((i = 0; i < overlay_filled; i++)); do bar+="█"; done
    fi
    if [[ $prev_remaining -gt 0 ]]; then
      bar+="#[fg=${prev_color}]"
      for ((i = 0; i < prev_remaining; i++)); do bar+="█"; done
    fi
    bar+="#[fg=#cdd6f4]"

    local cost_cents=$((overage * 4))
    local cost_dollars=$((cost_cents / 100))
    local cost_frac=$((cost_cents % 100))
    suffix=$(printf ' +$%d.%02d' "$cost_dollars" "$cost_frac")
  fi

  echo "${bar} ${used}/${entitlement}${suffix}" >"$OUTPUT_FILE"
}

render_quota

while true; do
  sleep 180
  render_quota
done
