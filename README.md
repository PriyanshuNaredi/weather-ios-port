# Weather — Android APK → native iOS port

A native SwiftUI reimplementation of the Android weather app
([Kian-hdr/Weather](https://github.com/Kian-hdr/Weather), Kotlin + Compose + MapLibre GL,
MIT), built by reverse-engineering the APK and porting its behaviour screen by screen.

**iOS port: Priyanshu Naredi.** Original Android app: **Kian Konrad** (MIT) — every screen,
string, colour stop and cache budget in this port comes from his source. The app icon is
rendered from his `ic_weather_foreground.xml` vector by `07_tools/make-app-icon.swift`, not
redrawn by hand.

**Status: working.** The port builds, launches and runs on the iOS Simulator from a clean
clone; the Android source is the reference for every screen, string, colour stop and cache
budget. It is an unsigned development build — no Apple ID, signing team, TestFlight or App
Store involvement.

```
./07_tools/macos-build.sh          # generate project, build, install, launch
./07_tools/macos-tests.sh all      # 87 logic tests + 11 simulator UI tests
./07_tools/visual-audit.sh         # 10 named screenshots → 07_logs/shots/audit/
swift 07_tools/make-app-icon.swift # re-render the 1024 app icon from the APK's vector
./07_tools/ipa-build.sh           # unsigned release IPA → 06_build_artifacts/ipa/
```

`export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` first — this machine's
`xcode-select` points at the Command Line Tools.

## Layout

| Directory | Purpose |
|---|---|
| `00_original/` | Pristine inputs: cloned source (`source/`), APKs (`apk/` self-built, `apk/official/` release), checksums |
| `01_android_build/` | Build logs and reports (tests, lint) |
| `02_apk_analysis/` | Reverse-engineering outputs: manifest, jadx, apktool, resources, native, dependencies |
| `03_runtime_baseline/` | Emulator/device screenshots, recordings, test cases |
| `04_documentation/` | Architecture, findings, API inventory, permissions |
| `05_ios_port/` | The iOS app: `WeatheriOS/` (SwiftUI), `WeatherLogicTests/` (host logic suite), `project.yml` (XcodeGen spec — the source of truth) |
| `06_build_artifacts/` | apk/ipa artifacts |
| `07_tools/` | Build, test and audit scripts |
| `07_logs/` | Working logs, probe scripts, screenshots (gitignored) |

Tracking: `PORT_GRAPH.md`, `PROJECT_STATUS.md`, `CHANGELOG.md`, `REPRODUCE.md`,
`CODE_AUDIT.md`, `CREDITS.md`.

## Releases — unsigned IPA

`./07_tools/ipa-build.sh` builds the app for a real device (`-sdk iphoneos`,
`-configuration Release`) with **signing disabled** and packages
`Payload/WeatheriOS.app` into `06_build_artifacts/ipa/Weather-<version>-<build>-unsigned.ipa`
plus a `.sha256`. The script then proves the unsigned state: no `_CodeSignature`, no
`embedded.mobileprovision`, no `LC_CODE_SIGNATURE`, `codesign` reports the bundle as not
signed, and the archive passes `unzip -t`.

CI does the same on every `v*` tag (`.github/workflows/unsigned-ipa.yml`, `macos-15`): build →
upload the IPA as a workflow artifact → create the GitHub release with the install notes from
`.github/release-notes.md`. `workflow_dispatch` builds on demand and can publish a release too.

> **These IPAs are unsigned.** No Apple ID, certificate or provisioning profile is bundled, so
> they cannot be installed with Finder/Xcode and will not run on their own. They must be signed
> on-device by the person installing them:
>
> | Tool | Notes | Link |
> |---|---|---|
> | **SideStore** | Untethered AltStore fork — installs any `.ipa` with just your Apple ID and refreshes it before the 7-day certificate expires | <https://sidestore.io/> · [docs](https://docs.sidestore.io/docs/installation/install) |
> | **LiveContainer** | Runs apps in a container so they don't each consume one of the 3 free app slots; ships a `LiveContainer + SideStore` build | <https://github.com/LiveContainer/LiveContainer> · [LC + SideStore guide](https://livecontainer.github.io/docs/installation/lc_sidestore) |
>
> With a free Apple ID: 3 active apps, 10 new App IDs per 7 days, 7-day certificates. Verify a
> download with `shasum -a 256 -c Weather-*-unsigned.ipa.sha256`.

## What the port involved

Everything below is evidenced in `CHANGELOG.md`, `CODE_AUDIT.md` and
`05_ios_port/MACOS_VERIFICATION.md`.

**Bring-up and stability**
- XcodeGen spec as the source of truth (`project.yml`), generated `.xcodeproj` gitignored.
- Swift 5 language mode: Swift 6 strict concurrency rejected `DiagLog`'s `mach_task_self_`
  and `WeatherMapView`'s `inFlight`, Darwin-only paths the Linux build never compiled.
- `ForecastPageModel.init` rebuilt the model on every `onWeather` callback — a 22 Hz
  invalidation loop at 100% CPU. Now 5.7% idle.
- O(n²) `uniqued` → `Set`; `DateFormatter` churn removed; metric-grid layout feedback fixed.
- Basemap: CARTO returned "API KEY REQUIRED" placeholder tiles, replaced with keyless ESRI
  World Dark Gray.

**Cosmetic parity with the Compose app**
- `GlassPanel` wrapped card modifiers around a view-builder tuple, painting every child as
  its own card; one `VStack` fixed all 13 call sites.
- Bottom bar rebuilt to `MainActivity.kt` (labels + 12 pt padding), edge scrims bound to
  `safeAreaInsets`, saved cities as `GlassPanel` cards, `Grid` for equal metric-tile heights,
  round-capped `RangeBar`, 44 pt targets, diagnostics moved out of the bar into Settings.

**Behaviour**
- Radar opens on the oldest frame and plays the window once (~10 s), stopping at "now"
  instead of parking at the newest frame looking already-played.
- Temperature layer paints full-bleed colours with five badges, greedily spaced, kept off
  the screen edges, both overlay panels and the city marker.
- `+` Add-city control on the forecast header; `Map` / `Settings` / `Cities` bar labels kept.

**Audit (ponytail method, findings in `CODE_AUDIT.md`)**
- `LocationFinder.ensureAuthorized` deadlocked for a second caller (continuation stored
  after `unlock`, authorization never requested) — now waiter-queue based.
- `currentLocation`'s 18 s timeout never fired (`withTaskGroup` waits for every child) —
  now `withTaskCancellationHandler`; regression test `testUseMyLocationTerminates`.
- `DiskTileCache.store` re-sorted the whole index per tile; GeoNames `id` is a number, so
  every city key fell back to "lat,lon".
- Dead code removed (`legacyCartoBasemapTile`, debug-only views gated behind `#if DEBUG`).

**Assets and docs**
- App icon generated from the APK's vector (`07_tools/make-app-icon.swift`), verified on the
  simulator home screen.
- `CREDITS.md` for attribution, `README.md` for status, `CHANGELOG.md` per change.

## Key facts (verified)

- Original: public, MIT, Kotlin, single module `:app`, branch `main` @ `6267da88`, tag `v1.1.1`
- Gradle 9.3.1 wrapper, AGP 9.1.1, Kotlin 2.2.20, Compose (Material3), OkHttp 4.12.0, MapLibre GL 13.6.1
- App id `dev.kiankonrad.weather`, versionName 1.1.1, versionCode 6, minSdk 28, targetSdk 36, compileSdk 37
- Port: Swift 5 language mode, SwiftUI, custom tile renderer (no MapLibre on iOS), iOS 17+
- Data: Open-Meteo (forecast, air quality, geocoding), RainViewer (radar), Esri World Dark Gray
  basemap, © OpenStreetMap contributors — full list and licenses in `CREDITS.md`

## What differs from the Android app, deliberately

Each is a documented decision, not drift:

| Change | Why |
|---|---|
| Basemap: Esri World Dark Gray instead of OpenFreeMap | Keyless and reliable; CARTO was tried first and returned "API KEY REQUIRED" tiles |
| SwiftUI tile renderer instead of MapLibre | Keeps the port dependency-free; radar/temperature layers are drawn directly |
| `+` Add-city button on the forecast header | The APK relies on the bottom-bar Cities tab alone |
| Bottom-bar labels kept (`Map` / `Settings` / `Cities`) | Icon-only parity hid the only route to adding a city |
| Temperature badges thinned and kept off chrome | The APK labels every other sample; badges were clipped by screen edges and hidden behind panels |
| Radar plays the window once on open, then stops | The APK opens parked on the newest frame, which reads as "already played" |
| Page dots centred on the screen | The APK's are ~24 pt off centre |
| Diagnostics live at the end of Settings | No Android counterpart; it crowded the Cities tab |

## Status

Current state, defect history and verification evidence: `PROJECT_STATUS.md` and
`05_ios_port/MACOS_VERIFICATION.md`. Known open item: on-device (physical iPhone)
installation — blocked on an Apple ID / signing team, see `HACKINTOSH_SETUP.md` §7.

## Credits

This app stands on open-source work: Open-Meteo, CAMS, GeoNames, RainViewer,
OpenStreetMap contributors, Esri, OpenFreeMap, OpenMapTiles, MapLibre, XcodeGen and
ponytail. See **[`CREDITS.md`](CREDITS.md)** for what each provides, its license, and the
shout-outs.
