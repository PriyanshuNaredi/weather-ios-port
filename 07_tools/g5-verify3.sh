#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
APP="$P/05_ios_port/HelloWorld/.build/out/Products/Debug-iphoneos/HelloWorld-App"
echo "== app bundle contents =="
find "$APP" -exec ls -ld {} \; | head -20
EXE="$APP/HelloWorld"
echo; echo "== file(1) =="
file "$EXE" || true
echo; echo "== Mach-O magic (od, first 32 bytes) =="
od -A x -t x1 -N 32 "$EXE"
echo; echo "== llvm-readobj headers =="
"$TC/llvm-readobj" --file-headers "$EXE" 2>/dev/null | head -30
echo; echo "== size + sha256 =="
du -h "$EXE"; sha256sum "$EXE"
echo; echo "== archive into project (plain byte copy) =="
D="$P/06_build_artifacts/hello-world-ios-binary"
mkdir -p "$D"
cp -r "$APP" "$D/HelloWorld-App"
ls -la "$D/HelloWorld-App/"
sha256sum "$D/HelloWorld-App/HelloWorld"
echo; echo "== rebuild timing from log =="
grep -E 'BUILD (START|END)|Build complete' "$P"/06_build_artifacts/logs/hello-build-*.log
