#!/bin/bash
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
H="$P/05_ios_port/HelloWorld"
echo "== Products/Debug-iphoneos =="
find "$H/.build/out/Products" -maxdepth 3 | head -20
echo; echo "== all files named HelloWorld* under .build =="
find "$H/.build" -name 'HelloWorld*' -not -path '*XCBuildData*' | grep -v -E '\.o$|\.d$|\.swift' | head -20
echo; echo "== app bundles anywhere in .build =="
find "$H/.build" -name '*.app' -type d | head
