#!/bin/bash
X="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool/xtool-x86_64.AppImage"
echo "== xtool auth --help =="
"$X" auth --help
echo; echo "== xtool setup --help =="
"$X" setup --help
