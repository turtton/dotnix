input=$(cat)

bun x ccusage statusline <<<"$input" || true

mapfile -t fields < <(jq -r '.rate_limits | .five_hour, .seven_day | (.used_percentage // ""), (.resets_at // "")' <<<"$input")
now=$(date +%s)

remaining() {
  local secs=$(($1 - now))
  if ((secs < 0)); then
    secs=0
  fi
  local d=$((secs / 86400)) h=$((secs % 86400 / 3600)) m=$((secs % 3600 / 60))
  if ((d > 0)); then
    printf '%dd%dh' "$d" "$h"
  elif ((h > 0)); then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

segment() {
  local label=$1 pct=$2 reset=$3
  pct=$(printf '%.0f' "$pct")

  local color=32
  if ((pct >= 80)); then
    color=31
  elif ((pct >= 50)); then
    color=33
  fi

  local filled=$(((pct + 5) / 10)) bar="" i
  if ((filled > 10)); then
    filled=10
  fi
  for ((i = 0; i < 10; i++)); do
    if ((i < filled)); then
      bar+="█"
    else
      bar+="░"
    fi
  done

  printf '%s \e[%sm%s %3d%%\e[0m' "$label" "$color" "$bar" "$pct"
  if [[ -n $reset ]]; then
    printf ' (%s)' "$(remaining "$reset")"
  fi
}

segments=()
if [[ -n ${fields[0]:-} ]]; then
  segments+=("$(segment 5h "${fields[0]}" "${fields[1]}")")
fi
if [[ -n ${fields[2]:-} ]]; then
  segments+=("$(segment 7d "${fields[2]}" "${fields[3]}")")
fi

if ((${#segments[@]} > 0)); then
  printf '%s' "${segments[0]}"
  if ((${#segments[@]} > 1)); then
    printf ' │ %s' "${segments[1]}"
  fi
  printf '\n'
fi
