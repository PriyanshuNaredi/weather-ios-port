#!/bin/bash
# baseline-manifest.sh — Phase 1 of the crash/navigation/scroll mission:
# record the source manifest + SHA-256 of every Swift source and artifact
# BEFORE any edits. Read-only; creates a single manifest file (never deletes).
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
OUT="$P/06_build_artifacts/fix2-baseline-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

{
  echo "# Pre-fix manifest — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# (Phase 1: state recorded before crash/navigation/scroll investigation)"
  echo
  echo "## Swift sources (05_ios_port)"
  find "$P/05_ios_port" -name "*.swift" -type f | sort | while read -r f; do
    rel="${f#$P/}"
    h=$(sha256sum "$f" | cut -d' ' -f1)
    echo "$h  $rel"
  done
  echo
  echo "## Build artifacts (06_build_artifacts/weather-ios-unsigned)"
  find "$OUT/../weather-ios-unsigned" -maxdepth 1 -type f \( -name "*.ipa" -o -name "*.sha256" -o -name "*.txt" -o -name "*.md" \) | sort | while read -r f; do
    rel="${f#$P/}"
    h=$(sha256sum "$f" | cut -d' ' -f1)
    echo "$h  $rel"
  done
  echo
  echo "## Logs"
  ls -la "$P/06_build_artifacts/logs/" | tail -n +2
  echo
  echo "## Android source untouched check (original repo)"
  find "$P/02_android_src" -name "*.kt" -type f 2>/dev/null | wc -l
  echo "Kotlin files present (count only — never modified)."
} > "$OUT/MANIFEST.txt"

# copy diagnostic logs into the snapshot for preservation
cp -r "$P/06_build_artifacts/logs" "$OUT/logs-copy" 2>/dev/null || true
echo "manifest: $OUT/MANIFEST.txt"
sha256sum "$OUT/MANIFEST.txt"
