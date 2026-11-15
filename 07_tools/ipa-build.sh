#!/usr/bin/env bash
# Build an UNSIGNED IPA for release.
#
# The app is compiled for a real device (`-sdk iphoneos -configuration Release`) with
# signing disabled — no Apple ID, team, certificate or provisioning profile is involved.
# The result cannot be installed as-is: it must be signed by whoever installs it, e.g.
# SideStore (https://sidestore.io/) or LiveContainer
# (https://github.com/LiveContainer/LiveContainer), both of which sign with the user's
# own free Apple ID on-device.
#
# Usage:  ./07_tools/ipa-build.sh
# Env:    DEVELOPER_DIR (default /Applications/Xcode.app/Contents/Developer)
#         DERIVED       (default /tmp/dd-ipa)
#         OUT           (default 06_build_artifacts/ipa)
set -euo pipefail

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT/05_ios_port/WeatheriOS"
DERIVED="${DERIVED:-/tmp/dd-ipa}"
OUT="${OUT:-$ROOT/06_build_artifacts/ipa}"

command -v xcodegen >/dev/null || { echo "FATAL: xcodegen not installed (brew install xcodegen)"; exit 1; }
[ -d "$DEVELOPER_DIR" ] || { echo "FATAL: DEVELOPER_DIR not found: $DEVELOPER_DIR"; exit 1; }

VERSION="$(sed -n 's/^ *MARKETING_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$PROJ/project.yml" | head -1)"
BUILD="$(sed -n 's/^ *CURRENT_PROJECT_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$PROJ/project.yml" | head -1)"
NAME="Weather-${VERSION}-${BUILD}-unsigned"

echo "== generating project (XcodeGen)"
(cd "$PROJ" && xcodegen generate --spec project.yml >/dev/null)

echo "== building Release for device, signing disabled"
xcodebuild \
  -project "$PROJ/WeatheriOS.xcodeproj" \
  -scheme WeatheriOS \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="$DERIVED/Build/Products/Release-iphoneos/WeatheriOS.app"
[ -d "$APP" ] || { echo "FATAL: no app bundle at $APP"; exit 1; }

echo "== packaging Payload/"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/WeatheriOS.app"
# Strip anything Xcode left behind that must not ship in a release IPA.
rm -rf "$STAGE/Payload/WeatheriOS.app/__preview.dylib" \
       "$STAGE/Payload/WeatheriOS.app/WeatheriOS.debug.dylib" \
       "$STAGE/Payload/WeatheriOS.app/_CodeSignature" \
       "$STAGE/Payload/WeatheriOS.app/embedded.mobileprovision"
mkdir -p "$OUT"
IPA="$OUT/$NAME.ipa"
rm -f "$IPA"
(cd "$STAGE" && zip -qry "$IPA" Payload)

echo "== verifying the IPA is unsigned"
# No `... | grep -q` here: grep exits on first match, the producer takes SIGPIPE, and
# `set -o pipefail` turns that into a spurious failure.
FAIL=0
fail() { echo "  FAIL: $1"; FAIL=1; }

LISTING="$(unzip -l "$IPA")"
unzip -tq "$IPA" >/dev/null || fail "archive is corrupt"
[[ "$LISTING" == *"Payload/WeatheriOS.app/WeatheriOS"* ]] || fail "executable missing from Payload"
[[ "$LISTING" != *"_CodeSignature"* ]] || fail "bundle contains _CodeSignature"
[[ "$LISTING" != *"embedded.mobileprovision"* ]] || fail "bundle contains a provisioning profile"

SIGN_INFO="$(codesign -dv "$STAGE/Payload/WeatheriOS.app" 2>&1 || true)"
[[ "$SIGN_INFO" == *"not signed"* ]] || fail "bundle appears to be signed: $SIGN_INFO"

LOAD_CMDS="$(otool -l "$STAGE/Payload/WeatheriOS.app/WeatheriOS" 2>/dev/null || true)"
[[ "$LOAD_CMDS" != *LC_CODE_SIGNATURE* ]] || fail "executable carries LC_CODE_SIGNATURE"
[[ "$FAIL" -eq 0 ]] && echo "  OK: no signature, no provisioning profile, archive intact"

ARCH="$(lipo -archs "$STAGE/Payload/WeatheriOS.app/WeatheriOS" 2>/dev/null || echo unknown)"
echo "  arch: $ARCH"
[ "$FAIL" -eq 0 ] || { echo "FATAL: unsigned verification failed"; exit 1; }

SHA="$(shasum -a 256 "$IPA" | awk '{print $1}')"
printf '%s  %s\n' "$SHA" "$(basename "$IPA")" > "$IPA.sha256"
SIZE="$(du -h "$IPA" | awk '{print $1}')"

echo
echo "OK: $IPA"
echo "    size   $SIZE"
echo "    sha256 $SHA"
echo
echo "This IPA is unsigned — install it with SideStore (https://sidestore.io/) or"
echo "LiveContainer (https://github.com/LiveContainer/LiveContainer), which sign it"
echo "with your own Apple ID on-device."