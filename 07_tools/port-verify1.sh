#!/usr/bin/env bash
# Verify the WeatheriOS foundation build output and copy artifacts back (no overwrite).
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
LOG="$P/06_build_artifacts/logs/port-foundation-verify-$(date +%Y%m%d-%H%M%S).log"
APP=~/weather-ios-src/xtool/WeatheriOS.app
BIN="$APP/WeatheriOS"

echo "=== app bundle ===" | tee "$LOG"
ls -la "$APP" 2>&1 | tee -a "$LOG"

echo "=== Info.plist key fields ===" | tee -a "$LOG"
for k in CFBundleIdentifier CFBundleExecutable CFBundleShortVersionString MinimumOSVersion; do
  echo -n "$k: " | tee -a "$LOG"
  grep -A1 "<key>$k</key>" "$APP/Info.plist" | tail -1 | sed 's/<[^>]*>//g' | tr -d ' ' | tee -a "$LOG"
done

echo "=== executable ===" | tee -a "$LOG"
file "$BIN" 2>&1 | tee -a "$LOG"
echo "LC_CODE_SIGNATURE count (expect 0): $(grep -c LC_CODE_SIGNATURE "$BIN")" | tee -a "$LOG"
echo "_CodeSignature present: $(test -d "$APP/_CodeSignature" && echo YES || echo NO)" | tee -a "$LOG"
echo "embedded.mobileprovision present: $(test -f "$APP/embedded.mobileprovision" && echo YES || echo NO)" | tee -a "$LOG"
sha256sum "$BIN" | tee -a "$LOG"

echo "=== copy artifacts back (cp -n, no overwrite) ===" | tee -a "$LOG"
OUT="$P/06_build_artifacts/unsigned-binaries"
mkdir -p "$OUT"
cp -n "$BIN" "$OUT/WeatheriOS-foundation-$(date +%Y%m%d).bin" && echo "binary copied" | tee -a "$LOG"
cp -rn "$APP" "$P/05_ios_port/WeatheriOS/build-output/WeatheriOS.app" 2>/dev/null || \
  mkdir -p "$P/05_ios_port/WeatheriOS/build-output" && cp -rn "$APP" "$P/05_ios_port/WeatheriOS/build-output/WeatheriOS.app"
echo "app bundle copied to project build-output/" | tee -a "$LOG"

echo "=== source immutability checks ===" | tee -a "$LOG"
echo "Android source file count: $(find "$P/00_original/source/Weather" -name '*.kt' | wc -l)" | tee -a "$LOG"
echo "HelloWorld untouched (newest file): $(find "$P/05_ios_port/HelloWorld" -type f -newer "$P/05_ios_port/HelloWorld/Package.swift" | wc -l) files newer than Package.swift" | tee -a "$LOG"
echo "=== done ===" | tee -a "$LOG"
