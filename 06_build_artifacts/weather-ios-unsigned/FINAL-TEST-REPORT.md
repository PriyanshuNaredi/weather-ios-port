# FINAL TEST REPORT — Runtime Debugging Mission (2026-11-13)

Build: `Weather-unsigned-FINAL-20261113-133010.ipa` (SHA-256 `3b399e…82782d`, see FINAL-IPA-VERIFICATION.md)

## What this build is
A **diagnostic build**: it contains full DEBUG instrumentation (Phase 1) plus the previous
stability fixes, and diagnostic configurations A–E (Phase 4). The instrumentation is temporary
by design and will be removed after the device issues are resolved. **No speculative code
changes were repeated** — per instruction, this build's purpose is to establish the actual
runtime failure with evidence, not to claim fixes.

## Instrumentation shipped (all privacy-scrubbed: counts, timings, screen names only — no coordinates, no city names)
- Launch: `app init (diagnostic build)`
- Scene lifecycle: `scenePhase -> …` with phys_footprint (jetsam's counter)
- `MEMORY WARNING` + footprint (UIApplication.didReceiveMemoryWarningNotification)
- Main view lifecycle; every bottom-bar tap (`nav bottom-bar tap -> map|settings|cities`)
- All navigation transitions (`nav screen -> …`, pager moves, back, metric open, city add/remove, unit toggle, location tap)
- Forecast: page appear/disappear, content rendered (`days=N tiles=7`), load success/failure/cache-skip, **scroll drag detected** (simultaneous DragGesture ≥25pt, once per gesture)
- Tiles: per-batch fetch stats (namespace, count, cached) and eviction stats
- Radar: timeline loaded/failed (frames=N), each animation frame, play/pause, layer switches, map drag
- Output channels: os.Logger (`subsystem dev.kiankonrad.weather`, category `stability`) **and** an in-app ring buffer (600 events, oldest-drop counted) shown on the new Diagnostics screen (ⓘ button in the bottom bar) with Copy / Share / Clear.

## Diagnostic configurations (Diagnostics screen presets)
| Preset | Forecast | Map previews | Radar |
|---|---|---|---|
| A | ✅ | ❌ | — |
| B | ✅ | ✅ | — |
| C | ✅ | ✅ | ❌ |
| D | ✅ | ✅ | ✅ |
| E | ✅ | ✅ | ✅ (full app, defaults) |

Nothing was permanently removed — map previews and radar are gated by persisted toggles only.

## Test results (Linux, Foundation-only logic — NOT device runtime proof)
- `logic-tests-20261113-132124.log`: XCTest **41/41 passed**; Swift Testing **15/15 passed**
  (TilePolicyTests 7 — tile-cache eviction policy, NavigationStateTests 2 — screen routing,
  DiagLogTests 6 — new ring-buffer capacity/drop/clear/export/monotonic-time tests)
- Total **56/56, exit 0**
- Full iOS app compiled for arm64 in this build (`package-20261113-132830.log`, exit 0 after
  fixing the `scenePhase` onChange closure arity noted in FINAL-IPA-VERIFICATION.md)

## Honest standing conclusion
**No runtime cause for the scroll break, dead buttons, or termination is provable statically.**
Linux tests do not exercise SwiftUI hit-testing, paging scroll, MapKit/tile rendering, or the
jetsam/memory subsystems. The two earlier builds failed on device and per instruction no
further speculative fixes were made. The evidence below is REQUIRED to proceed to a real fix.

## EVIDENCE NEEDED FROM YOU (exact checklist)
1. **Crash / jetsam report** (distinguishes "crashed" from "killed by memory"):
   iPhone: Settings → Privacy & Security → Analytics & Improvements → Analytics Data →
   look for `WeatheriOS-2026-…-.ips` files, share their content.
   Or connect to a Mac and copy from Console.app device log (no Xcode needed).
2. **Live Console.app capture**: Mac Console.app → select your iPhone → search
   `dev.kiankonrad.weather` (subsystem). Record 2–3 minutes while: launching, scrolling the
   daily forecast, tapping each of map / cities / settings.
3. **In-app diagnostics log** (works without a Mac): open app → tap the **ⓘ button in the
   bottom bar** → Copy (or Share) the diagnostic log. Do this once per run; if the app dies,
   note at which moment.
4. **Per-configuration repro**: run the app under presets A → B → C → D → E (set on the
   Diagnostics screen) and note for each: does scrolling work? do map/cities/settings buttons
   work? does it terminate? If scrolling works at A but not B, the map-preview tiles are the
   trigger; if D but not E differs, radar animation is implicated. Export/copy the log after
   each configuration.
5. **Device model + iOS version** of the test device.

With items 1–4 the failure mode becomes identifiable: hit-testing interception (buttons dead
but taps logged as fired or not at all), SwiftUI paging-scroll regression (drag events present
but content doesn't move), or jetsam (MEMORY WARNING + footprint trend before termination).
