# CODE_AUDIT.md — full repo audit (ponytail ruleset)

Method: [ponytail](https://github.com/DietrichGebert/ponytail) `ponytail-audit`
(v5.3.3, installed project-locally in `.pi/settings.json`). Order of importance:
correct, safe, holds under load, tested, fast, lean.

Scope: `05_ios_port/WeatheriOS` (5,943 Swift lines, app + support), plus
`07_tools/` and the test targets. The Kotlin original in
`00_original/source/Weather` was read as the behavioural reference, never as
code to audit.

**What this repo is:** an Android weather APK re-implemented natively in
SwiftUI. It fetches forecasts from Open-Meteo, geocoding from GeoNames, radar
frames from RainViewer, and draws its own slippy map with a disk tile cache.
**Assumed load:** one user, one device, interactive use — not a server. So
"scale" here means phone memory, disk and battery, not concurrent requests.

---

## Must fix

1. **The permission request could hang the button forever** (`Services/LocationFinder.swift:45-63`)
   - **What it is:** `ensureAuthorized()` waits for the "allow location?" dialog and reports the answer.
   - **Problem:** if a second call arrived while a dialog was already pending, the older waiter was
     resumed with `false`, the new continuation was stored **after** `lock.unlock()`, and
     `requestWhenInUseAuthorization()` was never called for it. Nothing would ever resume it: the
     button stays disabled and "Finding your location…" stays on screen until relaunch.
   - **Fix:** keep an array of waiters, always request once when the array was empty, resume every
     waiter from the single delegate callback. Done.
   - **If skipped:** a double tap on "Use my location" (or a slow dialog) permanently freezes the flow.

2. **The 18 s location timeout never fired** (`Services/LocationFinder.swift:66-88`)
   - **What it is:** `locateOnce()` races one GPS fix against an 18 s timer, like Kotlin's
     `withTimeoutOrNull(18_000)`.
   - **Problem:** `withTaskGroup` waits for *all* children before returning, and the fix child sat in
     `withCheckedContinuation` with no cancellation handling. The timer task returning nil changed
     nothing — the group kept waiting for a fix that a simulator or a tunnel may never deliver. A
     timed-out continuation also stayed in `locationContinuation` and was overwritten by the next
     attempt, leaking it.
   - **Fix:** resolve the continuation from `withTaskCancellationHandler`'s `onCancel`, and resolve a
     stale slot before replacing it. `testUseMyLocationTerminates` guards it.
   - **If skipped:** "Use my location" hangs indefinitely offline; the app looks frozen.

## Should fix

3. **Every tile write re-sorted the whole disk cache index** (`Models/DiskTileCache.swift:store`)
   - **What this is:** the map's 48 MiB tile cache, evicted least-recently-used when over budget.
   - **Problem:** `store()` called `evictIfNeeded` after **every** tile, which built an array of every
     index entry and sorted it — O(n log n) per tile while panning, with the index holding thousands
     of tiles. Most of that work concluded "nothing to do".
   - **Fix:** keep a running `totalBytes` and only run the eviction pass when it exceeds the budget.
     Done.
   - **If skipped:** janky panning on a warm cache (the exact screen that used to watchdog).

4. **Mislabelled city identity** (`Repositories/OpenWeatherRepository.swift:search`)
   - **Problem:** GeoNames returns `id` as a JSON **number**. `row["id"] as? String` failed, so every
     city fell back to `"\(lat),\(lon)"` as its id — different identity than Android's
     `optString("id")`, and it makes ids depend on float formatting.
   - **Fix:** stringify the number like `optString` does. Done.

5. **Debug-only screens shipped in the binary** (`Views/NavTestView.swift`, `Views/ForecastIsolationView.swift`, 283 lines)
   - **Problem:** a navigation self-test and a scroll-isolation harness — written to prove framework
     behaviour during the debugging missions — compiled into every build, reachable from Diagnostics.
   - **Fix:** wrapped in `#if DEBUG`, with their entry points in `DiagnosticsScreenView`. Done.
   - **Note:** `DiagnosticsScreenView` itself (273 lines) is still shipped; it is the only way to read
     the on-device session log, so it stays.

6. **Dead code** (`Views/WeatherMapView.swift:52` `legacyCartoBasemapTile`)
   - Kept "for reference" after the CARTO basemap was replaced. Nothing referenced it. Deleted.

## Nice to have

7. Search dedupes `admin1`/`country` with `contains` inside a loop, and `saveCities` dedupes with a
   nested `contains`. Both are O(n²) over lists of ≤12 cities — correct today, not worth the code
   to change.

8. `DiagLog.record` flushes synchronously to disk on the calling thread (one open/write/close per
   event). Deliberate: the file must survive a watchdog kill. 60 call sites, none per frame, so the
   cost does not show; revisit only if events move into a render loop.

---

## Checked and found healthy

- **No secrets, no third-party SDKs, no analytics.** All endpoints HTTPS; the only network code is
  `OpenMeteoClient`. The geocoding query goes through `URLComponents`, so user text is escaped.
- **Cache keys cannot escape their directory:** tile keys strip `/` and `:`, and forecast cache names
  are float bit patterns. No path traversal, no unbounded growth — grid cache keeps 12 files, diag
  logs keep 3, tiles are byte-bounded.
- **Structured concurrency:** the air-quality side fetch is a structured child (`async let`); the
  earlier unstructured `Task` that outlived cancellation is gone.
- **Timezone handling** checks the raw zone against the IANA database and falls back to UTC; daily
  buckets use the provider's `utc_offset_seconds`, matching the Kotlin comment.
- **Error paths:** a failed refresh never replaces a good cached forecast; radar falls back to a
  snapshot younger than 2 h.

## Not checked

- `Views/WeatherMapView.swift` (1,139 lines) was read for fetch/eviction/render paths, not line by
  line for the drawing math.
- No device profiling: the speed findings rest on code reading, not Instruments traces.
- `LocationFinder` behaviour on a real device with a denied permission was not exercised; only the
  granted path runs in the simulator.

**Verdict:** healthy after findings 1–6. Fix 1 and 2 first — they are the two that freeze the app.
**Lean:** −290 lines (debug screens gated, dead tile helper), −0 dependencies.
