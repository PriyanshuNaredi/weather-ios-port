#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
cd ~/hello-src
"$TC/swift" build -v --swift-sdk darwin 2>&1 | tee "$P/06_build_artifacts/logs/hello-swift-build-verbose.log" | grep -E 'swift-frontend|clang|ld64|/usr/bin/clang' | head -6 | cut -c1-900
