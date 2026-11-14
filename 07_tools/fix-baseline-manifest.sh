#!/usr/bin/env bash
# fix-baseline-manifest.sh — record the pre-fix source state (section 1 of the
# stability mission). No git repository exists in this workspace, so the
# baseline is recorded as a SHA-256 manifest of every Swift source file plus a
# note that the working IPA is preserved untouched. Creates new files only.
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$P/06_build_artifacts/fix-baseline-$STAMP"
mkdir -p "$OUT"

{
  echo "# Pre-fix baseline manifest — $STAMP"
  echo "Baseline IPA preserved (never modified): 06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-115901.ipa"
  echo "SHA-256: 6a032f8aa5cd005a1f57fbd699ec2e41a77122645a59a867363d8f70a5a1231e"
  echo
  echo "## Swift sources (SHA-256 before any stability edits)"
  find "$P/05_ios_port/WeatheriOS/Sources" "$P/05_ios_port/WeatherLogicTests" -name "*.swift" -type f | sort | while read -r f; do
    rel=${f#"$P"/}
    printf '%s  %s\n' "$(sha256sum "$f" | cut -d' ' -f1)" "$rel"
  done
  echo
  echo "## Original Android source untouched (spot check)"
  sha256sum "$P/00_original/source/Weather/app/src/main/java/dev/kiankonrad/weather/MainActivity.kt" \
            "$P/00_original/source/Weather/app/src/main/java/dev/kiankonrad/weather/Maps.kt"
} > "$OUT/BASELINE-MANIFEST.md"

cat "$OUT/BASELINE-MANIFEST.md"
echo "=== manifest written to $OUT ==="
