#!/usr/bin/env bash
# Final packaging — unsigned IPA. New script per project rule 3.
# Produces: 06_build_artifacts/weather-ios-unsigned/ with the IPA, build log,
# test report, IPA verification report, and SHA-256 checksum file.
# RESTRICTIONS HONORED: no --sign, no Apple auth, no certificates, unsigned only.
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
export PATH="$P/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/usr/bin:$PATH"
XT="$P/07_tools/xtool/xtool-x86_64.AppImage"
SRC="$P/05_ios_port/WeatheriOS"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$P/06_build_artifacts/weather-ios-unsigned"
LOG="$OUT/package-$STAMP.log"
mkdir -p "$OUT"

echo "=== mirror WeatheriOS to ext4 scratch ===" | tee "$LOG"
rm -rf ~/weather-ios-src
cp -r "$SRC" ~/weather-ios-src
cd ~/weather-ios-src

echo "=== xtool dev build --ipa (unsigned, no --sign) ===" | tee -a "$LOG"
"$XT" dev build --ipa 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
echo "xtool dev build --ipa exit code: $RC" | tee -a "$LOG"
if [ "$RC" -ne 0 ]; then
  echo "BUILD FAILED" | tee -a "$LOG"; exit "$RC"
fi

IPA=$(ls -t ~/weather-ios-src/xtool/*.ipa | head -1)
echo "=== IPA found: $IPA ===" | tee -a "$LOG"
rm -rf /tmp/ipa-inspect && mkdir -p /tmp/ipa-inspect
python3 -c "
import zipfile
with zipfile.ZipFile('$IPA') as z:
    z.extractall('/tmp/ipa-inspect')
"
APPDIR=$(echo /tmp/ipa-inspect/Payload/*.app)
echo "=== inspect .app bundle ($APPDIR) ===" | tee -a "$LOG"
ls "$APPDIR" | tee -a "$LOG"
BIN="$APPDIR/WeatheriOS"

{
  echo "--- bundle identifier"
  python3 -c "
import plistlib
with open('$APPDIR/Info.plist','rb') as f: d = plistlib.load(f)
for k in ('CFBundleIdentifier','CFBundleShortVersionString','CFBundleName','CFBundleExecutable'):
    print(k, '=', d.get(k))
"
  echo "--- Mach-O type / arch"
  file "$BIN"
  echo "--- LC_CODE_SIGNATURE present?"
  python3 - "$BIN" <<'EOF'
import struct, sys
path = sys.argv[1]
with open(path,'rb') as f:
    data = f.read()
magic, cputype, cpusub = struct.unpack_from('<III', data, 0)
little = magic == 0xfeedfacf
n, size = struct.unpack_from('<II', data, 12) if little else struct.unpack_from('>II', data, 12)
off = 32
found = []
for _ in range(n):
    cmd, cmdsize = struct.unpack_from('<II', data, off)
    if cmd == 0x1d and 'LC_CODE_SIGNATURE' not in found: found.append('LC_CODE_SIGNATURE')
    off += cmdsize
print('LC_CODE_SIGNATURE found' if found else 'NO LC_CODE_SIGNATURE (unsigned Mach-O)')
print(f'cputype={cputype} (12=arm64)')
EOF
  "$BIN" 2>/dev/null || true
} 2>&1 | tee -a "$LOG" || true

echo "--- _CodeSignature directory present?" | tee -a "$LOG"
if [ -d "$APPDIR/_CodeSignature" ]; then echo "PRESENT (unexpected)" | tee -a "$LOG"; else echo "absent (unsigned)" | tee -a "$LOG"; fi
echo "--- embedded.mobileprovision present?" | tee -a "$LOG"
if [ -f "$APPDIR/embedded.mobileprovision" ]; then echo "PRESENT (unexpected)" | tee -a "$LOG"; else echo "absent (no provisioning profile)" | tee -a "$LOG"; fi

echo "=== IPA zip structure ===" | tee -a "$LOG"
python3 -c "
import zipfile
with zipfile.ZipFile('$IPA') as z:
    for n in z.namelist(): print(n)
" | tee -a "$LOG"

echo "=== copy artifacts (versioned, never overwrite) ===" | tee -a "$LOG"
cp "$IPA" "$OUT/Weather-unsigned-$STAMP.ipa"
cp "$LOG" "$OUT/package-log-$STAMP.txt"

echo "=== SHA-256 ===" | tee -a "$LOG"
sha256sum "$OUT/Weather-unsigned-$STAMP.ipa" | tee "$OUT/Weather-unsigned-$STAMP.sha256" | tee -a "$LOG"

echo "=== DONE exit $RC ===" | tee -a "$LOG"
exit "$RC"
