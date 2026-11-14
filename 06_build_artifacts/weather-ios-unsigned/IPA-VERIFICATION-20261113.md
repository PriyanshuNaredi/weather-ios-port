# Unsigned IPA Verification Report

Date: 2026-11-13
Final artifact: `Weather-unsigned-20261113-115901.ipa` (version-corrected final)
Prior intermediate: `Weather-unsigned-20261113-115627.ipa` (xtool output as-built, version 1.0.0)

## Build
- Toolchain: Swift 6.4.2 (Linux), Darwin SDK iPhoneOS27.2, xtool 1.24.0
- Command: `xtool dev build --ipa` — **without** `--sign` (project restriction honored)
- Triple: `arm64-apple-ios` (ARM64 iOS)
- Build exit code: 0 (see `package-log-20261113-115627.txt`)
- Post-build step (documented): `CFBundleShortVersionString` set to 1.1.1 and
  `CFBundleVersion` to 1 via plistlib before rezipping, to match the original
  Android app version (xtool 1.24.0 has no Info.plist override; see
  `finalize-20261113-115901.log`).

## Verification results (final IPA)

| Check | Expected | Result |
| --- | --- | --- |
| ZIP structure | `Payload/WeatheriOS.app/…` | PASS — Info.plist, Mach-O executable, `WeatheriOS_WeatheriOS.bundle` with `legal/` (5 license texts) |
| Bundle identifier | `dev.kiankonrad.weather` | PASS |
| Bundle version | `1.1.1` | PASS |
| Mach-O | ARM64 executable | PASS — cputype 16777228 (arm64), magic 0xfeedfacf |
| LC_CODE_SIGNATURE | absent (unsigned) | PASS — not present |
| `_CodeSignature/` directory | absent | PASS — not present |
| `embedded.mobileprovision` | absent | PASS — not present |
| Apple authentication used | none | PASS — no certificate, no provisioning profile, no signing, no device interaction |

## SHA-256
```
6a032f8aa5cd005a1f57fbd699ec2e41a77122645a59a867363d8f70a5a1231e  Weather-unsigned-20261113-115901.ipa
```
(checksum file: `Weather-unsigned-20261113-115901.sha256`)

## Test report
- Linux logic tests (Swift Testing, `logic-tests.sh`): **41 executed, 0 failures**
- Covers: DataCodec parsers, weather text / label mappings, forecast projection,
  temperature color, formatting helpers, cache key/retention logic, camera math.
- Runtime verification on a device/emulator was NOT performed (restricted —
  no device registration, no signing); verification is limited to build,
  static bundle inspection, and logic tests, as documented in REPRODUCE.md.

## Parity-check notes (Workstream G)
- Automated Kotlin-literal scan (`parity-check.sh`, report-only) compared every
  Kotlin string literal ≥8 chars against the Swift sources.
- Two genuine gaps found and fixed in `WeatherMapView.swift`:
  1. Basemap load failure now reports Kotlin's exact Maps.kt:105 message
     "Map could not load. Check your connection." (previously reused the tile message).
  2. Map content carries the Maps.kt:104 accessibility label
     "Weather map centered on \(city.name)".
- Remaining scan hits are Kotlin interpolation fragments, MapLibre-internal
  identifiers (layer ids, `place_city`, `MissingPermission` suppress annotation),
  API parameter lists (verified present in Swift), and format strings — no
  further user-visible parity gaps identified.
