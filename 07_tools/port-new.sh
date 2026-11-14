#!/bin/bash
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
TC="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin"
export PATH="$TC:$PATH"
cd "$P/05_ios_port"
"$P/07_tools/xtool/xtool-x86_64.AppImage" new WeatheriOS --skip-setup
cd WeatheriOS
sed -i 's/bundleID:.*/bundleID: dev.kiankonrad.weather/' xtool.yml
echo "== xtool.yml =="; cat xtool.yml
echo "== tree =="; find . -type f | sort
