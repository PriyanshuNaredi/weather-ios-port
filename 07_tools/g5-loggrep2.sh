#!/bin/bash
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
L="$P/06_build_artifacts/logs/hello-build-ext4-20261112-224627.log"
wc -l "$L"
echo "== sample lines 1-30 =="
head -30 "$L"
echo; echo "== lines containing iPhoneOS or swiftc or clang (first 5) =="
grep -n -m5 -E 'iPhoneOS|swiftc|clang' "$L" | cut -c1-400
echo; echo "== a few 'warning' lines =="
grep -i 'warning' "$L" | sort | uniq -c | sort -rn | head -5
