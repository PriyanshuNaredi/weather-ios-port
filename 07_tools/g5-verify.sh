#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
H="$P/05_ios_port/HelloWorld"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
echo "== xtool staging dir (unsigned .app) =="
ls -la ~/.cache/xtool/ 2>/dev/null
APP=$(find ~/.cache/xtool -maxdepth 2 -name 'HelloWorld.app' -type d 2>/dev/null | head -1)
echo "app dir: $APP"
[ -n "$APP" ] && find "$APP" -maxdepth 2 -exec ls -la {} \;
echo; echo "== SwiftPM build products =="
find "$H/.build" -maxdepth 3 -type d | head -20
BIN=$(find "$H/.build" -type f -name 'HelloWorld' 2>/dev/null | head -3)
echo "candidate binaries: $BIN"
echo; echo "== file type / Mach-O check =="
for f in $BIN; do
  echo "--- $f ---"
  file "$f" || true
  ls -la "$f"
done
[ -n "$APP" ] && EXE="$APP/HelloWorld" || EXE=$(echo "$BIN" | head -1)
echo; echo "=== EXE: $EXE ==="
file "$EXE"
echo; echo "== Mach-O header parse (od) =="
od -A x -t x1 -N 32 "$EXE"
echo; echo "== size =="
du -h "$EXE"
echo; echo "== llvm filecheck via xcrun-less tools: use lldb's file? =="
"$TC/llvm-readobj" --file-headers "$EXE" 2>/dev/null | head -25 || strings -n 8 "$EXE" | head -5
echo; echo "== copy binary into project (byte copy only, exec bit not needed) =="
cp "$EXE" "$P/06_build_artifacts/hello-world-ios-binary/HelloWorld" 2>/dev/null || { mkdir -p "$P/06_build_artifacts/hello-world-ios-binary"; cp "$EXE" "$P/06_build_artifacts/hello-world-ios-binary/HelloWorld"; }
ls -la "$P/06_build_artifacts/hello-world-ios-binary/"
sha256sum "$EXE"
