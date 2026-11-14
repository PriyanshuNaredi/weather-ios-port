# MACOS_VERIFICATION.md — first real macOS/Xcode build of the iOS port

Environment: Hackintosh, macOS 15.5 (24F74), x86_64, **Xcode 16.0 (16A242d)**,
iOS 18.0 SDK, iPhone 16 simulator (22A3351). `xcode-select` still points at the
Command Line Tools, so everything sets `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
(no `sudo xcode-select -s` needed). XcodeGen 2.x via Homebrew.

Date: 2026-11-14. Baseline commit: `dc03dd7`.

## How it builds now (verified commands)

```bash
brew install xcodegen
./07_tools/macos-build.sh     # generate + build + install + launch on the simulator
./07_tools/macos-tests.sh     # host logic suite (87) + simulator UI suite (7)
```

The repo had **no `.xcodeproj`** — all prior builds were Linux `xtool`/SwiftPM.
`05_ios_port/WeatheriOS/project.yml` is now the macOS build definition
(XcodeGen); the generated `WeatheriOS.xcodeproj` and `Support/Info.plist` are
gitignored, so `project.yml` stays the single source of truth.

App identity matches the Android original: `dev.kiankonrad.weather`, 1.1.1 (6),
iOS 17 deployment target, `NSLocationWhenInUseUsageDescription` +
`NSLocationWhenInUseUsageDescription` for the `ACCESS_COARSE/FINE_LOCATION`
permissions declared in `AndroidManifest.xml`.

## Verified working (simulator, live network)

| Surface | Evidence |
|---|---|
| Cold start → city screen | `testSearchAddCityAndRenderForecast` |
| Real geocoding search (Open-Meteo/GeoNames) | same test: types "Berlin", taps the result row |
| Forecast render (10-day, hourly, metric grid) | temperature `°` labels present within ~1 s |
| Bottom-bar navigation, settings, cities | `testBottomBarNavigation` |
| Map: basemap + radar overlay + city dot + pan/pinch | `testMapPanAndZoomStaysResponsive` |
| Metric detail screen | `testMetricDetailAndCityPager` |
| Bundled `legal/*.txt` resources | `testSettingsUnitsAndLegalTexts` (Apache text found in bundle) |
| Units switch (metric ↔ imperial) | same test |
| Idle CPU on the forecast screen | 5.7% (was 100%) |
| Host logic suite | 87/87 pass on the macOS toolchain (59 XCTest + 28 Swift Testing) |

## Defects found on macOS (all fixed in this change)

1. **Swift 6 strict-concurrency build failure** — `DiagLog` (`mach_task_self_` read,
   only compiles on Darwin) and `WeatherMapView` (`inFlight` mutated from a
   nonisolated closure) failed the build in Swift 6 mode. The app target builds in
   **Swift 5 language mode** (matching what the Linux pipeline actually exercised);
   the logic test package pins `.v5` too.
2. **Broken dark basemap** — CARTO `dark_all` raster tiles now answer `200` with a
   placeholder PNG reading "API KEY REQUIRED" for keyless requests, so the map was a
   grid of watermarks. Switched to Esri World Dark Gray Canvas (keyless, same role);
   attribution strings updated. Verified visually.
3. **Inert units switch** — the SwiftUI `Toggle` in Settings never called its setter
   (no `units ->` diagnostic event at 5 different hit points, while buttons on the
   same screen worked). Replaced with a Button + capsule switch, which also gives a
   proper 44 pt target.
4. **100% CPU / UI stall after scrolling (the serious one)** — `ForecastPageModel.init`
   forwarded the cached snapshot via `onWeather`, so every parent re-render built a new
   page model that wrote back into the shared `WeatherViewModel`, re-invalidating the
   parent: a self-sustaining ~22 Hz SwiftUI invalidation loop. Symptoms: device-warm
   simulator, and XCTest "Failed to get matching snapshots: Timed out while evaluating
   UI query" whenever the forecast was scrolled. Fixed by moving the one-shot forward
   to `forwardInitialWeather()` called from the page's `.task`. Idle CPU 100% → 5.7%;
   the metric-detail test went from timing out (199 s) to passing in 48 s.
5. **O(n²) hourly dedup** — `Array.uniqued` used `contains` per element over 240 hourly
   points, called per metric tile per layout pass. Now `Set`-based.
6. **DateFormatter churn** — `localTime` allocated a formatter per call (48 hourly
   labels per pass) and `DisplayClock.uses24Hour` re-read the locale template each time.
   Both cached.
7. **Metric-grid layout feedback** — column count was derived from a width the grid
   itself measured, so sub-point jitter across the 330 pt threshold re-laid-out forever.
   Measurement is now quantised with a dead band.
8. **Tooling gaps for macOS** — logic test package had no `platforms:` (macOS 10.13
   default rejected `FileHandle.write(contentsOf:)`); added `.macOS(.v14)`.

## Not verified here

- **Physical iPhone**: no signing identity/team exists in this environment
  (`sudo` needs a password, no Apple ID configured). The signed-IPA and on-device
  paths from `HACKINTOSH_SETUP.md` §7 remain open.
- **Watchdog regression on real hardware**: the simulator reproduces the *old* freeze
  conditions (cached-tile pan/zoom) only synthetically; the map test covers the
  gesture path and responsiveness, not the device watchdog.
- Android parity of the basemap change: the Android app still loads the OpenFreeMap
  dark vector style, which is unaffected; only the iOS raster endpoint moved.

## Cosmetic parity pass (same day)

Every screen was re-checked against the Compose source and re-captured with
`./07_tools/visual-audit.sh` (output in `07_logs/shots/audit/`):

| Surface | Was | Now |
|---|---|---|
| Settings "Units" | heading and value row painted as two cards | one card (GlassPanel now stacks children like Kotlin's Column) |
| Bottom bar | text labels, 8 pt spacing, extra debug "i" beside Cities | icon-only 48 pt targets, SpaceBetween, 8 pt dots, 12 pt padding, no debug icon |
| Status/nav bar | unscrimmed sky | `0x99112340` scrims over both edges |
| Saved cities | `List` chrome | Glass cards, 12 pt apart |
| Metric tiles | ragged row heights | equal per row, summary wraps (no ellipsis) |
| Day range bars | square end at the scale maximum | round caps inset by radius |
| Headers / links | small hit targets | 44 pt targets matching Material `IconButton`/`TextButton` |

`VisualAuditTests` is skipped in normal runs; the suite reports `1 skipped`.

## Later same day — chrome, behaviour, audit, identity

| Area | Change | Evidence |
|---|---|---|
| Page indicator | dots were centred in the leftover bar gap (172.5 pt vs 196.5 pt) — 24 pt left of centre; now an overlay centred on the full bar width | `testPageIndicatorIsCentred` (midX within 1.0 pt) |
| Add city | explicit `+` on the forecast header, 44 pt, wired to the Cities tab | `testAddCityButtonOpensSearch` |
| Radar playback | opened parked on the newest frame with nothing playing, which reads as "already played"; now opens on the oldest frame and plays the window once (~13 frames, 10 s), stopping at "now" | `testRadarPlaysOnceFromTheStartWhenMapOpens`; session log frames 2/13→13/13 then silence |
| Temperature colours | full-bleed over the whole viewport (Kotlin `FillLayer`); a capped sample box was tried and reverted because the shading read as half-drawn | `audit-10-map-temperature` |
| Temperature badges | at most five, greedily spaced (96×78 pt), ≥34 pt from edges, excluded from the measured top/bottom panel frames and the city marker | same capture: 5 badges, none clipped or overlapped |
| Repo audit | two `LocationFinder` hangs, `DiskTileCache` index re-sort per tile, GeoNames numeric `id`, dead code gated/removed | `CODE_AUDIT.md`, `testUseMyLocationTerminates` |
| App icon | rendered from the APK's `ic_weather_foreground.xml` vector; the target had an empty `ASSETCATALOG_COMPILER_APPICON_NAME`, so no icon ever compiled | `Assets.car` in the bundle; home-screen capture in `07_logs/shots/icon-on-home.png` |
| Attribution | Settings footer names the iOS port author and keeps "Based on Weather for Android by Kian Konrad (MIT)"; `CREDITS.md` lists every upstream project | `audit-06-settings-bottom` |

Suites at this point: 87 logic tests (59 XCTest + 28 swift-testing) and 11 UI tests pass;
`VisualAuditTests` is skipped in normal runs (1 skipped).
