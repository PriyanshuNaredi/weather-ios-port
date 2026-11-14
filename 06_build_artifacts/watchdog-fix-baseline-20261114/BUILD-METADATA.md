# Watchdog-fix build metadata (2026-11-14)

## Defect
WeatherMapView tile-fetch task-group priming loop
`while inFlightCount < TileCachePolicy.maxConcurrentTileFetches { addNext() }`:
`addNext()` silently returned when the pending-tile iterator was exhausted, so
whenever fewer pending tiles existed than the limit (8) the loop spun forever
synchronously on the MainActor — frozen UI (dead buttons, no scrolling) until
the OS watchdog terminated the app. Occurs on every second+ camera move when
most tiles are already cached.

## Change (3 files, minimal)
- Views/WeatherMapView.swift: explicit `iteratorExhausted` flag set inside
  `addNext()`; priming loop condition now
  `!iteratorExhausted && inFlightCount < TileCachePolicy.maxConcurrentTileFetches`.
- Models/TileCachePolicy.swift: pure `simulateTileScheduler` reference added
  (Linux-testable; mirrors the fixed loop exactly). Added because the logic
  test package only compiles the pure-logic files (same convention as the
  earlier Screen enum relocation) — scope disclosure, see final report.
- WeatherLogicTests/StabilityFixTests.swift: 7 new TileSchedulerTests
  (0/1/7/8/25 pending, exhaustion termination, full draining).

## Tests
logic-tests.sh: 59 XCTest + 28 Swift Testing = 87/87 pass, 0 failures, exit=0.
Host-side logic tests only — not device tests.

## Artifacts (all prior IPAs untouched; before-hashes in IPA-HASHES-BEFORE.txt)
- Weather-unsigned-20261114-091720.ipa (pre-finalize package output)
  SHA-256 06520d7b79b060e72890b18bade08c185615ac623f65abbf4844402b2f078e9d
- FINAL: Weather-unsigned-20261114-091826.ipa
  SHA-256 caf962c8fc2e7fb4ec1808f6047ab7cd0cd4e1838ba629cd31e0022031510591
  Verified: CFBundleIdentifier dev.kiankonrad.weather, v1.1.1, Mach-O arm64
  (cputype 16777228), NO LC_CODE_SIGNATURE, no _CodeSignature/,
  no embedded.mobileprovision. Unsigned — needs signing to launch.

## Verification limits
No device access: the physical-device crash is NOT claimed fixed until this
build is signed, installed and tested on the iPhone.

## git diff --check status
The project is not a git repository (confirmed this session), so
`git diff --check` cannot run. Equivalent check performed instead on all 3
modified files: no trailing whitespace, no tabs, no conflict markers found.
Post-fix full Swift-source manifest: SOURCE-MANIFEST-AFTER.txt.
