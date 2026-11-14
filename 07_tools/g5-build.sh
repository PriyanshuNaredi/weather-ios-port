#!/bin/bash
# Compile+link only: xtool dev build (no --sign, no --ipa). Swift 6.4.2 on PATH.
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
H="$P/05_ios_port/HelloWorld"
# User-approved bundle ID
sed -i 's/^bundleID: .*/bundleID: dev.kiankonrad.weather.hello/' "$H/xtool.yml"
cat "$H/xtool.yml"
echo "--- sources ---"
cat "$H/Sources/HelloWorld/HelloWorldApp.swift"
cat "$H/Sources/HelloWorld/ContentView.swift"
mkdir -p "$P/06_build_artifacts/logs"
cd "$H"
echo "=== BUILD START $(date -Is) ==="
time "$P/07_tools/xtool/xtool-x86_64.AppImage" dev build 2>&1 | tee "$P/06_build_artifacts/logs/hello-build-$(date +%Y%m%d-%H%M%S).log"
echo "=== BUILD END $(date -Is) ==="
echo "--- find .app / executables ---"
find "$H/.build" -name '*.app' -maxdepth 6
find "$H/.build" -type f -perm -u+x -name 'HelloWorld' 2>/dev/null
