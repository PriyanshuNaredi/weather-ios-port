#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
S=~/hello-src/.build/out/Intermediates.noindex
echo "== common-args.resp (compiler flags) =="
F=$(find "$S" -name '*common-args.resp' | head -1); echo "file: $F"
cat "$F" 2>/dev/null | tr '\n' ' ' | cut -c1-1600
echo; echo; echo "== LinkFileList (link inputs) =="
L=$(find "$S" -name '*.LinkFileList' | head -1); cat "$L"
echo; echo "== SDK root from OutputFileMap/dependency =="
D=$(find "$S" -name '*dependencies-1.json' | head -1)
grep -oE '/[^"]*iPhoneOS[^"]*sdk[^"]*' "$D" 2>/dev/null | head -3
echo; echo "== XCBuildData build db (link command) =="
find ~/hello-src/.build/out/XCBuildData -name 'build.db' -o -name '*.json' | head -5
