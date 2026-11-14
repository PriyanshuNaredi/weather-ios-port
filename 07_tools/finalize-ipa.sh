#!/usr/bin/env bash
# Final packaging step 2 — set the app version to the original app's version
# (1.1.1; xtool generates 1.0.0 by default and 1.24.0 has no plist override),
# rebuild the IPA, and re-verify the unsigned state. Creates NEW versioned
# artifacts (project rule 3/4 — nothing overwritten).
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$P/06_build_artifacts/weather-ios-unsigned"
LOG="$OUT/finalize-$STAMP.log"
mkdir -p "$OUT"

IPA=$(ls -t ~/weather-ios-src/xtool/WeatheriOS.ipa | head -1)
WORK=/tmp/ipa-final-$STAMP
rm -rf "$WORK" && mkdir -p "$WORK"

echo "=== extract $IPA ===" | tee "$LOG"
python3 -c "
import zipfile
with zipfile.ZipFile('$IPA') as z:
    z.extractall('$WORK')
"
APP="$WORK/Payload/WeatheriOS.app"

echo "=== set CFBundleShortVersionString = 1.1.1 ===" | tee -a "$LOG"
python3 -c "
import plistlib
p = '$APP/Info.plist'
with open(p,'rb') as f: d = plistlib.load(f)
d['CFBundleShortVersionString'] = '1.1.1'
d['CFBundleVersion'] = '1'
with open(p,'wb') as f: plistlib.dump(d, f)
print('version now:', d['CFBundleShortVersionString'])
" 2>&1 | tee -a "$LOG"

echo "=== rezip (store app payload, deflate ok) ===" | tee -a "$LOG"
FINAL="$OUT/Weather-unsigned-$STAMP.ipa"
python3 -c "
import zipfile, os
os.chdir('$WORK')
with zipfile.ZipFile('$FINAL', 'w') as z:
    for root, dirs, files in os.walk('Payload'):
        for name in sorted(files):
            path = os.path.join(root, name)
            z.write(path, path)
print('wrote', '$FINAL')
" 2>&1 | tee -a "$LOG"

echo "=== verification of final IPA ===" | tee -a "$LOG"
python3 -c "
import zipfile, plistlib, struct
with zipfile.ZipFile('$FINAL') as z:
    names = z.namelist()
    for n in names: print('zip:', n)
    info = plistlib.load(z.open('Payload/WeatheriOS.app/Info.plist'))
    print('CFBundleIdentifier =', info['CFBundleIdentifier'])
    print('CFBundleShortVersionString =', info['CFBundleShortVersionString'])
    macho = z.read('Payload/WeatheriOS.app/WeatheriOS')
magic, = struct.unpack_from('<I', macho, 0)
cputype, = struct.unpack_from('<i', macho, 4)
n, = struct.unpack_from('<i', macho, 12)
off = 32; sig = False
for _ in range(n):
    cmd, cmdsize = struct.unpack_from('<ii', macho, off)
    if cmd == 0x1d: sig = True
    off += cmdsize
print('Mach-O magic ok:', magic == 0xfeedfacf, '| cputype =', cputype, '(16777228 = arm64)')
print('LC_CODE_SIGNATURE present:', sig)
print('_CodeSignature in zip:', any('_CodeSignature' in n for n in names))
print('embedded.mobileprovision in zip:', any('mobileprovision' in n for n in names))
" 2>&1 | tee -a "$LOG"

echo "=== SHA-256 ===" | tee -a "$LOG"
sha256sum "$FINAL" | tee "$OUT/Weather-unsigned-$STAMP.sha256" | tee -a "$LOG"
echo "=== DONE ===" | tee -a "$LOG"
