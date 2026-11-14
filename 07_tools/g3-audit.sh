#!/bin/bash
# Read-only audit of the bundled Darwin SDK artifactbundle.
set -u
X="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool/xtool-x86_64.AppImage"
B="$HOME/.swiftpm/swift-sdks/darwin.artifactbundle"
echo "== 1. xtool sdk status =="
"$X" sdk status
echo; echo "== 2. artifactbundle root =="
ls -la "$B"
echo; echo "== 2b. Info.json =="
cat "$B/Info.json"
echo; echo "== 2c. tree (2 levels) =="
find "$B" -maxdepth 3 -type d | head -40
echo; echo "== file count / size =="
find "$B" | wc -l; du -sh "$B"
echo; echo "== 4. timestamps =="
stat -c '%n | mtime=%y' "$B" "$B/Info.json" 2>/dev/null
