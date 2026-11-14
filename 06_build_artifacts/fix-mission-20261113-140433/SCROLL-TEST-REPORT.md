# SCROLL-TEST-REPORT.md — Weather iOS (fix mission 2026-11-13)

## What was built (mission Phase 4 requirement)

`ForecastIsolationView` — an isolated forecast-scroll test screen reachable
from the Diagnostics screen ("Scroll self-test" button):

- 3-page horizontal pager built **exactly like the app's weatherPager**:
  `ScrollView(.horizontal)` + `LazyHStack` + `.scrollTargetLayout()` +
  `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)` bound to an
  `Int` `@State`, with a **single identity system**
  (`ForEach(indices, id: \.self)`, no `.id()` modifier).
- Each page contains a **vertical ScrollView with 60 tappable rows**, proving
  vertical touch scrolling works inside a horizontally-paging container.

## Defects fixed in the real forecast screen

| Defect | Fix |
|---|---|
| Pager triple-identity mismatch (element ids + `.id(index)` + `scrollPosition(id:)`) — the two identity systems fight drags, making daily-forecast scrolling unreliable | Single `Int` identity: `ForEach(cities.indices, id: \.self)` |
| `.simultaneousGesture(DragGesture(minimumDistance: 25))` monitor on the forecast page intercepted vertical drags | Removed entirely |
| `.task { while true { try? await Task.sleep… } }` 15-min retry loop never exits on cancellation (one leaked loop per page visit) | `while !Task.isCancelled` + do/catch break |
| Ten-day rows / hourly strip reachable only while identity stayed stable; duplicate hour ids risked broken rows | Enumerated-offset ids; tap closures `guard let snapshot` |
| Out-of-range `pagerMoved` indices after city removal | `PagerIndexPolicy.clamp` (logic-tested) |

## Verification performed — and its limits

| Check | Type | Result |
|---|---|---|
| Range-band geometry (`RangeSpan.band`) incl. degenerate/min-width/fallback cases | Host-side automated logic tests (Linux) | **PASS** (4 RangeSpanTests + 19 ProjectionTests) |
| Pager index clamping incl. stale-index and zero-city cases | Host-side automated logic tests | **PASS** (4 PagerIndexTests) |
| Forecast data ordering / projection | Host-side automated logic tests | **PASS** (ProjectionTests) |
| Isolation screen compiles with the same scroll-target stack as the app | ARM64 iOS build | Compiled |
| Vertical touch scrolling, hourly strip reachability, range-bar rendering, horizontal paging on an actual touchscreen | **Device test** | **NOT PERFORMED** — no device access permitted |

**No touchscreen/device scroll verification has been performed.** The isolation
screen exists so the user's device run can verify scrolling independently of
weather data: open Diagnostics → "Scroll self-test" → page horizontally 3
pages, scroll each page vertically, tap rows. Then repeat inside the full
weather app.
