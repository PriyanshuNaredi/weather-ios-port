# REPRODUCE.md — How to reproduce this project's Phase 1 results

## macOS / Xcode (current path — what actually builds today)

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer   # xcode-select points at CLT
cd 05_ios_port/WeatheriOS && xcodegen generate --spec project.yml  # regenerate after adding files
cd - && ./07_tools/macos-build.sh                                  # build, install, launch (sim)
./07_tools/macos-tests.sh all                                      # 87 logic + 11 UI tests
./07_tools/visual-audit.sh                                         # 10 screenshots -> 07_logs/shots/audit/
swift 07_tools/make-app-icon.swift                                 # regenerate the 1024 app icon
./07_tools/ipa-build.sh                                            # unsigned release IPA (device build)
```

- Regenerating the project matters: a new source or test file is invisible to the build (and
  silently runs zero tests) until `xcodegen generate` runs.
- The simulator destination is pinned by UDID, not `booted`, because a second booted simulator
  (e.g. Orpheon-Test) makes `booted` ambiguous.
- `07_tools/visual-audit.sh` fails loudly if fewer than 10 screenshots export.
- The icon needs no Xcode: `make-app-icon.swift` parses the APK's vector and rasterises it.
- `ipa-build.sh` produces an **unsigned** IPA and verifies that it stayed unsigned; installing it
  needs SideStore (<https://sidestore.io/>) or LiveContainer
  (<https://github.com/LiveContainer/LiveContainer>), which sign it with the user's own Apple ID.

---

## Historical — Windows/WSL pipeline (kept for provenance)

## 1. Build the debug APK (WSL pipeline, all tools portable inside this project)

Requirements: Windows with WSL2 Ubuntu; nothing installed system-wide.

```bash
# script: 07_tools/wsl-build.sh (v2)
#  - JAVA_HOME      = 07_tools/jdk-linux        (Temurin JDK 21 Linux x64)
#  - ANDROID_HOME   = 07_tools/android-sdk-linux (platforms;android-37.0, build-tools;37.0.0)
#  - GRADLE_USER_HOME = ~/.gradle-weather (WSL ext4; /mnt/c drvfs breaks Gradle daemon registry writes)
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/wsl-build.sh" \
  :app:assembleDebug :app:testDebugUnitTest :app:lintDebug --console=plain --max-workers=3
```

Observed: BUILD SUCCESSFUL in 7m 11s; 28 unit tests, 0 failures; lint 0 errors / 21 warnings (OldTargetApi etc.).

APK lands in `/home/<user>/.cache/weather/build/app/outputs/apk/debug/app-debug.apk` (the repo's build.gradle.kts redirects build output to `$user.home/.cache/weather/build`) — copy it to `06_build_artifacts/apk/`.

Why WSL: the project path contains `→` (U+2192). Windows-side gradlew.bat/sdkmanager.bat corrupt the classpath through this character; WSL handles it, with `MSYS_NO_PATHCONV=1` needed to stop Git Bash converting `/mnt/c/...` args.

Runtime behavior: **PENDING, NOT VERIFIED** — no emulator/system image/device was available in Phase 1; nothing in this file constitutes a runtime-verified claim.

## 2. Verify the official APK

```bash
curl -sL -o 00_original/apk/official/Weather_v1.1.1.apk \
  https://github.com/Kian-hdr/Weather/releases/download/v1.1.1/Weather_v1.1.1.apk
sha256sum 00_original/apk/official/Weather_v1.1.1.apk
# expect 49a502b2b2747c6cd6bf10e2d8ace1dad832d1e645e31b935e014ef8417199c1 (matches release SHA256SUMS.txt)
java -jar 07_tools/android-sdk/build-tools/37.0.0/lib/apksigner.jar verify --print-certs 00_original/apk/official/Weather_v1.1.1.apk
# expect cert SHA-256 d3370a7978ab64640b64af5be1ceca607eebc683cb0c3d47dd02dd0e7e23f5c3 (matches README)
```

## 3. Reverse-engineer

```bash
java -jar 07_tools/apktool/apktool.jar d -f -o 02_apk_analysis/apktool 00_original/apk/official/Weather_v1.1.1.apk
java -classpath "07_tools/jadx/lib/*" jadx.cli.JadxCLI -d 02_apk_analysis/jadx --no-res -j 4 00_original/apk/official/Weather_v1.1.1.apk
# (jadx.bat fails on the Unicode path; invoke jadx.cli.JadxCLI directly)
07_tools/android-sdk/build-tools/37.0.0/aapt2.exe dump badging <apk>
```

## Modifications made (rule 7)
- `07_tools/wsl-build.sh` (project-local build driver, v2) — sets portable JDK/SDK/Gradle home; Gradle caches on WSL ext4.
- No repo source files were modified. No files outside the project root were created (Gradle home + repo build output live in the WSL user's home, a documented deviation necessary for Gradle to function).

## 3. Reproduce the unsigned iOS IPA (Phase 2, no signing / no Apple services)
```bash
# script: 07_tools/ipa-build.sh (build) + ipa-verify.sh (verify)
# Requirements: Swift 6.4.2 + xtool 1.24.0 (07_tools), Darwin SDK 27.2 (~/.swiftpm/swift-sdks), WSL Ubuntu.
# Build runs from ext4 scratch ~/hello-src because /mnt/c drvfs cannot hold executable Mach-O files.
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/ipa-build.sh"
#   → xtool dev build --ipa  (NOTE: --sign omitted → unsigned, no Apple Developer Services calls)
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/ipa-verify.sh"
#   → ZIP structure Payload/HelloWorld.app, Info.plist fields, Mach-O arm64 check,
#     LC_CODE_SIGNATURE count (0), _CodeSignature/mobileprovision absence, SHA-256,
#     copies IPA to 06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa
```
Observed (2026-11-13): `Build complete! (16.07 secs)`; `Wrote to /home/naredi/hello-src/xtool/HelloWorld.ipa` (96 KB); IPA SHA-256 `98b123e85425624e3796cdf09d151552973669f0910dc0afe2f76b573191aa51`. The IPA is UNSIGNED — it will not launch on a device until signed (G5).
## 4. Reproduce the WeatheriOS foundation build (Phase 2, unsigned)
```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/port-build1.sh"   # mirror to ~/weather-ios-src + xtool dev build
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/port-verify1.sh"  # verify + copy artifacts back
```
Observed 2026-11-13: `xtool dev build` exit 0; WeatheriOS.app/WeatheriOS Mach-O 64-bit arm64; LC_CODE_SIGNATURE count 0; no _CodeSignature/, no embedded.mobileprovision; CFBundleIdentifier dev.kiankonrad.weather; MinimumOSVersion 17.0; SHA-256 4f80335c5e6c9e7258c1e5febdf5392de7d4a06dc1d29f2661d460d65359dd7c. No Apple services touched. Packaging only — not installed on any device.

## 5. Reproduce the complete Weather port build + tests (Phase 2, unsigned)
```bash
# Full iOS port (all workstreams A–F): mirror 05_ios_port/WeatheriOS to ext4
# scratch ~/weather-ios-src, unsigned xtool dev build, arm64-apple-ios.
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/port-build2.sh"
#   → xtool dev build exit 0; WeatheriOS.app/WeatheriOS Mach-O 64-bit arm64,
#     unsigned (LC_CODE_SIGNATURE count 0).

# Linux logic tests (Swift Testing, x86_64 Linux build of the app logic):
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/logic-tests.sh"
#   → 41 tests executed, 0 failures.
#   NOTE: these exercise pure logic (DataCodec parsers, mappings, formatting,
#   projection, cache logic) compiled for Linux; UI-layer code compiles for the
#   iOS target but is NOT runtime-verified (no device/emulator, restricted).
```
Observed 2026-11-13 (final): build exit 0 (23.9 s); tests 41/41 pass.

## 6. Reproduce the final unsigned Weather IPA
```bash
# 1) Build + package (no --sign):
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/package-ipa.sh"
# 2) Set bundle version to the original app's 1.1.1 and re-verify:
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/finalize-ipa.sh"
# 3) Kotlin→Swift string parity scan (report-only):
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "<project>/07_tools/parity-check.sh"
```
Observed 2026-11-13: `Payload/WeatheriOS.app` with CFBundleIdentifier
`dev.kiankonrad.weather`, CFBundleShortVersionString 1.1.1; Mach-O arm64
(cputype 16777228); NO LC_CODE_SIGNATURE, no _CodeSignature/, no
embedded.mobileprovision; bundle ID/version verified inside the final IPA zip.
Final IPA: `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-115901.ipa`
SHA-256 `6a032f8aa5cd005a1f57fbd699ec2e41a77122645a59a867363d8f70a5a1231e`
(see `IPA-VERIFICATION-20261113.md`). The IPA is UNSIGNED — it will not launch
on a device until signed; signing/installation was out of scope and not performed.

## 7. Reproduce the stability-fix IPA (2026-11-13)
Same commands as §5–§6. Baseline state recorded before edits in
`06_build_artifacts/fix-baseline-20261113-124944/BASELINE-MANIFEST.md`
(SHA-256 of every Swift source + Android spot checks).
Observed: `logic-tests.sh` → 41 existing + 9 new StabilityTests = 50/50 pass
(`logs/logic-tests-20261113-125439.log`); `package-ipa.sh` exit 0;
`finalize-ipa.sh` →
`06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-130504.ipa`
CFBundleShortVersionString 1.1.1, Mach-O arm64 (cputype 16777228), NO
LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision.
SHA-256 `beb82eb893d7a2fc69381339187bc1630b12bf4ff13722245cb556679af59856`.
Prior baseline IPA (115901, `6a032f8a…`) preserved; nothing overwritten.

## 8. Reproduce the runtime-debugging diagnostic IPA (2026-11-13)
Device re-test showed the 130504 build did NOT resolve the issues; per instruction no
further speculative fixes were made — this build ships instrumentation + diagnostic
configurations A–E instead (details: `06_build_artifacts/weather-ios-unsigned/FINAL-TEST-REPORT.md`).
Same commands as §5–§6 (`logic-tests.sh` → `package-ipa.sh` → `finalize-ipa.sh`).
Observed: `logic-tests.sh` → 41 XCTest + 15 Swift Testing (incl. 6 new DiagLogTests)
= **56/56 pass** (`logs/logic-tests-20261113-132124.log`); `package-ipa.sh` exit 0
(after fixing the Scene-level `scenePhase` onChange closure arity in WeatherApp.swift);
`finalize-ipa.sh` →
`06_build_artifacts/weather-ios-unsigned/Weather-unsigned-FINAL-20261113-133010.ipa`
CFBundleShortVersionString 1.1.1, bundle `dev.kiankonrad.weather`, arm64 (cputype
16777228), NO LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision.
SHA-256 `3b399e915b093acf6975fb77af00bc68cd96753dfce0f88ba17620150382782d`.
Baseline (115901) and stability (130504) IPAs preserved untouched (see SHA256SUMS.txt).

## 9. Reproduce the crash/navigation/scroll FIXED IPA (2026-11-13)
Mission required static investigation first ("do not claim a root cause without
evidence"), then fixes, tests, and a new unsigned IPA. Same commands as §5–§6:
1. `logic-tests.sh` → **67/67 pass** (52 XCTest + 15 Swift Testing; includes 10 new
   StabilityFixTests: pager clamping, range-band geometry, cancellation-loop exit,
   DiagLog session clean/abnormal protocol) (`logs/logic-tests-20261113-135126.log`).
2. `package-ipa.sh` → exit 0. Two build-cycle fixes were needed first:
   RangeSpan.band optional `guard`-unwrapped in ForecastPageView's RangeBar Canvas,
   and NavTestView `if let route` shorthand restructured (Linux swift-frontend 6.4.2
   type-checker assertion crash, not a source error).
3. `finalize-ipa.sh` → verification output: CFBundleIdentifier `dev.kiankonrad.weather`,
   CFBundleShortVersionString 1.1.1, Mach-O magic ok, cputype 16777228 (arm64),
   NO LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision.
4. Copy (never overwrite) to the mission filename:
   `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-FIXED-20261113-140433.ipa`,
   SHA-256 `25e404a21764279ea8e9292631a30fcfb72a17d164a1ffa524a8ef176693d3c1`.
Reports: `06_build_artifacts/fix-mission-20261113-140433/` (CRASH-ANALYSIS.md,
NAVIGATION-TEST-REPORT.md, SCROLL-TEST-REPORT.md, FINAL-IPA-VERIFICATION.md,
SHA256SUMS.txt). All four prior IPAs re-verified byte-identical.

## 10. Reproduce the parity IPA (2026-11-13)
Mission: implement the 8 architectural parity corrections in
`07_tools/rea-analysis/ANDROID_IOS_PARITY.md` (city-id pager identity, pager as
single source of truth, safeAreaInset bottom bar, reachable screens, one vertical
ScrollView per page, horizontal hourly strip, 48 MiB disk tile cache, radar/
temperature preserved).
1. Baseline preserved first: `06_build_artifacts/parity-baseline-20261113/`
   (SHA-256 of 10 IPAs + 39 Swift sources; nothing overwritten).
2. `logic-tests.sh` → **80/80 pass** (52 XCTest + 28 Swift Testing; 13 new parity
   tests: pager id↔index identity ×5, disk-cache eviction policy ×6, screen
   reachability ×2) (`logs/logic-tests-20261113-144943.log`).
3. `package-ipa.sh` → exit 0 after four build-cycle fixes in the new
   `DiskTileCache` actor (nonisolated-init index load; Linux swift-frontend 6.4.2
   `sorted{}`/SortComparator inference failures → explicit types + `.sorted(by:)`;
   actor-isolated property in `try?` autoclosures → `FileManager.default`;
   `inFlight` dict type aligned to `Task<Data, Error>`).
4. `finalize-ipa.sh` → CFBundleIdentifier `dev.kiankonrad.weather`, v1.1.1,
   Mach-O arm64 (cputype 16777228), NO LC_CODE_SIGNATURE, no _CodeSignature/,
   no embedded.mobileprovision.
Final IPA: `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-150013.ipa`
SHA-256 `9a8425fdc53a9a381cd58bc87ebc0b5f6ece6036efd3ea5b7c33334db386d258`.
The IPA is UNSIGNED — it will not launch on a device until signed; signing was
out of scope. Static analysis only: no runtime/device verification is claimed.
Physical-device items still open: pager gestures with city-id identity, bottom-bar
hit areas under safeAreaInset, disk-cache persistence/eviction across relaunch and
memory pressure, radar/temperature rendering, diagnostics exports A–E.
