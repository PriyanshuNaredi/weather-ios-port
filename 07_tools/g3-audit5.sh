#!/bin/bash
set -u
echo "== ~/.cache/xtool (SDK provenance) =="
find ~/.cache/xtool -maxdepth 3 | head -30
du -sh ~/.cache/xtool 2>/dev/null
echo; echo "== swiftpm cache artifacts =="
ls ~/.cache/org.swift.swiftpm 2>/dev/null | head
find ~/.cache/org.swift.swiftpm -maxdepth 3 -iname '*darwin*' 2>/dev/null | head
echo; echo "== xtool data file sizes (metadata only — contents NOT printed) =="
ls -la ~/.config/xtool/data
echo; echo "== install-time evidence: newest files in SDK =="
find "$HOME/.swiftpm/swift-sdks/darwin.artifactbundle" -newermt "2026-11-12 14:50" -type f 2>/dev/null | wc -l
stat -c '%y %n' "$HOME/.swiftpm/swift-sdks/darwin.artifactbundle/OpenAppleMacrosServer" "$HOME/.swiftpm/swift-sdks/darwin.artifactbundle/toolset/bin/llvm-lib"
echo; echo "== does xtool sdk status exist in cache as downloaded archive? =="
find ~/.cache/xtool -type f -size +10M 2>/dev/null | head
