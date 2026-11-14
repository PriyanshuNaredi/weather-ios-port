# MEMORY_AND_UI_FINDINGS.md — Memory & UI findings (Android ground truth vs iOS)

Mission §4-D + §5 focus areas. Evidence: REA decompiles (marker counts in
ORIGINAL_APK_DEEP_ANALYSIS.md), shipped source, and the iOS port sources.

## Memory model (Android, bytecode-verified)

| Item | Android fact | iOS port today | Gap |
|---|---|---|---|
| Tile images | MapLibre renderer owns them; app holds NO tile bitmaps. HTTP layer caches to **48 MiB disk** (`cacheDir/map-http`) — survives restart | `TileCachePolicy` LRU, **96 tiles ≈ 25 MB, memory only**; no disk cache | iOS refetches all tiles after relaunch/leave-reenter; Android never does |
| Image/bitmap churn | No Coil/Glide; the only `Bitmap` creation is tiny map label icons (`temperatureLabel`) | No image lib; tile PNG decode via `Task.detached` (post-fix) | Parity |
| Coroutines | 15-min loop under `repeatOnLifecycle(RESUMED)` — cancels automatically; radar/temperatures on `Dispatchers.IO`; `CancellationException` rethrown everywhere | Structured Tasks; cancel-correct loops after 140433 fix; structured `async let` for air quality | Parity post-fix |
| Cache write safety | `AtomicFile` startWrite/finishWrite/failWrite | `.atomic` FileManager writes | Parity |
| Cache GC | Forecast cache = exactly the saved-city set (pruned every saveCities) | Same prune on saveCities | Parity |
| Map memory under pressure | MapView explicitly `onPause/onStop` when off-screen; renderer frees tiles itself | scenePhase hooks + cancel on disappear | Parity |

**Net:** the only material memory divergence is the missing disk tile cache. The
earlier iOS refetch loop (TileLayer `.id(cacheTick)` bug) has been fixed; a disk cache
is the remaining structural advantage Android holds against memory pressure.

## UI findings (what Android actually guarantees)

1. **Bottom bar is structurally protected.** It is a layout sibling (Row after pager),
   never an overlay; screens fully replace content via `when`. Any iOS design that
   overlays the bar must reproduce this guarantee explicitly.
2. **Pager identity = city id.** Add/remove/reorder of cities never rebinds page state.
   `currentIndex` is derived from `pager.currentPage` — one source of truth.
3. **One vertical scroller per forecast page.** The only other scroller is the hourly
   `Row(horizontalScroll)`; pager owns horizontal drags. No Lazy* on the forecast page
   (LazyColumn only on the city search screen).
4. **Pull-to-refresh is platform-native** (`PullToRefreshBox`) — iOS has no equivalent
   yet (minor UX gap, not a defect).
5. **Dots reflect pager state**, not app state: `pager.currentPage` highlights; tapping
   dots isn't a feature (they're not interactive on Android either).
6. **`rememberSaveable` on `screen`** — screen survives process death; the iOS port
   keeps screen in an in-memory view model and would relaunch on the weather screen
   after process death (parity gap worth noting, low priority).
7. **Back handling order:** detail → weather → system. iOS `back()` matches.
8. **Compact layout** adapts to `screenHeightDp < 500` and font scale; iOS has no
   compact variant (gap for small devices/Dynamic Type).
9. **Map error UX:** "Map could not load. Check your connection." + tile error
   surfacing + retry; iOS ports this message (parity verified earlier).
10. **Estimated-now card** ("Estimated now · … · From saved hourly forecast ·
    Downloaded …") distinguishes ConditionSource FORECAST/UNAVAILABLE/CURRENT —
    iOS implements the same distinction (DataCodec port tested).

## Runtime evidence still missing (both platforms)

- Android: no adb/device — no logcat, hierarchy dump, memory trace, screenshots.
- iOS: pending user-supplied device crash/jetsam reports, Console capture, and
  diagnostics exports A–E (listed in FINAL-TEST-REPORT.md).
- All claims above are static; nothing here is a device-verified root cause.
