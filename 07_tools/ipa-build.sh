#!/bin/bash
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
# ext4 scratch rebuild from pristine project copy (rule 1: project untouched)
rm -rf ~/hello-src; mkdir -p ~/hello-src
cp -r "$P/05_ios_port/HelloWorld/." ~/hello-src/
cd ~/hello-src
echo "=== IPA BUILD START $(date -Is) ==="
"$P/07_tools/xtool/xtool-x86_64.AppImage" dev build --ipa 2>&1 | tee "$P/06_build_artifacts/logs/hello-ipa-build-$(date +%Y%m%d-%H%M%S).log" | tail -15
echo "=== IPA BUILD END $(date -Is) ==="
echo "=== locate IPA ==="
find ~/hello-src/xtool ~/hello-src/.build/out -name '*.ipa' 2>/dev/null
find ~/hello-src/xtool ~/hello-src/.build/out -maxdepth 4 -name 'HelloWorld.app' 2>/dev/null
