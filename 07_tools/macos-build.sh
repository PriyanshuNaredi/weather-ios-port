#!/bin/bash
# macos-build.sh — build, install and launch the WeatheriOS port on macOS/Xcode.
#
# Replaces the Linux-only xtool pipeline for day-to-day work on the Hackintosh.
# Requires: Xcode (full install), xcodegen (`brew install xcodegen`).
#
#   ./07_tools/macos-build.sh                 # build for the simulator and launch
#   ./07_tools/macos-build.sh --device-list   # list simulator destinations
#   SIM="iPhone 16 Pro" ./07_tools/macos-build.sh
#
# Exit codes: 0 = built and launched, non-zero = first failing stage.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO/05_ios_port/WeatheriOS"
DERIVED="${DERIVED:-/tmp/dd-weather}"
SIM_NAME="${SIM:-iPhone 16}"
BUNDLE_ID="dev.kiankonrad.weather"

# xcodebuild and simctl live inside Xcode.app; `xcode-select` may still point at
# the Command Line Tools (as it did on this machine), so set DEVELOPER_DIR here
# instead of requiring `sudo xcode-select -s`.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [ "${1:-}" = "--device-list" ]; then
  xcrun simctl list devices available
  exit 0
fi

command -v xcodegen >/dev/null || { echo "FATAL: xcodegen missing (brew install xcodegen)"; exit 2; }
[ -d "$DEVELOPER_DIR" ] || { echo "FATAL: Xcode not found at $DEVELOPER_DIR"; exit 2; }

UDID="$(xcrun simctl list devices available | grep -m1 "$SIM_NAME (" | grep -oE '[0-9A-F-]{36}')"
[ -n "$UDID" ] || { echo "FATAL: no simulator matching '$SIM_NAME'"; exit 2; }

echo "== generating project (XcodeGen)"
( cd "$APP_DIR" && xcodegen generate --spec project.yml >/dev/null )

echo "== building for iOS Simulator (derived data: $DERIVED)"
xcodebuild -project "$APP_DIR/WeatheriOS.xcodeproj" \
           -scheme WeatheriOS \
           -sdk iphonesimulator \
           -destination "id=$UDID" \
           -derivedDataPath "$DERIVED" \
           CODE_SIGNING_ALLOWED=NO \
           build | tail -3

echo "== booting simulator $SIM_NAME ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

echo "== installing + launching"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/WeatheriOS.app"
xcrun simctl launch "$UDID" "$BUNDLE_ID"

echo "OK: built, installed and launched on $SIM_NAME"
