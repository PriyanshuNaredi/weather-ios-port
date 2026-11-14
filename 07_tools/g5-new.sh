#!/bin/bash
set -e
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
X="$P/07_tools/xtool/xtool-x86_64.AppImage"
cd "$P/05_ios_port"
"$X" new HelloWorld --skip-setup
echo "--- template contents ---"
find HelloWorld -type f | sort
echo "--- xtool.yml ---"
cat HelloWorld/xtool.yml
echo "--- Package.swift ---"
cat HelloWorld/Package.swift
