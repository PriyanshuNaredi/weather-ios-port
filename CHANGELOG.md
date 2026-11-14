# CHANGELOG

## 2026-11-13 — Android↔iOS architectural parity build (PARITY IPA)

Mission: implement the 8 parity corrections documented in
`07_tools/rea-analysis/ANDROID_IOS_PARITY.md`, using the original Kotlin source
(MainActivity.kt, Maps.kt) as behavioral ground truth — matching the interaction
model, not copying Android implementation details.

- **Fix 1 — city-ID page identity:** pages are now keyed by city id
  (`ForEach(viewModel.cities, id: \.id)` + `scrollPosition(id:)`), matching
  Android's `HorizontalPager(key={cities[it].id})` (MainActivity.kt:144). New
  pure policy `PagerPagePolicy` (StabilityPolicies.swift) converts id↔index.
- **Fix 2 — pager as single source of truth:** `pagerMoved(to:)` is the ONLY
  writer of `currentIndex` (Android `LaunchedEffect(pager.currentPage)`, line
  104); `add`/`remove` route programmatic page changes through it; the
  scrollPosition binding set→get derives the index — no competing state.
- **Fix 3 — bottom bar as layout sibling:** moved from overlay to
  `.safeAreaInset(edge: .bottom)` on the pager, matching Android's Row-after-pager
  hierarchy (content avoids the bar; bar never occluded).
- **Fix 4 — all four destinations reachable:** map/cities/settings via the screen
  switch, diagnostics via the fullScreenCover — verified statically, pinned by
  new `ScreenReachabilityTests` on the `Screen` raw values.
- **Fixes 5+6 — verified, no change needed:** ForecastPageView already has
  exactly one vertical ScrollView per city page plus an independently horizontal
  hourly strip (matches Android Column(verticalScroll) + Row(horizontalScroll)).
- **Fix 7 — bounded persistent disk tile cache:** new `Models/DiskTileCache.swift`
  (Swift actor, iOS counterpart of Android's 48 MiB `cacheDir/map-http` HTTP
  cache, Maps.kt:81): LRU-by-stamp eviction via new pure `TileCachePolicy.evictDisk`
  (budget 48 MiB, protected tiles never evicted), in-flight fetch dedupe (one
  Task per URL), .atomic writes (Android AtomicFile parity), self-healing index,
  survives relaunch. `WeatherMapView.mapTileData` now routes all tiles through
  it; fetch errors rethrow unchanged so tile error semantics are preserved.
- **Fix 8 — radar & temperature map preserved:** no radar/temperature code
  touched — both flow transparently through the same tile helper (radar
  RainViewer cadence, temperature FillLayer 0.42 unchanged).
- **Tests:** suite now **80/80 pass** (52 XCTest + 28 Swift Testing; 13 new
  parity tests: PagerIdentityTests ×5, DiskCachePolicyTests ×6,
  ScreenReachabilityTests ×2) — host-side logic tests, NOT device runtime tests
  (`logs/logic-tests-20261113-144943.log`).
- **Artifact:** baseline preserved first (`06_build_artifacts/parity-baseline-20261113/`:
  10 IPA SHA-256s + 39 Swift source hashes). New IPA
  `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-150013.ipa`,
  SHA-256 `9a8425fdc53a9a381cd58bc87ebc0b5f6ece6036efd3ea5b7c33334db386d258`,
  unsigned (no LC_CODE_SIGNATURE/_CodeSignature/embedded.mobileprovision),
  arm64 (cputype 16777228), bundle dev.kiankonrad.weather, v1.1.1. All prior
  IPAs untouched.
- **Still needs a physical device:** pager gesture/identity behavior across
  add/remove, bottom-bar hit areas under safeAreaInset, disk-cache behavior
  across relaunch and under memory pressure, radar/temperature rendering,
  diagnostics exports A–E.

## 2026-11-13 — Crash/navigation/scroll fix build (FIXED IPA)

Device re-test still showed: unreliable daily-forecast scrolling, dead map/cities/
settings buttons, app terminated. Mission required static investigation first, fixes,
regression tests, and a new unsigned IPA. Reports: `06_build_artifacts/fix-mission-20261113-140433/`.

- **Static defect audit (9 defects, all fixed — see CRASH-ANALYSIS.md):**
  cancellation-immune `try?`+`while true` loops (ForecastPageView, DiagnosticsScreenView)
  rewritten cancel-correct; pager triple-identity mismatch fixed to single `Int` identity
  (ContentView); `.simultaneousGesture(DragGesture)` monitor removed (ForecastPageView);
  `snapshot!` force-unwraps → `guard let` in tap closures; hourly ForEach enumerated-offset
  ids; air-quality side fetch → structured `async let`; `pagerMoved` clamped via new
  `PagerIndexPolicy`; barButton `.contentShape(Rectangle())` hit area.
- **DiagLog disk session files** (crash-evidence channel): per-session `session-<unixtime>.log`
  in Application Support/weather-diag; clean-end marker via `markSessionClean()` wired to
  scenePhase; next launch reports "PREVIOUS SESSION — ABNORMAL END" on-screen with copy
  button. Synchronous writes (survive jetsam right after an event); same-second session
  filenames collision-proofed. Privacy preserved: never coordinates/city names.
  Known fix: previous async utility-queue flush could lose the last events
  exactly in the crash case it exists to capture.
- **Self-test screens** (mission Phase 3/4): `NavTestView` (3 real buttons → 3 real
  destinations, stage evidence panel) and `ForecastIsolationView` (3-page pager + 60-row
  vertical pages, same scroll-target stack as the app) — reachable from Diagnostics.
- **Tests:** new `StabilityFixTests.swift` (10 tests) + `Models/StabilityPolicies.swift`
  (Foundation-only helpers). Suite now **67 tests, 0 failures** (52 XCTest + 15 Swift
  Testing). These are host-side logic tests, NOT device runtime tests — no device access
  permitted; no runtime root-cause claim made (see CRASH-ANALYSIS.md).
- **Build fixes:** `RangeSpan.band` optional now `guard`-unwrapped in RangeBar Canvas;
  NavTestView `if let route` shorthand restructured (Linux swift-frontend 6.4.2 type-checker
  assertion crash, not a source error).
- **Artifact:** `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-FIXED-20261113-140433.ipa`,
  SHA-256 `25e404a21764279ea8e9292631a30fcfb72a17d164a1ffa524a8ef176693d3c1`, unsigned,
  arm64, bundle dev.kiankonrad.weather, v1.1.1, no LC_CODE_SIGNATURE/_CodeSignature/
  embedded.mobileprovision. All four prior IPAs re-verified byte-identical (untouched).

## 2026-11-13 — Runtime-debugging diagnostic build (Phase 1–6)
Device re-test showed the 130504 stability build did NOT resolve the issues (scroll broken,
map/cities/settings dead, app terminated). Per instruction, **no further speculative fixes**
were made. This build ships evidence-collection instrumentation + diagnostic configurations.

- **Instrumentation** (privacy-scrubbed: counts/timings/screen names only, never coordinates
  or city names):
  - `Services/DiagLog.swift` (new): in-memory ring buffer (600 events, oldest-drop counted,
    clear resets), export text, phys_footprint via `task_vm_info` (Darwin-gated).
  - `Services/Diagnostics.swift`: `Diag.event` → os.Logger (`dev.kiankonrad.weather` /
    `stability`) **and** the ring buffer.
  - `Views/DiagnosticsScreenView.swift` (new): in-app diagnostics screen (ⓘ button in the
    bottom bar) — presets A–E, two toggles, live log (last 80), Copy / Share / Clear.
  - `App/WeatherApp.swift`: scenePhase transitions + MEMORY WARNING with footprint.
  - `ContentView.swift`: main-view lifecycle, every bottom-bar/nav/pager/city/unit tap.
  - `ViewModels/WeatherViewModel.swift`: navigate/back/pager/add/remove/unit/location/forecast
    load results + cache-skip events.
  - `Views/ForecastPageView.swift`: page appear/disappear, content render counts
    (days/tiles), scroll drag detection (simultaneous DragGesture ≥25pt).
  - `Views/WeatherMapView.swift`: screen lifecycle, drag detection, layer switches, radar
    timeline load/failure/frame ticks, play/pause; tile fetch/eviction stats.
- **Diagnostic configurations** (Diagnostics screen): A forecast-only (map previews off),
  B forecast + map previews, C map without radar, D map with radar, E full app. Map previews
  gated via `DebugConfig.mapPreviews` (passed to `ForecastPageHost`), radar TileLayers via
  `DebugConfig.radarEnabled` — nothing permanently removed.
- **Tests**: new `DiagLogTests` (6 Swift Testing tests on ring-buffer capacity, drop
  counting, clear semantics, export format, monotonic timestamps; DiagLog got an internal
  `init()` for isolated instances). `logic-tests.sh` copy list extended with DiagLog.swift.
  **56/56 tests pass** (41 XCTest + 15 Swift Testing), exit 0 (`logs/logic-tests-20261113-132124.log`).
- **Build fixes**: `WeatherApp.swift` scenePhase onChange — Scene-level overload takes a
  `() -> Void` closure and `ScenePhase` lacks `rawValue` in this SDK; zero-param closure +
  direct interpolation.
- **IPA**: `package-ipa.sh` exit 0 → `finalize-ipa.sh` →
  **`Weather-unsigned-FINAL-20261113-133010.ipa`** (SHA-256 `3b399e915b093acf6975fb77af00bc68cd96753dfce0f88ba17620150382782d`)
  in `06_build_artifacts/weather-ios-unsigned/`. Verified: bundle `dev.kiankonrad.weather`,
  version 1.1.1, arm64, no LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision.
  Baseline (115901) and stability (130504) IPAs untouched. New docs: FINAL-TEST-REPORT.md,
  FINAL-IPA-VERIFICATION.md, SHA256SUMS.txt.
- **Honest status**: the scroll break, dead buttons and termination are NOT yet diagnosed —
  no runtime cause is provable statically. Device evidence required is listed in
  FINAL-TEST-REPORT.md (crash/jetsam report, Console.app capture of subsystem
  `dev.kiankonrad.weather`, per-configuration A–E in-app diagnostics exports).

## 2026-11-12
- Restored shell connectivity; completed Step 1 environment inspection (Windows host + WSL Ubuntu + RE tool availability) — recorded in PROJECT_STATUS.md.
- Pre-clone inspection of https://github.com/Kian-hdr/Weather via GitHub API: repo exists, public, MIT, default branch `main` @ `6267da88`, tag `v1.1.1`; fetched and reviewed gradle-wrapper.properties, scripts/build.sh, settings.gradle.kts, gradle.properties, root/app build.gradle.kts **before** cloning (per user instruction).
- Created Phase 1 directory tree `00_original…07_logs` inside project root.
- Created PROJECT_STATUS.md, CHANGELOG.md, README.md.
- Identified blockers: no Android SDK on machine; build.sh/Gradle write outside project root by default; RE tools not installed. Awaiting user approval before any install or clone.

## Session 2026-11-12 (continued)
- WSL build pipeline works (wsl-build.sh v2; Gradle caches on WSL ext4 — /mnt/c drvfs breaks daemon registry writes).
- BUILD SUCCESSFUL in 7m11s: :app:assembleDebug :app:testDebugUnitTest :app:lintDebug. 28 unit tests pass; lint 0 errors / 21 warnings.
- Self-built debug APK copied to 06_build_artifacts/apk/app-debug.apk (SHA-256 ed25fb69…cc20e).
- Official v1.1.1 APK downloaded to 00_original/apk/official/ — SHA-256 49a502b2…99c1 matches release SHA256SUMS.txt; signing cert d3370a79…f5c3 matches README.
- RE tools installed portable: jadx 1.5.6, apktool 2.12.1 (07_tools).
- Step 5 done: apktool + jadx decode of official APK into 02_apk_analysis/; findings in 04_documentation/findings/apk-analysis.md.
- Step 7 done: PORT_GRAPH.md (file-dependency table, 4 Mermaid diagrams, portability classification).
- Step 8: feasibility table in PORT_GRAPH.md; final Phase 1 report delivered in chat.

## Session 2026-11-13
- G4 completed: Apple authentication via `xtool auth login` (mode 1 Password) run by the user in their own terminal; `xtool auth status` exit 0; XTLAuthToken refreshed (perms 600, contents never read); no provisioning/device activity. Recorded in PROJECT_STATUS.md + G4_PREP.md.
- Unsigned IPA packaging test: `xtool dev build --ipa` (no `--sign`) from ext4 scratch → `Payload/HelloWorld.app` verified (Mach-O arm64, unsigned — no LC_CODE_SIGNATURE/_CodeSignature/mobileprovision); IPA SHA-256 98b123e8…1aa51 archived at `06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa`. Packaging ≠ installation; no device touched.
## 2026-11-13 — WeatheriOS foundation (port Steps 3–4)
- Added: 05_ios_port/WeatheriOS (xtool project, bundle dev.kiankonrad.weather) with App/Models/Services/Repositories/ViewModels/Views foundation ports traced to Kotlin source.
- Changed: template WeatheriOSApp.swift + ContentView.swift overwritten (documented; retained per rule 3).
- Build: unsigned `xtool dev build` succeeds on Swift 6.4.2 / Darwin SDK 27.2; arm64, LC_CODE_SIGNATURE=0; artifacts copied without overwrite.
- Known limitation: unit tests not runnable for iOS target on Linux (no `xtool dev test`).

## 2026-11-13 — Workstreams A–G complete (full port)
- A Weather data provider: OpenWeatherRepository + DataCodec parsers (Data.kt port), 41 Linux logic tests.
- B Main weather screen: ForecastPageView + SkyView + bottom bar/pager (MainActivity.kt / MainActivity WeatherApp port).
- C Location & cities: CityScreenView + CoreLocation permission flow (Data.kt city search / MainActivity location flow).
- D Metric detail screens: MetricScreenView, 11 metrics with charts (MainActivity.kt metric section port).
- E Settings & persistence: SettingsScreenView + bundle legal texts + JSON cache persistence (SettingsScreen / Data.kt store port).
- F Map & radar: WeatherMapView — custom SwiftUI Web Mercator tile renderer substituting MapLibre Native + OpenFreeMap dark vector style with CARTO dark-matter raster tiles (documented substitution; no MapKit module on the Linux toolchain, no third-party packages permitted). RainViewer coverage (.32) + radar (.8) tiles maxTileZoom 7, verbatim temperatureFeatures/temperatureColor Canvas polygons at .42, exact UI strings/errors/legends/attribution, drag/pinch camera, 300 s refresh, 700/1300 ms animation, scenePhase lifecycle, "Try again" reset semantics.
- G Parity check: automated Kotlin-literal scan (07_tools/parity-check.sh). Two genuine gaps found and fixed in WeatherMapView.swift: basemap load failure now uses Kotlin Maps.kt:105 exact message "Map could not load. Check your connection."; map content carries the Maps.kt:104 accessibility label "Weather map centered on <city>". Remaining scan hits are interpolation fragments / MapLibre internals / annotations — no further user-visible gaps.
- Build: xtool dev build exit 0 (arm64-apple-ios, unsigned); logic tests 41/41.

## 2026-11-13 — Stability fix (forecast scroll, navigation, memory pressure)
- Root cause #1 (dead buttons + memory jetsam): TileLayer used `.id(cacheTick)`;
  every fetch completion reset view identity → @State cache wiped → `.task`
  restarted → infinite refetch/decode loop on every weather pager page. With
  Swift 6 actor isolation inheritance (SE-0431) PNG decode also ran on the
  main actor. Fixed: stable TileLayer identity; detached `Task.detached`
  decode; LRU-bounded cache (96 tiles ≈ 25 MB, `TileCachePolicy`); in-flight
  dedupe; 30 s failure negative-cache; per-namespace keys (radar frames no
  longer collide); concurrency cap 8.
- Root cause #2 (no vertical scroll): ForecastPageView metricTiles used
  GeometryReader + `.fixedSize(vertical: true)` inside the forecast ScrollView
  → collapsed to ~10 pt, corrupting layout/hit-testing below. Fixed with a
  PreferenceKey width measurement (MetricGridWidthKey).
- Root cause #3 (navigation): metric detail was rendered via
  `.background(detailGate)` — behind the ZStack, never visible/tappable. Fixed:
  rendered as the last ZStack child. Pager replaced TabView(.page) with iOS 17
  paging ScrollView (single horizontal axis, no nested vertical scrollers);
  bottom bar order corrected to Kotlin parity (map | dots | settings | cities);
  dead emptyCities view removed.
- Added: Services/Diagnostics.swift (DEBUG-only os.Logger, privacy-scrubbed:
  no coordinates/city names); TileCachePolicy.swift; StabilityTests.swift
  (9 new tests: eviction bounds, viewport protection, duplicate fetch,
  failure throttle, back() routing). Tests: 41 existing + 9 new = 50/50 pass.
- Other safeguards: updateTemperatures structured Task + duplicate guard +
  cancel on disappear; SkyView TimelineView throttled to 30 fps and paused
  under Reduce Motion.
- Build: package-ipa.sh compile fixes (Diagnostics.swift import scope +
  escaping autoclosure; PreferenceKey defaultValue var→let). New IPA:
  `06_build_artifacts/weather-ios-unsigned/Weather-unsigned-20261113-130504.ipa`,
  SHA-256 `beb82eb893d7a2fc69381339187bc1630b12bf4ff13722245cb556679af59856`,
  unsigned, arm64, version 1.1.1. Baseline IPA (115901) untouched.

## 2026-11-13 — REA integration + deep APK analysis (investigation only, no code changes)
- REA (`rea-agents@6.9.0`) installed fully project-local (`07_tools/rea-analysis/`): portable
  Node 24.22.1 (system Node 25 rejected by REA engines gate), npm prefix install, jadx-headless-mcp
  0.7.1 jar (SHA-256 verified), apktool wired via 8.3-short-path launcher (cmd.exe cannot
  represent the `→` in the project path). `npx rea-agents setup` deliberately NOT run — no agent
  config, PATH, or system changes. See `07_tools/rea-analysis/REA_SETUP_REPORT.md`.
- REA evidence runs on the official v1.1.1 APK: signature/package/manifest, class search + 8 class
  inventories, 17 single-method decompiles, apktool client check, resource decode — all with
  Evidence IDs; results cross-checked against shipped Kotlin source (agree).
- New reports: `07_tools/rea-analysis/{ORIGINAL_APK_DEEP_ANALYSIS,ANDROID_IOS_PARITY,MEMORY_AND_UI_FINDINGS}.md`.
- Key ground-truth findings: single-Activity Compose state machine (`when(screen)`, bar inside the
  weather branch, never overlaid); HorizontalPager keyed by **city id** with `currentIndex` derived
  from `pager.currentPage`; forecast page = one verticalScroll Column + horizontal hourly Row; no
  image library; MapLibre with bounded 48 MiB disk tile HTTP cache; AtomicFile forecast cache;
  900 s cache TTL / 15 min RESUMED refresh.
- Recommended (NOT applied): iOS pager keyed by city id + pager as single source of truth; bottom
  bar moved out of the overlay (safeAreaInset sibling); disk tile cache (~48 MiB). Device runtime
  evidence still pending on both platforms.
