#!/bin/bash
# visual-audit.sh — capture a full-resolution screenshot of every app surface.
#
# Runs `WeatheriOSUITests/VisualAuditTests`, which walks empty state → search →
# forecast → scrolled forecast → settings (top/bottom) → cities → map and attaches
# one screenshot per surface, then exports them here with readable names:
#
#   ./07_tools/visual-audit.sh            # → 07_logs/shots/audit/
#   OUT=~/shots ./07_tools/visual-audit.sh
#
# These are review artifacts (git-ignored), not assertions. Pair them with the
# Compose source in 00_original/source/Weather when judging parity.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO/05_ios_port/WeatheriOS"
OUT="${OUT:-$REPO/07_logs/shots/audit}"
SIM_NAME="${SIM:-iPhone 16}"
DERIVED="${DERIVED:-/tmp/dd-weather}"
BUNDLE="$(mktemp -d -t audit)"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

UDID="$(xcrun simctl list devices available | grep -m1 "$SIM_NAME (" | grep -oE '[0-9A-F-]{36}')"
[ -z "$UDID" ] && { echo "FATAL: no simulator matching '$SIM_NAME'"; exit 1; }
xcrun simctl boot "$UDID" 2>/dev/null || true

( cd "$APP_DIR" && xcodegen generate --spec project.yml >/dev/null )

xcodebuild test \
  -project "$APP_DIR/WeatheriOS.xcodeproj" \
  -scheme WeatheriOS \
  -sdk iphonesimulator \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$BUNDLE/audit.xcresult" \
  -only-testing:WeatheriOSUITests/VisualAuditTests \
  CODE_SIGNING_ALLOWED=NO TEST_RUNNER_RUN_VISUAL_AUDIT=1 >"$BUNDLE/build.log" 2>&1
status=$?
if [ $status -ne 0 ]; then
  echo "AUDIT RUN FAILED — tail of log:"
  grep -E "error:|Test Case '.*failed" "$BUNDLE/build.log" | tail -8
  exit 1
fi

rm -rf "$OUT" && mkdir -p "$OUT"
xcrun xcresulttool export attachments --path "$BUNDLE/audit.xcresult" --output-path "$BUNDLE/raw" >/dev/null 2>&1
python3 - "$BUNDLE/raw" "$OUT" <<'PY'
import json, os, shutil, sys
raw, out = sys.argv[1], sys.argv[2]
m = json.load(open(os.path.join(raw, 'manifest.json')))
for test in m:
    for a in test.get('attachments', []):
        f, name = a.get('exportedFileName'), a.get('suggestedHumanReadableName') or ''
        src = os.path.join(raw, f or '')
        if not name or not os.path.exists(src):
            continue
        shutil.move(src, os.path.join(out, name.split('_0_')[0] + '.png'))
PY
rm -rf "$BUNDLE"
ls "$OUT"
echo "OK: audit screenshots in $OUT"
