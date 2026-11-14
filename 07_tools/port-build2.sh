#!/usr/bin/env bash
# Workstream B compile check — same procedure as port-build1.sh (ext4 scratch,
# unsigned xtool dev build, no --sign / --ipa / Apple services). New script per
# project rule 3 (never overwrite existing files).
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
export PATH="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin:$PATH"
XT="$P/07_tools/xtool/xtool-x86_64.AppImage"
LOG="$P/06_build_artifacts/logs/port-workstreamB-build-$(date +%Y%m%d-%H%M%S).log"
SRC="$P/05_ios_port/WeatheriOS"

echo "=== mirror WeatheriOS to ext4 scratch ===" | tee "$LOG"
rm -rf ~/weather-ios-src
cp -r "$SRC" ~/weather-ios-src

echo "=== xtool dev build (unsigned) ===" | tee -a "$LOG"
cd ~/weather-ios-src
"$XT" dev build 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
echo "xtool dev build exit code: $RC" | tee -a "$LOG"
exit "$RC"
