# PROJECT_STATUS.md

## macOS/Xcode build status — VERIFIED 2026-11-14

| Item | Status |
|---|---|
| Xcode project | Generated from `05_ios_port/WeatheriOS/project.yml` (XcodeGen) |
| Simulator build (iOS 18 SDK, Xcode 16.0) | PASS — `07_tools/macos-build.sh` |
| Cold start / search / forecast render | PASS — live Open-Meteo geocoding + forecast |
| Map (basemap, radar, pan/pinch responsiveness) | PASS |
| Settings, units switch, bundled legal texts | PASS |
| Visual audit walk (10 screens) | PASS — `07_tools/visual-audit.sh` → `07_logs/shots/audit/` |
| App icon (`Assets.car` in bundle, home screen) | PASS — rendered from the APK's own vector |
| Host logic suite | PASS 87/87 on the macOS toolchain (59 XCTest + 28 swift-testing) |
| Simulator UI suite | PASS 11/11 (`WeatheriOSUITests`, visual-audit class excluded) |
| Idle CPU on the forecast screen | 5.7% (was 100% — invalidation loop, fixed) |
| Physical device / signing | NOT DONE — no Apple ID/team in this environment |

Defects found and fixed during this build are listed in
`05_ios_port/MACOS_VERIFICATION.md` (basemap 200-with-watermark, inert units switch,
`ForecastPageModel.init` invalidation loop, O(n²) hourly dedup, `DateFormatter` churn,
metric-grid layout feedback, Swift 6 strict-concurrency build failures, missing
SwiftPM platform/toolchain settings, `GlassPanel` painting children as separate cards,
radar opening on the newest frame, temperature badges clipped by edges and panels, empty
`ASSETCATALOG_COMPILER_APPICON_NAME`).

Repo-wide audit findings: `CODE_AUDIT.md`. Credit and upstream licences: `CREDITS.md`.
iOS port by Priyanshu Naredi; original Android app by Kian Konrad (MIT).

Port: Android APK → native iOS (SwiftUI) IPA — unsigned development build.
Attribution and upstream projects: `CREDITS.md`.

Project: Android Weather APK Reverse Engineering → Native iOS Port
Root: `C:\Users\naredi\Downloads\Android Weather APK Reverse Engineering → Native iOS Port`
Last updated: 2026-11-14

## Phase status

| Step | Description | Status |
|---|---|---|
| 1 | Environment inspection | DONE (see 04_documentation/findings/01_environment.md) |
| 2 | Repo inspection + clone | PARTIAL — remote inspection DONE, clone pending |
| 3 | Build debug APK | BLOCKED — no Android SDK on machine |
| 4 | Official APK acquisition | PENDING |
| 5 | APK reverse engineering | PENDING |
| 6 | Runtime baseline | PENDING |
| 7 | PORT_GRAPH.md | PENDING (created once analysis starts) |
| 8 | iOS feasibility assessment | PENDING |

## Environment — VERIFIED (2026-11-12)

### Windows host
- Windows 11 (10.0.26300) x64, host DESKTOP-KPP3FUA
- RAM 23.4 GB; CPU AMD Ryzen 5 4600H (6C/12T); C: free 266.2 GB
- Shell: Git Bash (MSYS2 MINGW64), user `naredi`
- Git 2.56.0.windows.4; Python 3.13.14
- Java: **JDK 25.0.1 LTS** on PATH
- Gradle: not installed (repo ships wrapper — OK)
- adb / Android SDK: **NOT PRESENT** (ANDROID_HOME, ANDROID_SDK_ROOT empty; no SDK dirs found)
- RE tools on Windows PATH: jadx, apktool, aapt2, apkanalyzer, apksigner, zipalign, keytool all **MISSING**; unzip present

### WSL Ubuntu
- Ubuntu 26.04.1 LTS (Resolute Raccoon), amd64, WSL2 (Running)
- RAM (WSL) 11 GB; disk 1007 GB total, 943 GB free
- Inside Ubuntu: java, gradle, adb all missing; ANDROID_HOME empty; git 2.53.0; Python 3.14.4

### Repository (remote inspection via GitHub API — pre-clone)
- URL: https://github.com/Kian-hdr/Weather
- Public, not a fork, language Kotlin, size ~3.4 MB, last push 2026-11-12
- Default branch: `main` @ `6267da88fc33d9b8e21ec5d77851f7a33bdf97ea`
- Branches: main, ind-168-public-creator-credit, ind-279-bundled-license, ind-279-license-credit
- Tag: `v1.1.1` @ `dfaa1aff5770dc03fe1e5bde162f8e3f4d7e0c2a`
- License: MIT (GitHub license API + LICENSE file present)
- Single module: `:app`; package `dev.kiankonrad.weather`

### Build configuration (fetched from raw.githubusercontent.com, pre-clone)
| Item | Value |
|---|---|
| Gradle wrapper | 9.3.1-bin |
| AGP | 9.1.1 |
| Kotlin | 2.2.20 (+ compose plugin) |
| compileSdk / targetSdk / minSdk | 37 / 36 / 28 |
| versionName / versionCode | 1.1.1 / 6 |
| Java/JVM target | 17 |
| Compose BOM | 2026.09.00 (Material3, icons-extended) |
| Networking | OkHttp 4.12.0 |
| Maps | MapLibre GL android-sdk 13.6.1 |
| Tests | JUnit 4.13.2, org.json 20250517; instrumented: androidx.test runner 1.7.0 |
| Debug build | applicationIdSuffix `.qa` |
| Release signing | external: `%USERPROFILE%/.config/weather/signing.properties` (not in repo) |
| lint | abortOnError = true |
| build.sh | sets macOS JAVA_HOME/ANDROID_HOME fallbacks, then `./gradlew <tasks> --project-cache-dir $HOME/.cache/weather/gradle-project --console=plain --max-workers=3`; build dirs redirected to `$HOME/.cache/weather/build/...` |

### JDK 25 compatibility assessment
- Gradle 9.3.1 supports running on JDK 25 → wrapper should run.
- AGP 9.1.1 requires JDK 17+ → OK.
- Kotlin/JVM target is 17 while the launcher JVM is 25 — toolchains may need care; will confirm at build time.
- No Gradle file modification will be made to "fix" JDK issues; actual errors will be reported.

## BLOCKERS requiring user approval
1. **No Android SDK anywhere on the machine.** Building (Step 3) is impossible without installing one (sdkmanager + cmdline-tools, platform 37, build-tools). Install requires approval per Rule 6.
2. **Build output location conflict.** `scripts/build.sh` and both `build.gradle.kts` files redirect build/cache output to `%USERPROFILE%/.cache/weather/` and the Gradle wrapper downloads the Gradle distribution + dependency caches to `%USERPROFILE%/.gradle/` — outside the project root (Rule 1 vs Rule 5). Options: (a) allow those default locations, (b) run with `-g <project>/.gradle-home` and overridden project-cache-dir to keep everything inside the project. Preference: (b).
3. RE tools (jadx/apktool/aapt2/apkanalyzer/apksigner) are not installed anywhere. Acquisition needs approval (prefer portable copies inside `07_tools/` or WSL apt with user sign-off).

## Files created so far
- Directory tree `00_original…07_logs` (this file's sibling directories)

## Rules in force
Phases 1 only; nothing outside project root; no deletes; no overwriting original APK; no installs without approval; no API keys/credentials/location in logs; STOP after Phase 1.

---

# Phase 2 — Gate G1 record (2026-11-12)

Scope executed: G1 only (Swift toolchain + xtool download/extract/verify). G2–G5 remain ON HOLD; no apt installs, no Xcode XIP download, no Apple authentication, no device access, no `xtool setup`.

## Components installed (all inside the project)
| Item | Version | Location | Download size | Extracted size | SHA-256 (computed) | Verification |
|---|---|---|---|---|---|---|
| Swift Linux toolchain (Ubuntu 26.04, x86_64) | 6.4.2 (swift-6.4.2-RELEASE) | `07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04/` | 1,111,257,289 B (1.1 GB) | 3.6 GB (2,265 files + 39 symlinks) | `ff69258a20ad7a70e31ec6bd983b4bcb241481001ebdbf5245150f7125f11e27` | **GPG verified** against swift.org key bundle (`swift.org/keys/all-keys.asc`): "Good signature from Swift 6.x Release Signing Key", primary fp `52BB 7E3D E28A 71BE 22EC 05FF EF80 A866 B47A 981F`. Note: swift.org publishes no per-tarball .sha256 sidecar; GPG sig is the trusted check. |
| xtool AppImage (x86_64) | 1.24.0 | `07_tools/xtool/xtool-x86_64.AppImage` | 54,135,288 B | — (single file) | `dbfd9d7216f077c84c171b688c4173c37c23ca76bf7fd185d1a9ae8a53dab59f` | SHA-1 `a22ff7bf9ea797d486b1b3d49fc702a936d4b667` matches the release's own `.zsync` manifest; byte length matches GitHub release API metadata exactly. |

`swift sdk list` already reports `darwin` (bundled iOS SDK stub in the 6.4 toolchain — favorable; the full SDK is still generated by `xtool setup` at G4).

## Verification commands (actual output)
- `swift --version` → `Swift version 6.4.2 (swift-6.4.2-RELEASE)` / `Target: x86_64-unknown-linux-gnu`
- `swift sdk list` → `darwin` (exit 0)
- `xtool-x86_64.AppImage --version` → `xtool 1.24.0`
- `xtool-x86_64.AppImage --help` → full subcommand list (setup/auth/sdk/new/dev/ds/devices/install/uninstall/launch)

## AppImage compatibility check (item 7)
Ubuntu 26.04.1 LTS x86_64: the AppImage runs **directly, without installing any system package** — no FUSE install was needed (its runtime is static-pie ELF; verified with `file`), and it executes from `/mnt/c` drvfs. Nothing was added to global PATH; it is invoked by its project-local path only.

## Disk usage & deviations
- Project additions: `07_tools/swift-linux/` 4.7 GB total (tarball 1.1 GB + extracted 3.6 GB), `07_tools/xtool/` 52 MB.
- Documented deviations outside the project root (deletable caches only, same precedent as Phase 1):
  - `$HOME/.gpg-weather/` (WSL ext4, ~1 MB) — temporary GPG keyring used to verify the Swift signature; gnupg refuses keyrings on drvfs. Deletable at any time.
- WSL disk: 941 GB free after G1.

## Scripts created (rule 7)
- `07_tools/verify-swift.sh` — GPG verification of the Swift tarball.
- `07_tools/g1-verify.sh` — G1 verification suite (swift/sdk/integrity/disk/xtool).

## Extraction note (documented)
Plain `tar -xzf` on `/mnt/c` fails on utime/chmod (drvfs limitation). Extraction used `tar -xzf <tarball> -m --no-same-owner --no-same-permissions`; the remaining 10 "Cannot change mode" messages are directory-permission no-ops on drvfs. Integrity confirmed: tarball members 2,304 = extracted files 2,265 + symlinks 39, and `swift --version` runs.

## Next gates (unchanged, all require explicit approval)
- G2: `sudo apt-get install usbmuxd libimobiledevice-utils` (system change)
- G3: user downloads Xcode 27.1 XIP via browser
- G4: `xtool setup` — stops at the interactive credential prompt for the user
- G5: signed Hello World on device (device access pre-approved by user)

## G3 preparation (2026-11-12, nothing executed)
- `05_ios_port/G3_PREP.md` written: official Apple download page (`developer.apple.com/download/all/?q=Xcode`), Xcode_27.1.xip requirements (the exact version xtool 1.24.0 docs name), space estimates (XIP ≈12–16 GB, transient unpack ≈30 GB, generated SDK ≈3–6 GB), manual browser-download instructions, and the `xtool sdk build <xip> <out>` project-local extraction procedure.
- **Discovery:** `xtool sdk status` reports "Darwin SDK is installed" (`/home/naredi/.swiftpm/swift-sdks/darwin.artifactbundle`, flavor normal, epoch=4) — bundled by Swift 6.4.2. The XIP (G3) is therefore possibly unnecessary; proposal recorded in G3_PREP.md to attempt the Hello World against the bundled SDK first, XIP path kept as fallback.
- GPG keyring deviation documented: `/home/naredi/.gpg-weather/` (WSL ext4, ~1–2 MB, swift.org public keys only); cleanup = `rm -rf /home/naredi/.gpg-weather` when approved.
- Gate state: G2 deferred by user until device deployment; G3/G4/G5 not executed.

## G3 SDK audit (2026-11-12, read-only)
- `05_ios_port/G3_AUDIT.md` written. Verdict: existing Darwin SDK is **complete** — iOS SDK **27.2** (iPhoneOS + iPhoneSimulator + MacOSX), 341 device frameworks incl. UIKit/SwiftUI/MapKit/CoreLocation with swiftmodules and swiftinterfaces, full toolset (ld64.lld, llvm-lib, dsymutil), targets `arm64-apple-ios` + simulators. `swift sdk list` → `darwin`; `xtool sdk status` discovers it.
- **Recommendation: skip the Xcode XIP download (G3); G3_PREP.md kept as fallback.**
- Disclosures: (a) `xtool sdk status` auto-installed the 7.0 GB SDK at `~/.swiftpm/swift-sdks/darwin.artifactbundle` (outside project, deletable via `xtool sdk remove`); (b) `~/.config/xtool/data/` contains 5 small auth-scaffold files (incl. XTLAuthToken, 409 B) created 14:51–14:52 — contents deliberately not read; flagged for user decision before G4.
- New audit scripts: `07_tools/g3-audit.sh` … `g3-audit6.sh` (all read-only).
- Gate state: G3 recommended-skip pending user approval; Hello World compile test plan drafted in G3_AUDIT.md awaiting approval; G4/G5 not executed.

## G5 compile-only test (2026-11-12) — SUCCESS
- Hello World SwiftUI app created at `05_ios_port/HelloWorld/` (xtool 1.24.0 `new --skip-setup`, bundle ID `dev.kiankonrad.weather.hello`), compiled and linked for **arm64-apple-ios** against Darwin SDK 27.2 with Swift 6.4.2 — **no Apple auth, no signing, no device**.
- Product: unsigned `.app` with a **Mach-O 64-bit arm64 executable** (magic `cf fa ed fe`, cputype arm64, `NOUNDEFS|DYLDLINK|TWOLEVEL|PIE`; NOT Linux ELF), 92,648 B, SHA-256 `25948c8d…4469aa`, archived at `06_build_artifacts/hello-world-ios-binary/HelloWorld-App/`.
- Build: `Build complete! (54.00 s)` cold; 18.10 s warm; **0 errors**, 33 harmless stale-file warnings. Logs in `06_build_artifacts/logs/`; compiler/linker flags recovered from xcbuild `.resp`/`LinkFileList` files.
- **Verdict: native iOS compilation and linking succeeded independently of signing** — the G3 Xcode XIP is confirmed unnecessary.
- Deviations: `~/hello-src/` ext4 build scratch (drvfs cannot hold executable Mach-O files; first drvfs attempt's app-move failed EPERM), documented in `05_ios_port/G5_COMPILE_TEST.md`; XTLAuthToken metadata inspected only (644/naredi/409 B/14:52), contents unread, file untouched.
- Full record: `05_ios_port/G5_COMPILE_TEST.md`. PORT_GRAPH.md updated with the Phase 2 toolchain section.
- STOP — awaiting approval before G4 (Apple auth) / G5 device steps.

---

## 2026-11-12 — G4 preparation (auth NOT executed; awaiting explicit approval)
- XTLAuthToken hardened: perms 644 -> **600**; parent `~/.config/xtool/data/` 755 -> **700**; verified via `stat` (owner naredi:naredi, 409 B, mtime unchanged). **Contents never read or printed.**
- xtool 1.24.0 auth workflow verified against official docs @ tag 1.24.0 (Documentation/xtool.docc/Installation-Linux.md): `xtool setup` = `xtool auth && xtool sdk`; login mode **0: API Key** (paid only — N/A) vs **1: Password** (any Apple ID; email+password+2FA; uses private Apple APIs — docs suggest a throwaway Apple ID); credentials "only sent to Apple". `xtool auth` subcommands confirmed live: login/logout/status; `xtool auth status` is credential-free post-login verification.
- Free-account signing limits documented (7-day app expiry, 3 App IDs per 7 days, device registration, Developer Mode, 1 dev cert, no push/TestFlight/App Store).
- New files: `05_ios_port/G4_PREP.md` (checklist, exact user interaction, limitations, secrets commitments), `07_tools/g4-token.sh`, `07_tools/g4-authhelp.sh`.
- Honored: no auth, no Xcode, no usbmuxd, no device access, no Weather port work. **STOP — awaiting explicit approval for `xtool auth login`.**

---

## 2026-11-13 — G4 executed: Apple authentication COMPLETED
- User ran `07_tools/g4-auth-login.sh` (`xtool auth login`, mode 1 Password) in their own WSL terminal; credentials typed privately by the user — nothing captured, logged, or automated by the agent (script contains no tee/redirect/logging).
- Verification: `xtool auth status` → **exit 0** (silent success). Metadata-only evidence: `XTLAuthToken` refreshed (409→412 B, mtime 2026-11-12 23:45:39, perms already 600; contents never read). Provisioning scaffolding (`XTLProvisioningInfo`, `XTLRoutingInfo`) untouched since 14:51 — no device registration, no provisioning profile created.
- Honored restrictions: no iPhone registration, no usbmuxd, no Xcode, no Weather port work.
- **STOP — awaiting explicit approval for G5 (sign + install on iPhone; requires G2 usbmuxd and device access).**

---

## 2026-11-13 — Unsigned IPA packaging test (HelloWorld, no signing, no Apple services)
- `xtool dev build --help` inspected first: `--sign` is a separate opt-in flag, `--ipa` packages a .ipa; without `--sign` no codesigning/Apple Developer Services is invoked — confirmed empirically (no auth calls, no cert/profile activity; `XTLAuthToken` untouched, never read).
- Command: `xtool dev build --ipa` in ext4 scratch `~/hello-src` (mirrored from project; drvfs cannot hold executables). `Build complete! (16.07 secs)` + `Packaging...` → `Wrote to /home/naredi/hello-src/xtool/HelloWorld.ipa` (96 KB). Log: `06_build_artifacts/logs/hello-ipa-build-20261113-*.log`.
- Verification: ZIP contains exactly `Payload/HelloWorld.app/{HelloWorld (92,648 B), Info.plist}`; Info.plist: CFBundleIdentifier dev.kiankonrad.weather.hello, CFBundleExecutable HelloWorld, MinimumOSVersion 17.0, platform iPhoneOS; executable = Mach-O 64-bit arm64 (magic cf fa ed fe, NOUNDEFS|DYLDLINK|TWOLEVEL|PIE); **unsigned**: 0 × LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision.
- IPA SHA-256: `98b123e85425624e3796cdf09d151552973669f0910dc0afe2f76b573191aa51` — copied to `06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa` (new dir; no existing files overwritten).
- Clarification: packaging ≠ installation. This IPA cannot launch on a device until signed (G5) — physical install requires G2 usbmuxd + device access, still pending approval. No iPhone touched.
- Scripts: `07_tools/ipa-help.sh`, `ipa-build.sh`, `ipa-verify.sh`. **STOP after verification, per instruction.**
## 2026-11-13 — Port foundation milestone (Step 3+4 of port kickoff)
- WeatheriOS created (bundle dev.kiankonrad.weather); 9 foundation Swift files + 2 documented template overwrites.
- `xtool dev build` unsigned: SUCCESS (exit 0), arm64 Mach-O, LC_CODE_SIGNATURE=0, no provisioning, no Apple services contacted.
- Executable SHA-256: 4f80335c5e6c9e7258c1e5febdf5392de7d4a06dc1d29f2661d460d65359dd7c.
- Unit tests: not runnable on Linux for iOS target (no `xtool dev test`); limitation documented.
- Next: user approval required before full feature implementation (provider decode, screens, MapKit layer).

## 2026-11-13 — Port complete: workstreams A–G + final unsigned IPA
All six workstreams finished under the standing autonomous directive; no Apple
services, signing, devices, or paid services were used at any point.

- **A Weather data provider (complete)**: OpenWeatherRepository + DataCodec
  port of Data.kt (parsers, WMO mapping, forecast projection inputs), 41 Linux
  logic tests (Swift Testing), 41/0 pass.
- **B Main screen (complete)**: ForecastPageView, SkyView, pager/bottom bar —
  MainActivity.kt layout & behavior port.
- **C Location & cities (complete)**: CityScreenView, search, saved-city
  management, permission flow.
- **D Metric details (complete)**: MetricScreenView with per-metric charts for
  all 11 metrics.
- **E Settings & persistence (complete)**: SettingsScreenView, bundled legal
  texts, JSON forecast cache persistence.
- **F Map & radar (complete)**: WeatherMapView — custom SwiftUI Web-Mercator
  tile renderer substituting MapLibre Native + OpenFreeMap vector style with
  CARTO dark-matter raster tiles (documented substitution; no MapKit on the
  Linux toolchain, no third-party packages). RainViewer coverage + radar
  layers, verbatim temperature polygon overlay, exact UI strings/errors/
  legends/attribution, camera gestures, 300 s refresh, animation timing,
  scenePhase lifecycle, "Try again" reset.
- **G Parity check (complete)**: automated Kotlin-literal scan
  (`07_tools/parity-check.sh`). Two genuine gaps found and fixed in
  WeatherMapView.swift: basemap-load failure now uses the exact Maps.kt:105
  message "Map could not load. Check your connection." (Maps.kt:106-110 tile
  message unchanged for radar/coverage tiles); accessibility label
  "Weather map centered on <city>" added (Maps.kt:104). Remaining scan hits are
  interpolation fragments, MapLibre internals, and API param lists — verified
  present in Swift. Log: `logs/parity-check-*.log`.
- **Final unsigned IPA (complete, verified)**:
  `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-115901.ipa`
  — bundle id `dev.kiankonrad.weather`, CFBundleShortVersionString 1.1.1
  (set post-build via plistlib because xtool 1.24.0 has no Info.plist
  override; nothing else modified), Mach-O arm64 (cputype 16777228), NO
  LC_CODE_SIGNATURE, no `_CodeSignature/`, no `embedded.mobileprovision`.
  SHA-256
  `6a032f8aa5cd005a1f57fbd699ec2e41a77122645a59a867363d8f70a5a1231e`.
  Full results: `IPA-VERIFICATION-20261113.md`.

**Caveat (unchanged)**: runtime behavior on a device/emulator is NOT verified —
restricted (no signing, no device registration). Verification is limited to the
build, static bundle inspection, and 41 logic tests. Reproduce via REPRODUCE.md
§5–§6 (`port-build2.sh` → `logic-tests.sh` → `package-ipa.sh` → `finalize-ipa.sh`).

**Next: project complete pending user review.**

## 2026-11-13 — Stability fix session (post-device-testing)
Device testing of the baseline IPA found: no vertical scroll past the current
conditions; Map/Cities/Settings buttons dead; app terminated under memory
pressure. Full root-cause investigation and fixes completed (details in
CHANGELOG.md 2026-11-13 Stability fix):
1. TileLayer `.id(cacheTick)` identity reset → infinite tile refetch/decode on
   the main actor → dead UI + memory-pressure jetsam. Replaced with stable
   identity + LRU-bounded cache + dedupe + negative cache + detached decode.
2. metricTiles GeometryReader collapse inside forecast ScrollView. Replaced
   with PreferenceKey width measurement.
3. detailGate rendered behind the ZStack. Moved to last ZStack child; pager
   switched to iOS 17 paging ScrollView; bottom bar parity with Kotlin.
- Tests: 41 existing + 9 new StabilityTests = 50/50 pass (Linux logic tests;
  log `06_build_artifacts/logs/logic-tests-20261113-125439.log`).
- New IPA: `Weather-unsigned-20261113-130504.ipa`
  SHA-256 `beb82eb893d7a2fc69381339187bc1630b12bf4ff13722245cb556679af59856`.
  Baseline IPA preserved untouched.
- Caveat: Linux tests + static inspection cannot establish actual iPhone
  memory behavior; device re-test required (needs signing — out of scope).

## 2026-11-13 — Runtime-debugging diagnostic build (final IPA delivered)
Device re-test: the 130504 stability build did NOT resolve scroll/navigation/
termination issues. Per instruction, NO speculative code changes were repeated.
Instead the project now ships a diagnostic build whose purpose is to establish
the actual runtime failure with evidence:
- Full DEBUG instrumentation wired through the app (launch, scenePhase with
  phys_footprint, MEMORY WARNING, every navigation/scroll/radar/tile event) —
  privacy-scrubbed, dual channel: os.Logger (`dev.kiankonrad.weather`/`stability`)
  + in-app ring buffer with Copy/Share on the new Diagnostics screen (ⓘ in the
  bottom bar). Temporary by design.
- Diagnostic configurations A–E (forecast-only → full app) via persisted
  `DebugConfig` toggles; map previews and radar gated, not removed.
- Tests: 56/56 (41 XCTest + 15 Swift Testing incl. 6 new DiagLogTests),
  `logs/logic-tests-20261113-132124.log`.
- **Final IPA: `Weather-unsigned-FINAL-20261113-133010.ipa`**
  SHA-256 `3b399e915b093acf6975fb77af00bc68cd96753dfce0f88ba17620150382782d`
  (see FINAL-IPA-VERIFICATION.md; prior IPAs untouched, SHA256SUMS.txt).
- **Status: pending device evidence.** The scroll break, dead map/cities/
  settings buttons and termination are NOT diagnosed — no runtime cause is
  provable statically and Linux tests cannot exercise SwiftUI/jetsam. The
  exact evidence checklist (crash/jetsam report, Console.app capture, in-app
  diagnostics exports per configuration A–E) is in FINAL-TEST-REPORT.md.

## 2026-11-13 — Crash/navigation/scroll fix mission (FIXED IPA delivered)

Device re-test still showed broken scrolling / dead map-cities-settings buttons /
termination. Mission: static investigation first, no speculative repeats, fixes,
tests, new unsigned IPA. **No device runtime logs were available** — no runtime
root-cause claim is made; see `06_build_artifacts/fix-mission-20261113-140433/CRASH-ANALYSIS.md`.

- Static audit found and fixed 9 evidence-backed defects (cancellation-immune
  `try?`+`while true` loops, pager triple-identity mismatch, simultaneousGesture
  interference, `snapshot!` force-unwraps, duplicate hour ids, unstructured airTask,
  unclamped pager index, diagnostics unreachable post-termination, barButton hit area).
- Crash-evidence channel: DiagLog disk session files + clean-end marker + on-device
  "PREVIOUS SESSION — ABNORMAL END" panel (privacy-scrubbed). Next device run yields
  the actual pre-termination Diag trail needed for a proven root cause.
- Self-test screens: NavTestView (3 buttons/3 destinations) and ForecastIsolationView
  (pager + vertical pages) for on-device independent verification.
- Tests: **67/67 pass** (52 XCTest + 15 Swift Testing, incl. 10 new StabilityFixTests)
  — host-side logic tests only, NOT device runtime tests.
- **New IPA: `Weather-unsigned-FIXED-20261113-140433.ipa`**
  SHA-256 `25e404a21764279ea8e9292631a30fcfb72a17d164a1ffa524a8ef176693d3c1`
  (FINAL-IPA-VERIFICATION.md; all four prior IPAs re-verified byte-identical, untouched).
- **Status: pending device evidence.** Device verification (touchscreen nav/scroll,
  termination capture via the DiagLog abnormal-session panel) still requires a
  physical run, which the mission restrictions forbid us to perform.

## 2026-11-13 — REA integration + original-APK deep analysis (Mission: "Integrate REA")
- Status: COMPLETE (static). REA installed isolated under `07_tools/rea-analysis/` (portable
  Node 24.22.1, rea-agents 6.9.0, jadx-headless-mcp 0.7.1, apktool wrapper). No `setup` run;
  no agent config / PATH / system changes; no device touched. REA_SETUP_REPORT.md documents
  install + all evidence runs.
- Original APK fully analyzed via REA (signature, manifest, 19,287 classes, 17 method
  decompiles, resources, apktool) and cross-checked against shipped source. Reports:
  ORIGINAL_APK_DEEP_ANALYSIS.md, ANDROID_IOS_PARITY.md, MEMORY_AND_UI_FINDINGS.md in
  `07_tools/rea-analysis/`.
- Runtime analysis NOT performed (no adb on Windows; no device/emulator connected) — §6
  condition not met; missing evidence is enumerated in the reports.
- iOS changes recommended but NOT applied (mission forbids modification yet): city-id pager
  identity + pager-derived currentIndex; non-overlaid bottom bar; disk tile cache. All prior
  artifacts and IPAs untouched.

## 2026-11-13 — Parity mission (ANDROID_IOS_PARITY.md implemented; PARITY IPA delivered)

All 8 architectural parity corrections from 
were implemented against the original Kotlin source as ground truth:
1. Pager pages keyed by city id (PagerPagePolicy + scrollPosition id binding; Android
   HorizontalPager key={cities[it].id}).
2. pagerMoved(to:) is the single writer of currentIndex (Android LaunchedEffect
   pager.currentPage); add/remove route through it.
3. Bottom bar is a .safeAreaInset(edge: .bottom) sibling, not an overlay.
4. Map/Cities/Settings/Diagnostics verified reachable (pinned by ScreenReachabilityTests).
5+6. Verified unchanged: one vertical ScrollView per city page + horizontal hourly strip.
7. New DiskTileCache actor (48 MiB LRU disk cache, evictDisk policy in TileCachePolicy,
   in-flight dedupe, .atomic writes) — counterpart of Android Maps.kt:81 HTTP cache.
8. Radar/temperature code untouched; tiles flow through the same helper.
- Tests: **80/80 pass** (52 XCTest + 28 Swift Testing; 13 new parity tests).
- Baseline preserved: `06_build_artifacts/parity-baseline-20261113/` (10 IPAs + 39 sources).
- **New IPA: `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-150013.ipa`**
  SHA-256 `9a8425fdc53a9a381cd58bc87ebc0b5f6ece6036efd3ea5b7c33334db386d258`
  (unsigned, arm64, dev.kiankonrad.weather, v1.1.1). All prior IPAs untouched.
- Status: parity fixes are static/host-tested only. Physical-device testing still
  required for: pager gestures with city-id identity, bottom-bar hit areas under
  safeAreaInset, disk-cache persistence/eviction across relaunch and memory
  pressure, radar/temperature rendering, diagnostics exports A–E.
