#!/bin/bash
# Rebuild from ext4 scratch: drvfs cannot hold executable Mach-O files
# (xtool's post-build move failed with EPERM). Source of truth stays in the
# project; ~/hello-src is a throwaway build scratch (documented deviation).
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
rm -rf ~/hello-src; mkdir -p ~/hello-src
cp -r "$P/05_ios_port/HelloWorld/." ~/hello-src/
cd ~/hello-src
mkdir -p "$P/06_build_artifacts/logs"
echo "=== BUILD START $(date -Is) ==="
time "$P/07_tools/xtool/xtool-x86_64.AppImage" dev build 2>&1 | tee "$P/06_build_artifacts/logs/hello-build-ext4-$(date +%Y%m%d-%H%M%S).log" | tail -15
echo "=== BUILD END $(date -Is) ==="
APP=~/hello-src/.build/out/Products/Debug-iphoneos/HelloWorld-App
EXE="$APP/HelloWorld"
echo "== app bundle =="
ls -la "$APP"
echo; echo "== file(1) =="; file "$EXE"
echo; echo "== Mach-O magic =="; od -A x -t x1 -N 32 "$EXE"
echo; echo "== llvm-readobj =="; "$TC/llvm-readobj" --file-headers "$EXE" | head -30
echo; echo "== size / sha256 =="; du -h "$EXE"; sha256sum "$EXE"
echo; echo "== copy product back into project (byte copy) =="
D="$P/06_build_artifacts/hello-world-ios-binary"
rm -rf "$D/HelloWorld-App"; mkdir -p "$D"
cp -r "$APP" "$D/HelloWorld-App"
ls -la "$D/HelloWorld-App/"
sha256sum "$D/HelloWorld-App/HelloWorld"
echo; echo "== xtool.yml of scratch =="
cat ~/hello-src/xtool.yml
