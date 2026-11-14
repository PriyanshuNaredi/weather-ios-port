#!/usr/bin/env bash
# Workstream G parity check — every user-visible string literal in the Kotlin
# sources (length >= 8, skipping URL/format/JSON templates) must appear in the
# Swift port sources. Report-only; exit 0 either way.
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
KT="$P/00_original/source/Weather/app/src/main/java/dev/kiankonrad/weather"
SWIFT="/home/naredi/weather-ios-src/Sources/WeatheriOS"
LOG="$P/06_build_artifacts/logs/parity-check-$(date +%Y%m%d-%H%M%S).log"

cat "$KT"/*.kt > /tmp/kt_all.txt
find "$SWIFT" -name "*.swift" | xargs cat > /tmp/sw_all.txt

grep -ho '"[^"]\{8,\}"' "$KT"/*.kt | sort -u | while IFS= read -r s; do
  core="${s%\"}"; core="${core#\"}"
  case "$core" in
    *'{z}'*|*http*|*'{json'*|*'{lat'*|*'{lon'*|*'{var'*|*.png|*'{year'*|*'{day'*) continue;;
  esac
  if ! grep -qF "$core" /tmp/sw_all.txt; then
    echo "MISSING: $core"
  fi
done | tee "$LOG"
echo "parity check complete" | tee -a "$LOG"
