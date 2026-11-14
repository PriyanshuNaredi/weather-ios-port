#!/usr/bin/env bash
# Port foundation build (Step 4) — ext4 scratch, unsigned, no Apple services.
# Mirrors WeatheriOS from the project dir into ~/weather-ios-src, runs
# `xtool dev build` (NO --sign, NO --ipa), then byte-copies build outputs back.
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
export PATH="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin:$PATH"
XT="$P/07_tools/xtool/xtool-x86_64.AppImage"
LOG="$P/06_build_artifacts/logs/port-foundation-build-$(date +%Y%m%d-%H%M%S).log"
SRC="$P/05_ios_port/WeatheriOS"

echo "=== swift version check ===" | tee "$LOG"
swift --version 2>&1 | tee -a "$LOG"

echo "=== mirror WeatheriOS to ext4 scratch ===" | tee -a "$LOG"
rm -rf ~/weather-ios-src
cp -r "$SRC" ~/weather-ios-src
echo "mirrored:" | tee -a "$LOG"
ls ~/weather-ios-src | tee -a "$LOG"

echo "=== xtool dev build (unsigned, no --sign, no --ipa) ===" | tee -a "$LOG"
cd ~/weather-ios-src
"$XT" dev build 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
echo "xtool dev build exit code: $RC" | tee -a "$LOG"

if [ "$RC" -eq 0 ]; then
  echo "=== locate and verify binary ===" | tee -a "$LOG"
  BIN=$(find ~/weather-ios-src/.build -type f -name WeatheriOS -perm -u+x 2>/dev/null | head -1)
  echo "binary: $BIN" | tee -a "$LOG"
  if [ -n "$BIN" ]; then
    file "$BIN" 2>&1 | tee -a "$LOG"
    echo "LC_CODE_SIGNATURE count (expect 0):" | tee -a "$LOG"
    grep -c LC_CODE_SIGNATURE "$BIN" | tee -a "$LOG"
    test -d "$BIN.dSYM" && echo "dSYM present" | tee -a "$LOG"
  fi
  # copy binary back into project artifacts without overwriting
  if [ -n "$BIN" ]; then
    OUT="$P/06_build_artifacts/unsigned-binaries"
    mkdir -p "$OUT"
    cp -n "$BIN" "$OUT/WeatheriOS-foundation-$(date +%Y%m%d).bin" && echo "copied binary to $OUT" | tee -a "$LOG"
  fi
fi
echo "=== done ===" | tee -a "$LOG"
exit "$RC"
