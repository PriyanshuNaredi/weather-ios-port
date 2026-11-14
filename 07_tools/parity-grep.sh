#!/usr/bin/env bash
# Workstream G helper — grep candidate UI strings in the Swift port.
set -u
pats=(
  "drift" "Map could not load" "Weather data could not be loaded" "Center on"
  "Remove " "Weather map centered" "Forecast chart" "European AQI"
  "Estimated now" "From saved hourly" "Model valid time" "Sunset · Sunrise"
  "Today’s peak" "Today’s total" "Today’s high" "Rain chance" "Area range"
  "Model estimate, not a local sensor" "is24HourFormat" "hour12" "use24HourClock"
)
for pat in "${pats[@]}"; do
  echo "=== [$pat]"
  grep -h -F "$pat" /tmp/sw_all.txt | head -4
done
