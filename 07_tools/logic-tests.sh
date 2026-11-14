#!/bin/bash
# logic-tests.sh — run the Linux-host pure-logic test package.
# Copies the shared Foundation-only sources from WeatheriOS into the test
# package's Sources/WeatherLogic (copies, never moves) and runs `swift test`
# on the ext4 scratch mirror. Usage:
#   MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "07_tools/logic-tests.sh"
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
export PATH="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin:$PATH"
SWIFT="$(command -v swift)" || { echo "FATAL: swift not found"; exit 1; }
echo "swift: $(swift --version 2>&1 | head -1)"

SRC="$P/05_ios_port/WeatheriOS/Sources/WeatheriOS"
PKG="$P/05_ios_port/WeatherLogicTests"
WORK="$HOME/weather-logic-tests"

rm -rf "$WORK"
mkdir -p "$WORK/Sources/WeatherLogic" "$WORK/Tests/WeatherLogicTests" "$WORK/Fixtures"
cp -r "$PKG/Package.swift" "$WORK/"
cp "$SRC/Models/Models.swift" \
   "$SRC/Models/Units.swift" \
   "$SRC/Models/WeatherCodes.swift" \
   "$SRC/Models/TileCachePolicy.swift" \
   "$SRC/Models/StabilityPolicies.swift" \
   "$SRC/Repositories/DataCodec.swift" \
   "$SRC/Repositories/ForecastProjection.swift" \
   "$SRC/Repositories/OpenWeatherRepository.swift" \
   "$SRC/Services/OpenMeteoClient.swift" \
   "$SRC/Services/DiagLog.swift" \
   "$WORK/Sources/WeatherLogic/"
cp "$PKG/Tests/WeatherLogicTests/"*.swift "$WORK/Tests/WeatherLogicTests/"
cp "$PKG/Fixtures/"*.json "$WORK/Fixtures/"

cd "$WORK" || exit 1
echo "--- swift test (Linux host, Foundation-only logic; NOT iOS runtime tests) ---"
swift test 2>&1 | tee "$P/06_build_artifacts/logs/logic-tests-$(date +%Y%m%d-%H%M%S).log"
STATUS=${PIPESTATUS[0]}
echo "exit=$STATUS"
exit "$STATUS"
