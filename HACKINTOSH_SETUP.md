# HACKINTOSH_SETUP.md — Continue WeatheriOS development on macOS

This repository (`weather-ios-port`, **private**) was published from the
original Windows/WSL project directory on 2026-11-14. It contains everything
needed to keep developing the WeatheriOS port on a Hackintosh — source,
tests, reference material, and build metadata. Heavy toolchains, binaries
(IPA/APK), caches and logs were intentionally **not** committed.

## 1. Clone

```bash
gh auth login            # or ensure git has credentials for the private repo
gh repo clone PriyanshuNaredi/weather-ios-port
cd weather-ios-port
```

(The repo is private; an anonymous clone will fail.)

## 2. Toolchain requirements

| Requirement | Verified on the publishing machine | Recommended |
|---|---|---|
| macOS + Xcode | **NOT verified** — all builds so far ran on Linux (WSL) via `xtool`/SwiftPM; no Xcode/macOS build has ever been run | Xcode 15+ with iOS SDK |
| Swift | SwiftPM logic tests were built with a **Linux** Swift toolchain (verified on Linux only) | The Swift toolchain bundled with Xcode |
| Signing/provisioning | None exists in the repo — **must be configured locally on the Hackintosh** | Xcode-managed signing with your Apple ID / dev cert |

> ⚠️ **Everything macOS-related below is unverified.** The iOS app was
> compiled cross-platform on Linux (`05_ios_port/WeatheriOS`, SwiftPM layout,
> no .xcodeproj is committed). Opening it in Xcode and building has never
> been tested — expect to create an Xcode project or use an SPM-to-Xcode
> bridge and allow build-setting adjustments.

## 3. Open the project in Xcode (unverified)

There is no `.xcodeproj`/`.xcworkspace` in the repo (the Linux pipeline used
SwiftPM + `xtool`). Options, in order of least effort:

1. Create a new iOS App project in Xcode and add
   `05_ios_port/WeatheriOS/Sources/WeatheriOS` as source (bundle id
   `dev.kiankonrad.weather`, version 1.1.1 — see below), or
2. Use `xcodebuild` / an XcodeGen/Tuist spec you write locally.

Marked unverified because neither path has been exercised on macOS.

## 4. Run the logic tests (verified pattern on Linux; unverified on macOS)

The tests are a SwiftPM package:

```bash
cd 05_ios_port/WeatherLogicTests
swift test
```

Expected: **87/87 pass** (59 XCTest + 28 Swift Testing) — verified on the
Linux toolchain (`07_tools/logic-tests.sh`). On macOS run from the Xcode
toolchain this should be identical, but it has not been run there.

## 5. Bundle identity / version (parity with the Android original)

- Bundle identifier: `dev.kiankonrad.weather`
- Version: `1.1.1`
- Defined in `05_ios_port/WeatheriOS/Sources/WeatheriOS/Info.plist` /
  build scripts (`07_tools/ipa-build.sh`, `package-ipa.sh` — these are the
  Linux `xtool` scripts and will need macOS equivalents or adaptation).

## 6. The watchdog scheduler fix (latest state — preserved in this commit)

Defect: `Views/WeatherMapView.swift` tile-fetch task-group priming loop
(`while inFlightCount < TileCachePolicy.maxConcurrentTileFetches { addNext() }`)
spun forever on the MainActor whenever fewer pending tiles existed than the
concurrency limit (8) — `addNext()` silently returned on iterator exhaustion.
Result: frozen UI (dead buttons, no scrolling) until the OS watchdog killed
the app, on every second+ camera move when most tiles were cached.

Fix (minimal, 3 files):
- `Views/WeatherMapView.swift` — explicit `iteratorExhausted` flag; loop
  condition now `!iteratorExhausted && inFlightCount < …maxConcurrentTileFetches`.
- `Models/TileCachePolicy.swift` — pure `simulateTileScheduler` reference
  mirroring the fixed loop (Linux-testable; scope disclosure in
  `06_build_artifacts/watchdog-fix-baseline-20261114/BUILD-METADATA.md`).
- `WeatherLogicTests/…/StabilityFixTests.swift` — 7 `TileSchedulerTests`.

## 7. Outstanding device verification (REQUIRED)

The physical-device crash is **NOT claimed fixed**. The final unsigned IPA
(Weather-unsigned-20261114-091826.ipa, SHA-256
`caf962c8fc2e7fb4ec1808f6047ab7cd0cd4e1838ba629cd31e0022031510591`) was never
installed on an iPhone. On the Hackintosh you must:

1. Configure **signing and provisioning locally** (Apple ID / team,
   certificate, provisioning profile) — nothing signing-related is in the repo.
2. Build, sign, install on the iPhone and test: map pan/zoom on a cached map
   (the watchdog scenario), navigation, scrolling, cold start.
3. Record results and update `PROJECT_STATUS.md`.

## 8. Repo map

- `05_ios_port/WeatheriOS/` — the Swift app (SwiftPM layout, Sources/…).
- `05_ios_port/WeatherLogicTests/` — 87 host-side tests incl. the 7 scheduler tests.
- `05_ios_port/*.md` (G3_AUDIT, G5_COMPILE_TEST, …) — gate/audit records.
- `00_original/source/Weather/` — the Android reference source (Kotlin).
- `04_documentation/` — API endpoints, architecture, APK analysis, permissions.
- `06_build_artifacts/` — small text build metadata only (manifests, hashes,
  test/crash reports). IPAs and binaries are intentionally not committed.
- `07_tools/` — the small Linux build/verify scripts (`.sh`), plus
  `rea-analysis/` evidence JSON/MD. SDKs/toolchains are not committed.
- Root docs: README, CHANGELOG, PORT_GRAPH, PROJECT_STATUS, REPRODUCE.

## 9. Linux→macOS differences to expect

- The committed build scripts use Linux paths and `xtool` (no Apple
  frameworks on Linux); on macOS use native `xcodebuild` + signing instead.
- Line endings: files were committed with LF; Xcode handles this fine.
- `TileCachePolicy.simulateTileScheduler` is pure Swift — tests run unchanged.
- Anything UI-level (UIKit/SwiftUI differences across SDKs) is unverified on
  a real iOS SDK until the first macOS build.
