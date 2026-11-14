#!/bin/bash
# macos-tests.sh — run both test layers on macOS/Xcode.
#
#   layer 1: host logic suite (87 tests: 59 XCTest + 28 Swift Testing) — no simulator
#   layer 2: simulator UI suite (7 XCUITest cases) — real SwiftUI, live Open-Meteo,
#            map gestures, settings, bundled legal texts
#
# Usage:
#   ./07_tools/macos-tests.sh              # both layers
#   ./07_tools/macos-tests.sh logic        # host logic only
#   ./07_tools/macos-tests.sh ui           # simulator UI only
#   SIM="iPhone 16 Pro" ./07_tools/macos-tests.sh
#
# Exit codes: 0 = all requested layers passed.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO/05_ios_port/WeatheriOS"
PKG="$REPO/05_ios_port/WeatherLogicTests"
DERIVED="${DERIVED:-/tmp/dd-weather}"
SIM_NAME="${SIM:-iPhone 16}"
WORK="${WORK:-$HOME/weather-logic-tests}"
MODE="${1:-all}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
FAILED=0

run_logic() {
  echo "== host logic tests (macOS Swift $(xcrun swift --version | head -1 | awk '{print $4}'))"
  local SRC="$APP_DIR/Sources/WeatheriOS"
  rm -rf "$WORK"
  mkdir -p "$WORK/Sources/WeatherLogic" "$WORK/Tests/WeatherLogicTests" "$WORK/Fixtures"
  cp "$PKG/Package.swift" "$WORK/"
  # Same source set the Linux script copies (single source of truth stays in the app).
  cp "$SRC/Models/Models.swift" "$SRC/Models/Units.swift" "$SRC/Models/WeatherCodes.swift" \
     "$SRC/Models/TileCachePolicy.swift" "$SRC/Models/StabilityPolicies.swift" \
     "$SRC/Repositories/DataCodec.swift" "$SRC/Repositories/ForecastProjection.swift" \
     "$SRC/Repositories/OpenWeatherRepository.swift" "$SRC/Services/OpenMeteoClient.swift" \
     "$SRC/Services/DiagLog.swift" "$WORK/Sources/WeatherLogic/"
  cp "$PKG"/Tests/WeatherLogicTests/*.swift "$WORK/Tests/WeatherLogicTests/"
  [ -d "$PKG/Fixtures" ] && cp -r "$PKG/Fixtures/." "$WORK/Fixtures/" 2>/dev/null
  ( cd "$WORK" && swift test 2>&1 | grep -E "Executed [0-9]+ test|Test run with|error:" | tail -4 )
  ( cd "$WORK" && swift test >/dev/null 2>&1 ) || { echo "LOGIC TESTS FAILED"; FAILED=1; }
  return 0
}

run_ui() {
  local UDID
  UDID="$(xcrun simctl list devices available | grep -m1 "$SIM_NAME (" | grep -oE '[0-9A-F-]{36}')"
  if [ -z "$UDID" ]; then echo "FATAL: no simulator matching '$SIM_NAME'"; FAILED=1; return 0; fi
  echo "== simulator UI tests on $SIM_NAME ($UDID)"
  xcrun simctl boot "$UDID" 2>/dev/null || true
  local log
  log="$(mktemp -t weather-ui-tests)"
  if xcodebuild test \
    -project "$APP_DIR/WeatheriOS.xcodeproj" \
    -scheme WeatheriOS \
    -sdk iphonesimulator \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO >"$log" 2>&1; then
    grep -E "Test Case '.*(passed|failed)|Executed [0-9]+ test" "$log" | tail -14
  else
    grep -E "Test Case '.*(passed|failed)|error:|Executed [0-9]+ test" "$log" | tail -20
    echo "UI TESTS FAILED (full log: $log)"
    FAILED=1
  fi
  return 0
}

case "$MODE" in
  logic) run_logic ;;
  ui)
    ( cd "$APP_DIR" && xcodegen generate --spec project.yml >/dev/null )
    run_ui
    ;;
  all)
    ( cd "$APP_DIR" && xcodegen generate --spec project.yml >/dev/null )
    run_logic
    run_ui
    ;;
  *) echo "usage: $0 [all|logic|ui]"; exit 2 ;;
esac

if [ "$FAILED" -ne 0 ]; then echo "RESULT: FAILED"; exit 1; fi
echo "RESULT: PASSED (see per-layer output above)"
