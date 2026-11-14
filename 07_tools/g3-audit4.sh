#!/bin/bash
set -u
echo "== xtool config / cache / logs (origin evidence) =="
ls -la ~/.config/xtool 2>/dev/null && find ~/.config/xtool -type f | head -20
ls ~/.cache 2>/dev/null | head -20
find ~/.cache -maxdepth 2 -iname '*xtool*' -o -maxdepth 2 -iname '*darwin*' 2>/dev/null | head
echo; echo "== SDK download provenance: xtool logs? =="
find ~/.local/share -maxdepth 3 -iname '*xtool*' 2>/dev/null | head
echo; echo "== ld64.lld wrapper =="
cat "$HOME/.swiftpm/swift-sdks/darwin.artifactbundle/toolset/bin/ld64.lld"
echo; echo "== host swift compiler version =="
D="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04"
"$D/usr/bin/swift" --version
echo; echo "== required linker tools present on host? =="
which clang clang++ 2>/dev/null || echo "clang: NOT on PATH"
ls "$D/usr/bin" | grep -iE 'clang|lld|swift-' | head -20
