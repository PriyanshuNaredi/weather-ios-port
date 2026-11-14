# FINAL-IPA-VERIFICATION.md — fix mission 2026-11-13

## Artifact

- **File:** `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-FIXED-20261113-140433.ipa`
- **SHA-256:** `25e404a21764279ea8e9292631a30fcfb72a17d164a1ffa524a8ef176693d3c1`
- Byte-identical copy of the versioned build `Weather-unsigned-20261113-140433.ipa` (same hash).
- Prior artifacts untouched (all four earlier IPAs still present with their
  original hashes; nothing was overwritten or deleted).

## Verification output (from finalize-ipa.sh)

```
CFBundleIdentifier      = dev.kiankonrad.weather
CFBundleShortVersionString = 1.1.1
Mach-O magic ok: True
cputype                 = 16777228 (arm64)
LC_CODE_SIGNATURE present: False
_CodeSignature in zip:  False
embedded.mobileprovision in zip: False
```

- Valid ZIP structure (zip listing of Payload/… succeeded during finalize).
- ARM64 slice only, iPhoneOS SDK (arm64-apple-ios17.0 target, SDK 27.2, Swift 6, swift-version 6 mode).
- Unsigned per mission restrictions: no signing, no provisioning, no
  embedded.mobileprovision.

## Test evidence backing this build

- Logic test suite (Linux host, Foundation-only — **not** device runtime tests):
  **67 tests, 0 failures** = 52 XCTest + 15 Swift Testing
  (log: `06_build_artifacts/logs/logic-tests-20261113-135126.log`).
- Includes the 10 new mission tests: PagerIndexTests (4), RangeSpanTests (4),
  CancellationLoopTests (1), DiagSessionCleanTests (2).
- Build log of the FINAL compile: xtool dev build --ipa exit 0 (after fixing
  one compile error and one toolchain type-checker crash workaround; see
  CHANGELOG).
- **Not verified:** any on-device runtime behavior. No device access permitted.
