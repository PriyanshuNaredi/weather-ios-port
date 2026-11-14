#!/bin/bash
set -u
X="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool/xtool-x86_64.AppImage"
echo "== xtool new --help =="
"$X" new --help
echo; echo "== xtool dev --help =="
"$X" dev --help
echo; echo "== xtool dev build --help (if exists) =="
"$X" dev build --help 2>&1 | head -20
echo; echo "== token metadata (NO contents) =="
stat -c 'file=%n | perms=%a | owner=%U:%G | size=%s bytes | mtime=%y | ctime=%z' ~/.config/xtool/data/XTLAuthToken
stat -c 'dir=%n | perms=%a | owner=%U:%G' ~/.config/xtool/data ~/.config/xtool
