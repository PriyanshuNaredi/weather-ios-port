# ORIGINAL_APK_DEEP_ANALYSIS.md — Ground-truth analysis of Weather v1.1.1 (Android)

Evidence sources: REA Evidence bundles (see REA_SETUP_REPORT.md §3) on
`00_original/apk/official/Weather_v1.1.1.apk` (SHA-256 `49a502b2…99c1`), plus the
shipped Kotlin source `00_original/source/Weather/` used as the readable cross-check
(bytecode and source agree on every structural fact below). Mission §4, areas A–E.

## A. UI architecture

- **Single-Activity Compose app.** Manifest: one exported LAUNCHER activity
  `dev.kiankonrad.weather.MainActivity`; no fragments, no fragments-library dependency,
  no `androidx.navigation` component, no bottom-nav composable. (out-package.json)
- **Screen switching is a state machine inside one composable.** `WeatherApp` keeps
  `var screen by rememberSaveable { mutableStateOf("weather") }` and a
  `var detail by remember { mutableStateOf<Metric?>(null) }`, then a `when` block picks
  exactly ONE of: `MetricScreen` (if detail != null), `WeatherMap` (screen=="map"),
  `CityScreen` (screen=="cities" or cities empty), `SettingsScreen` (screen=="settings"),
  else the weather page. (MainActivity.kt:129–144; WeatherApp decompile)
- **The bottom bar lives INSIDE the weather branch** — it is a `Row` placed after
  `HorizontalPager(Modifier.weight(1f))` in the same `Column`: map IconButton, page dots
  (center, `pager.currentPage` highlight), settings IconButton, cities IconButton.
  Because the whole branch is replaced by `when`, the bar cannot be occluded by any
  other screen, and it is only rendered on the weather screen. (MainActivity.kt:144–156)
- **Navigation is not a stack.** `BackHandler(screen!="weather" || detail!=null)` pops
  detail first, then screen→"weather". Screen transitions have no saved per-screen state
  other than `screen` itself (rememberSaveable). (MainActivity.kt:127)
- Pager ↔ index sync: `LaunchedEffect(pager.currentPage) { currentIndex = pager.currentPage }`;
  `add(city)` dedupes by id, saves, sets screen back to "weather", and
  `pager.scrollToPage(...)`. Pager pages are keyed `key={cities[it].id}`. (MainActivity.kt:104,117–122,144)
- City search screen uses `LazyColumn` (weight(1f)); SettingsScreen and MetricScreen use
  `Column(verticalScroll(rememberScrollState()))` — bytecode marker counts match
  (LazyColumn×1 in CityScreen; verticalScroll×1 in each). No Lazy* anywhere on the
  forecast page.

## B. Weather screen (forecast page)

- Per-city state, keyed by city: `remember(city.id)` for weather/refreshing/error
  (WeatherApp$add and ForecastPage decompiles). Data flow is pull-based: page pulls from
  `repository.cached(city)` first, then fetches.
- **Refresh policy (bytecode-verified):** initial load serves the cache if
  `now - fetchedAt < 900 s`; a `LifecycleEventObserver` bumps a `tick` on ON_RESUME when
  the snapshot is ≥ 900 s old; a `repeatOnLifecycle(RESUMED) { while(true) { delay(15*60_000); tick++ } }`
  re-fetches every 15 min while resumed. `CancellationException` is rethrown, other
  errors fall back to the cache with distinct messages.
- **Layout:** `PullToRefreshBox { Column(fillMaxSize.verticalScroll(...).padding(horizontal=20.dp)) }` —
  ONE vertical scroller per pager page containing header, notice, estimated-now glass
  card, summary, hourly strip, daily list, metric tiles. The hourly strip is a
  `Row(horizontalScroll)` inside that column (48 entries max, first "Now" entry merged).
  **No nested vertical scrollers anywhere on the page.**
- Scrolling works on Android because the page has exactly one vertical scroll container
  and one horizontal one, on different axes, inside a `HorizontalPager` that consumes
  only horizontal drags.
- Metric tiles call `onMetric(snapshot, metric)` → `detail = metric` → `MetricScreen`
  branch of `when` (full-screen replacement, not an overlay).
- `MetricScreen`: `Column(verticalScroll)` with chart; chart is Canvas-based (no image lib).
- `compact` layout for `screenHeightDp < 500` and font-scale-aware sizing.

## C. Map & radar (Maps.kt)

- **MapLibre Android** (`org.maplibre.android.*`); `prepareMap()` initializes MapLibre
  once with an OkHttpClient carrying a real application identity (User-Agent) and a
  **bounded 48 MiB disk HTTP cache** at `cacheDir/map-http` (Maps.kt:74–81). Map tile
  HTTP traffic therefore has dedupe + disk caching at the client layer.
- `NativeWeatherMap` wraps a raw `MapView` with an explicit lifecycle shim
  (start/resume/pause/stop flags, Maps.kt:146–149) — map renders only pause when the
  screen is not visible. Style load failure posts the exact message
  "Map could not load. Check your connection."; tile `TileOperation.Error` is surfaced too.
- City marker: `GeoJsonSource("city")` + `CircleLayer` (blue #1679f2, white stroke);
  style SymbolLayers (place labels) get textSize scaled by `labelDensity`.
- **Radar:** RainViewer — coverage TileSet `…/v2/coverage/0/256/{z}/{x}/{y}/0/0_0.png`
  and frame TileSet `{host}{frame.path}/256/{z}/{x}/{y}/2/1_1.png`, both `maxZoom = 7f`;
  raster layers added above basemap, below overlays. Timeline animation advances with
  `delay(if(lastIndex) 1300 else 700)` ms. While the Rainfall layer is active and map
  shown, a `LaunchedEffect` re-loads radar every 300 s.
- **Temperature grid:** `GeoJsonSource("temperature", temperatureFeatures(data))` +
  `FillLayer("temperature-fill")` with `fillColor(get("color"))`, opacity 0.42,
  `fillAntialias(false)`; numeric labels are pre-rendered `Bitmap` symbol icons
  (`temperatureLabel`), avoiding glyph endpoints. `clearWeatherLayers(style)` removes
  temperature/radar layers before re-adding (no layer accumulation).
- Temperature layer refresh is explicit (`updateTemperatures()` at Maps.kt:258).

## D. Memory & performance (bytecode-verified)

- **No third-party image library** (no Coil/Glide `ImageRequest`/`AsyncImage` markers in
  any app composable; `android.graphics.Bitmap` used only for map label rendering). The
  only bitmaps are small label icons, not forecast imagery.
- Tile/image memory lives in **MapLibre's renderer + the bounded 48 MiB OkHttp disk
  cache** — the app never holds its own unbounded tile cache. Eviction is the engine's.
- Coroutines are lifecycle-scoped: `repeatOnLifecycle(RESUMED)` for the 15-min loop
  (cancels with the lifecycle), `withContext(Dispatchers.IO)` for radar/temperatures
  (OWR.radar/temperatures decompiles), `withTimeoutOrNull(18000)` for location.
- No polling loops outside RESUMED scope; no global static caches in app code.
- Persistence writes are `AtomicFile` (crash-safe) and `SharedPreferences.apply()`
  (async, single flush per save).

## E. Data & persistence

- **Cities:** `SharedPreferences` key `"cities"` = JSON array of city objects
  (`DataCodec.cityJson`); dedupe by `City.id` on save. (OWR.saveCities decompile)
- **Forecast cache:** files `forecast-<cacheKey(city)>.json` in a repository directory,
  written/read via **`AtomicFile`** (temp-file + rename; `failWrite` rollback). Parse via
  `DataCodec.cachedForecast(JSONObject)`; any failure returns `null` (never crashes).
- **Cache pruning:** on every `saveCities`, all `forecast-*.json` files not belonging to
  a saved city are deleted — disk cache is exactly the saved-city set.
- **Network:** single `get` path with `IOException` handling; endpoints are
  Open-Meteo geocoding/forecast + RainViewer radar (per Data.kt / Maps.kt URLs above);
  `usesCleartextTraffic=false`, INTERNET + location permissions only.
- Units flag `imperial` persisted in SharedPreferences (`repository.imperial`).

## Limitations / missing evidence

- No runtime analysis was possible (no adb, no device/emulator): gesture timing,
  actual memory footprint, ANR/jetsam behavior and screenshot verification are NOT
  evidenced here. Everything above is static bytecode + shipped source.
- Decompiled method bodies are compiler-transformed; structural claims rely on marker
  counting and cross-check against the shipped source, which agree.
