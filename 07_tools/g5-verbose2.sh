#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
cd ~/hello-src
"$TC/swift" build -v --swift-sdk darwin > /tmp/hello-v.log 2>&1
echo "exit=$?"
cp /tmp/hello-v.log "$P/06_build_artifacts/logs/hello-swift-build-verbose.log"
echo "== compile command (first swift-frontend) =="
grep -m1 'swift-frontend' /tmp/hello-v.log | cut -c1-1200
echo; echo "== link command =="
grep -m1 -E 'clang.*(-o|HelloWorld)' /tmp/hello-v.log | cut -c1-1200
echo; echo "== result =="
tail -3 /tmp/hello-v.log
find ~/hello-src/.build -maxdepth 4 -name '*.o' -o -name 'libHelloWorld*' | head
