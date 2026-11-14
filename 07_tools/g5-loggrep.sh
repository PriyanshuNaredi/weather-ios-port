#!/bin/bash
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
L=$(ls -t "$P"/06_build_artifacts/logs/hello-build-ext4-*.log | head -1)
echo "log: $L"
echo "== first swiftc invocation (truncated) =="
grep -m1 -o 'swift-frontend[^ ]*.*' "$L" | head -c 1500
echo; echo; echo "== linker invocation =="
grep -m1 -oE '[^ ]*clang[ -][^ ]*.*'-o "$L" | head -c 800 || true
grep -m1 'clang' "$L" | head -c 1200
echo; echo; echo "== SDK path used =="
grep -m1 -oE '(iPhoneOS[0-9.]*\.sdk)' "$L" | head -1
grep -m1 -oE 'target arm64-apple-ios[0-9.]*' "$L" | head -1
echo; echo "== warnings/errors count =="
echo "warning lines: $(grep -c -i 'warning' "$L")"
echo "error lines:   $(grep -c -i 'error' "$L")"
