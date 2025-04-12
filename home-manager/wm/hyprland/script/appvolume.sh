#!/usr/bin/env bash
PIDS=$(hyprctl activewindow -j | jq -r '.pid as $id | "pgrep -P \($id) | paste -sd \",\"  | echo \"\($id),$(</dev/stdin)\""' | sh)
if [ -z "$PIDS" ]; then
  exit 1
fi
pw-dump | jq -r 'map(select(.type == "PipeWire:Interface:Node" and (.info.props."application.process.id" | IN('"$PIDS"'))) | .info.props)' | jq -c '.[]' | while read CLIENT; do
  ID=$(echo "$CLIENT" | jq -r '."object.id"')
  APP=$(echo "$CLIENT" | jq -r '."application.name"')
  # Volume: 0.00 -> 0.00 * 100
  VOLUME=$(wpctl get-volume $ID | awk '{print int($2 * 100)}')
  zenity --scale --text "Adjust volume for client $APP" --value="$VOLUME" --min-value=0 --max-value=150 --print-partial |
    while read new_vol; do
      wpctl set-volume $ID $(echo "$new_vol" | awk '{print $1 / 100}')
    done
done
