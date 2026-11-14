#!/bin/bash
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
IPA=~/hello-src/xtool/HelloWorld.ipa
echo "== sha256 of IPA =="; sha256sum "$IPA"; du -h "$IPA"
echo; echo "== ZIP listing (unzip -l) =="; unzip -l "$IPA" | head -25
echo; echo "== extract for inspection =="
rm -rf ~/ipa-inspect; mkdir -p ~/ipa-inspect; cd ~/ipa-inspect
unzip -q "$IPA"; find . -maxdepth 3 | sort
echo; echo "== Info.plist key fields =="
TCBINDIR="$TC"; PLIST=Payload/HelloWorld.app/Info.plist
if [ -x "$TCBINDIR/plutil" ]; then "$TCBINDIR/plutil" -p "$PLIST" | head -20; else
  strings "$PLIST" | grep -A1 -E "CFBundleIdentifier|CFBundleExecutable|CFBundleShortVersion|MinimumOSVersion|CFBundlePackageType" | head -20; fi
echo; echo "== executable arch =="
EXE=Payload/HelloWorld.app/HelloWorld
file "$EXE"; od -A x -t x1 -N 32 "$EXE"
echo; echo "== LC_CODE_SIGNATURE present? =="
"$TCBINDIR/llvm-objdump" -macho -private-headers "$EXE" 2>/dev/null | grep -c "LC_CODE_SIGNATURE" || true
echo; echo "== _CodeSignature dir? =="
ls -la Payload/HelloWorld.app/ | grep -i codesign || echo "no _CodeSignature (unsigned)"
echo; echo "== embedded.mobileprovision? =="
ls Payload/HelloWorld.app/embedded.mobileprovision 2>/dev/null || echo "none (unsigned)"
echo; echo "== copy into project (no overwrite) =="
D="$P/06_build_artifacts/unsigned-ipa"
mkdir -p "$D"
cp "$IPA" "$D/HelloWorld-unsigned.ipa"
sha256sum "$D/HelloWorld-unsigned.ipa"; ls -la "$D"
