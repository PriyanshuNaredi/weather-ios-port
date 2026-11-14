# ANDROID_IOS_PARITY.md — Android ground truth vs current iOS port (2026-11-13)

Mission §5. Android column = REA bytecode evidence + shipped Kotlin source (see
ORIGINAL_APK_DEEP_ANALYSIS.md). iOS column = `05_ios_port/WeatheriOS/Sources/WeatheriOS`
current files. **No iOS code was modified in this mission.**

## 1. Comparison table

| Feature | Original Android | Current iOS port | Difference | Evidence |
|---|---|---|---|---|
| App shell | Single `MainActivity`; screens are branches of a `when(screen)` inside `WeatherApp`; `screen` is `rememberSaveable` | `ContentView` switches on `viewModel.screen` in a ZStack-like structure; `screen` in `WeatherViewModel` | Functionally equivalent; Android survives process death via rememberSaveable, iOS state is in-memory only | MainActivity.kt:96–129; ContentView.swift:62–121 |
| Screen graph | `when`: detail → map → cities → settings → weather; `BackHandler` pops detail then screen | `switch viewModel.screen` + `detail`; `back()` mirrors order (tested in StabilityTests) | Parity | MainActivity.kt:129; WeatherViewModel.swift |
| Bottom bar placement | **Inside the weather branch only**, a `Row` after `HorizontalPager.weight(1f)` — cannot be occluded; plain Material `IconButton`s | Bar is a separate row in the ZStack **overlaid over page content**; `.contentShape(Rectangle())` added as a fix | Android's bar never competes with page content for touches; iOS's overlaid bar can be covered by content whose own hit-testing wins (map previews, scroll content) | MainActivity.kt:144–156; ContentView.swift:176–200 |
| City pager | `HorizontalPager(state=rememberPagerState{cities.size}, key={cities[it].id})`, pages = full forecast pages | iOS 17 paging `ScrollView(.horizontal)` + `scrollTargetBehavior(.paging)`, pages `ForEach(cities.indices, id: \.self)` | **Key difference:** Android keys pages by **city id** (page content survives add/remove/reorder); iOS keys by **array index** (id: \.self) — after removing/adding a city, SwiftUI can recycle the wrong page's scroll state. Also Android's `currentIndex` is fed FROM the pager (`LaunchedEffect(pager.currentPage)`), a single source of truth; iOS maintains `currentIndex` and pager position as two states that can diverge | MainActivity.kt:104,144; ContentView.swift:145–165 |
| Forecast page scroll | ONE `Column(verticalScroll)` per page; hourly strip = `Row(horizontalScroll)` (different axis); `PullToRefreshBox` wraps it | Vertical `ScrollView` per page + horizontal hourly `ScrollView` + horizontal paging ScrollView outside — three scrollers | Structurally similar to Android post-fix, but iOS nests a horizontal pager and horizontal strip around the same vertical column, so gesture routing has one more layer than Android; Android additionally has native pull-to-refresh | MainActivity.kt:231; ForecastPageView.swift:62–110,187 |
| Map engine | MapLibre Native: GPU renderer, tile HTTP via OkHttp with **48 MiB bounded disk cache** at `cacheDir/map-http`, real User-Agent | Custom SwiftUI Mercator tile renderer + raster basemap tiles; in-memory **LRU 96 tiles (~25 MB)**; no disk tile cache | Biggest architectural divergence: Android delegates tiles to engine+disk cache (cheap memory, instant reload); iOS re-renders tiles in SwiftUI and holds them only in RAM — relaunching or leaving/re-entering the map refetches everything | Maps.kt:74–81; TileCachePolicy.swift:9–24 |
| Radar | RainViewer TileSets maxZoom 7; frame animation 700/1300 ms; re-load every 300 s while Rainfall active; `clearWeatherLayers` before re-add (no layer buildup) | Same endpoints, 700/1300 ms, 300 s refresh, per-namespace tile keys | Parity (verified Kotlin literal parity earlier) | Maps.kt:220–241; WeatherMapView.swift |
| Temperature layer | GeoJSON source + `FillLayer` opacity 0.42, fillAntialias off; labels pre-rendered Bitmap icons | Canvas polygons, same 0.42, temperatureColor ported verbatim | Parity | Maps.kt:246–248; WeatherMapView.swift |
| Map lifecycle | Explicit MapView start/resume/pause/stop shim; pauses off-screen | scenePhase lifecycle + cancel on disappear | Rough parity | Maps.kt:146–149 |
| Data refresh | Cache-first if `< 900 s`; ON_RESUME staleness tick; 15-min loop under `repeatOnLifecycle(RESUMED)`; PullToRefresh | Cache-first 900 s; 15-min structured Task (cancel-correct after fix) | Parity in policy; Android additionally ties refetch to lifecycle resume | MainActivity.kt:184–200 |
| Persistence | Cities: SharedPreferences JSON array; forecasts: **`AtomicFile`** `forecast-<key>.json` with failWrite rollback; prune non-saved cities on every saveCities | UserDefaults suite "weather"; Application Support "weather-cache" with **`.atomic` writes**; prune on saveCities | Parity (atomic-write equivalent) | OWR.saveCities decompile; OpenWeatherRepository.swift:101,178–182 |
| Image loading | No image library; bitmaps only for map labels | None (no image lib) | Parity | marker counts |
| Coroutines | lifecycle-scoped loops; `CancellationException` rethrown | structured Task, cancel-correct after fix | Parity post-fix | MainActivity.kt:198–200 |

## 2. Why forecast scrolling works on Android but failed on iOS

Android's guarantee comes from **one vertical scroll container per page** inside a
`HorizontalPager` that owns horizontal drags exclusively, with pages **keyed by city id**
and a **single source of truth** for the current page (`LaunchedEffect(pager.currentPage) → currentIndex`).
There is no simultaneous-gesture observer, no third scroller axis, and page identity
never changes when cities are reordered (the key follows the city).

The iOS port (even after the 140433 fixes) still has, per page: outer paging ScrollView →
inner vertical ScrollView → inner horizontal hourly ScrollView, an index-keyed pager,
and a separately-maintained `currentIndex`. The scroll symptom the device showed
("unreliable daily-forecast scrolling") is consistent with horizontal/vertical gesture
arbitration in this 3-scroller stack and/or page-state recycling after index-keyed
identity changes — **this is a hypothesis ranked by structural difference, not a proven
device root cause** (no device runtime evidence is available in this mission; see §4).

## 3. Why Android bottom-nav buttons work but iOS buttons didn't

On Android the bar is **not an overlay**: it is a `Row` sibling placed after the pager in
the same `Column`, and all other screens *replace* the weather branch entirely via
`when` — the bar physically cannot be overlapped, and Material `IconButton`s have
unconditional hit-testing. On iOS the bar sits over page content in a ZStack; any
content layer that wins hit-testing above it (map preview cards, scroll containers,
the temporary diagnostics overlay) makes the buttons dead. The iOS-side evidence that
this class of bug existed before: `.contentShape(Rectangle())` and re-rendering `detail`
as the last ZStack child were needed as fixes (CHANGELOG 2026-11-13 stability section).

## 4. Missing runtime evidence (mission §6)

No Android device/emulator and no Windows adb → no logcat, no UI-hierarchy dump, no
touch/memory traces for either platform. The iOS-side runtime evidence (device
crash/jetsam reports, Console capture, diagnostics exports A–E) is likewise pending
from the user. Conclusions above are static and ranked, not runtime-proven.

## 5. Exact Android method ↔ iOS file mapping

| Android (class.method) | Evidence | iOS file |
|---|---|---|
| `MainActivityKt.WeatherApp` | out-m-WeatherApp.json; MainActivity.kt:95–160 | ContentView.swift + WeatherViewModel |
| `MainActivityKt.ForecastPage` | out-m-ForecastPage.json; MainActivity.kt:163–235 | Views/ForecastPageView.swift |
| `MainActivityKt.CityScreen` | out-m-CityScreen.json | Views/CityScreenView.swift |
| `MainActivityKt.MetricScreen` | out-m-MetricScreen.json | Views/MetricScreenView.swift |
| `MainActivityKt.SettingsScreen` | out-m-SettingsScreen.json | Views/SettingsScreenView.swift |
| `MapsKt.NativeWeatherMap` / `WeatherMap` | out-class-MapsKt.json; Maps.kt:93,180 | Views/WeatherMapView.swift |
| `MapsKt.prepareMap` | Maps.kt:75–81 | Services/OpenMeteoClient.swift (HTTP config) |
| `MapsKt.clearWeatherLayers` / `temperatureFeatures` / `temperatureColor` | Maps.kt:359,365,387 | WeatherMapView.swift (Canvas) |
| `OpenWeatherRepository.cached/write/read/saveCities/get` | out-m-OWR-*.json | Repositories/OpenWeatherRepository.swift |
| `ForecastProjectionKt.atTime/conditionSourceAt/…` | out-class-ForecastProjectionKt.json | Repositories/ForecastProjection.swift |
| `DataCodec.*` | Data.kt | Repositories/DataCodec.swift |

## 6. Recommended iOS changes (NOT applied — mission boundary §8)

Ranked, each traceable to a structural difference above:

1. **Key pager pages by city id, not index** (`ForEach(cities, id: \.id)` with a
   id→index mapping for scrollTargetBehavior), and make the pager position the single
   source of truth for `currentIndex` (derive, don't mirror) — mirrors
   `HorizontalPager(key={cities[it].id})` + `LaunchedEffect(pager.currentPage)`.
2. **Move the bottom bar out of the overlay** — place it as a sibling below the pager
   (e.g. `safeAreaInset(edge: .bottom)` on the weather branch only) so nothing can
   cover its hit area; keep it rendered only on the weather screen like Android.
3. **Add a disk tile cache** (URLCache or file-backed, bounded ~48 MiB like Maps.kt:81)
   so map tiles survive relaunch — removes repeated refetch pressure that produced the
   earlier refetch/jetsam loop.
4. **Consider collapsing the 3-scroller stack**: Android's hourly strip works because
   it is the only horizontal scroller inside the vertical column *other than the pager*;
   verify iOS retains `.paging` behavior exclusivity (no simultaneous drag observers)
   and test `ForecastIsolationView` on-device before further change.
