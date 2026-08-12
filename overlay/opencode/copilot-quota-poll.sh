#!/usr/bin/env bash
# Copilot quota ポーリング (copilot_internal は非公開 API; best-effort 表示用)
# ビルド時に quota-report.sh のストアパスが埋め込まれる
QUOTA_REPORT="__QUOTA_REPORT__"
if [[ ! -x $QUOTA_REPORT ]]; then
  QUOTA_REPORT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quota-report.sh"
fi

render_quota() {
  local json
  json=$(gh api copilot_internal/user 2>/dev/null) || return

  local entitlement remaining
  entitlement=$(echo "$json" | jq -r '.quota_snapshots.premium_interactions.entitlement // 0')
  remaining=$(echo "$json" | jq -r '.quota_snapshots.premium_interactions.remaining // 0')

  if [[ $entitlement -eq 0 ]]; then
    return
  fi

  local used=$((entitlement - remaining))
  if [[ $used -lt 0 ]]; then used=0; fi

  local suffix=""
  if [[ $used -gt $entitlement ]]; then
    local overage=$((used - entitlement))
    local cost_cents=$((overage * 4))
    suffix=$(printf ' +$%d.%02d' $((cost_cents / 100)) $((cost_cents % 100)))
  fi

  "$QUOTA_REPORT" copilot "${used}/${entitlement}${suffix}"
}

render_quota

while true; do
  sleep 180
  render_quota
done
