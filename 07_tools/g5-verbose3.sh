#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
cd ~/hello-src
"$TC/swift" build -v --swift-sdk darwin --triple arm64-apple-ios > /tmp/hello-v.log 2>&1
echo "exit=$?"
cp /tmp/hello-v.log "$P/06_build_artifacts/logs/hello-swift-build-verbose.log"
echo "== swift-frontend command =="
grep -m1 'swift-frontend' /tmp/hello-v.log | cut -c1-1400
echo; echo "== link command =="
grep -m1 -E '/usr/bin/clang|autolink|ld64' /tmp/hello-v.log | cut -c1-1400
echo; echo "== result =="
tail -2 /tmp/hello-v.log
ls -la ~/hello-src/.build/arm64-apple-ios/debug/ 2>/dev/null | head
