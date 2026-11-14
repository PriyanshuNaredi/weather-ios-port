#!/bin/bash
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
echo "== REPRODUCE.md (head 20 + grep swift/ipa) =="
head -20 "$P/REPRODUCE.md"
grep -n -i -E "xtool|ipa" "$P/REPRODUCE.md" | tail -15
echo; echo "== CHANGELOG.md (head 20) =="
head -20 "$P/CHANGELOG.md"
