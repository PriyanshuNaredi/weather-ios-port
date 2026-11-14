#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
APP=~/hello-src/xtool/HelloWorld.app
EXE="$APP/HelloWorld"
echo "== app bundle tree =="
find "$APP" -exec ls -ld {} \;
echo; echo "== Info.plist bundle id =="
plutil -p "$APP/Info.plist" 2>/dev/null | grep -iE 'BundleIdentifier|Executable|BundleName' || strings "$APP/Info.plist" | grep -iE 'dev\.kiankonrad|CFBundle' | head
echo; echo "== file(1) on executable =="
file "$EXE"
echo; echo "== Mach-O magic (od) =="
od -A x -t x1 -N 32 "$EXE"
echo; echo "== llvm-readobj file headers =="
"$TC/llvm-readobj" --file-headers "$EXE" | head -30
echo; echo "== arch check =="
"$TC/llvm-nm" --version >/dev/null 2>&1; lipo -info "$EXE" 2>/dev/null || "$TC/llvm-objdump" -f "$EXE" 2>/dev/null | head -8
echo; echo "== size / sha256 =="
du -h "$EXE"; sha256sum "$EXE"
echo; echo "== copy bundle into project (byte copy, no exec-bit preservation on drvfs) =="
D="$P/06_build_artifacts/hello-world-ios-binary"
rm -rf "$D/HelloWorld-App"; mkdir -p "$D"
cp -r "$APP" "$D/HelloWorld-App"
ls -la "$D/HelloWorld-App/"
sha256sum "$D/HelloWorld-App/HelloWorld"
