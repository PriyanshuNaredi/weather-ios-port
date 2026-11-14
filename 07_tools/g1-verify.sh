#!/bin/bash
# G1 verification: swift --version, swift sdk list, tarball/extracted integrity, disk usage.
set -u
D="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux"
TC="$D/swift-6.4.2-RELEASE-ubuntu26.04"
export PATH="$TC/usr/bin:$PATH"
echo "== swift --version =="; swift --version
echo "== swift sdk list =="; swift sdk list; echo "(exit=$? — empty list expected; darwin SDK is added by xtool setup, G4)"
echo "== tar vs extracted file count =="
echo "in tarball: $(tar -tzf "$D/swift-6.4.2-RELEASE-ubuntu26.04.tar.gz" | grep -v '/$' | wc -l)"
echo "extracted:  $(find "$TC" -type f | wc -l)"
echo "== disk usage =="
du -sh "$TC"
du -sh "$D/swift-6.4.2-RELEASE-ubuntu26.04.tar.gz"
du -sh "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool"
echo "== xtool --version =="
"/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/xtool/xtool-x86_64.AppImage" --version
TC="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04"
echo "== integrity recount =="
echo "extracted files: $(find "$TC" -type f | wc -l), symlinks: $(find "$TC" -type l | wc -l), sum: $(( $(find "$TC" -type f | wc -l) + $(find "$TC" -type l | wc -l) ))"
