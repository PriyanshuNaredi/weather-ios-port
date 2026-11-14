# CRASH-ANALYSIS.md — Weather iOS (fix mission 2026-11-13)

## Scope and honesty statement

**No physical-device runtime logs were available for this mission** (no device
access is permitted under the mission restrictions: no signing, no
provisioning, no device registration, no usbmuxd). Therefore **no root cause of
the on-device termination has been proven from runtime evidence**. What follows
is a **static, evidence-based defect audit** of the port's source (against the
Kotlin reference `MainActivity.kt` @ 6267da88), with every defect fixed in this
build. The build itself carries a **crash-evidence capture channel** (DiagLog
session files, below) that will record the actual abnormal-termination log on
the next device run — that log is the input a future root-cause analysis needs.

## Evidence: static defects found and fixed (all reproduce from source, not speculation)

| # | Defect (static evidence) | Why it can crash / break the device | Fix (this build) |
|---|---|---|---|
| 1 | `try? await Task.sleep` inside `while true` loops (ForecastPageView 15-min retry; DiagnosticsScreenView 1 s refresh) — `try?` swallows `CancellationError`, so the loop never exits. Leaked loops accumulate **per city page** and stay alive for the app's lifetime | Each navigation round leaks another never-ending task; combined with per-page fetches this is a monotonic memory/task growth pattern — a jetsam-termination candidate | Cancel-correct pattern: `while !Task.isCancelled { do { try await Task.sleep } catch { break } ... }`; covered by `CancellationLoopTests.testTimerLoopExitsOnCancellation` |
| 2 | Pager triple-identity mismatch: `ForEach(cities)` element ids + `.id(index)` + `scrollPosition(id: Int)` = two competing identity systems fighting user drags | Broken/unreliable paging; stale binding callbacks with out-of-range indices (crash-adjacent) | Single identity system: `ForEach(cities.indices, id: \.self)`, no `.id()` modifier |
| 3 | `pagerMoved(to:)` accepted unclamped indices | A stale scrollPosition callback after city removal sets `currentIndex` out of range → array out-of-bounds | `PagerIndexPolicy.clamp` (logic-tested) + Diag event on clamp |
| 4 | Force-unwraps `snapshot!` in tap closures (hourly/tiles/daily rows) | Tap during a re-render window → nil unwrap → crash | `guard let snapshot` everywhere |
| 5 | Hourly strip `ForEach(id: \.time)` — synthesized "Now" hour can duplicate a real hour id | Duplicate ForEach ids → SwiftUI undefined behavior/crash risk | `Array(hours.enumerated()), id: \.offset` |
| 6 | Unstructured `Task { }` air-quality fetch inside `forecast()` — never cancelled when the parent fails/cancels | Orphaned network tasks accumulate | Structured `async let` |
| 7 | `.simultaneousGesture(DragGesture(minimumDistance: 25))` diagnostic monitor sat on top of the paging ScrollView | Intercepted/interfered with vertical scroll drags | Removed (diagnostics now via Diag events + self-test screens) |
| 8 | Diagnostics screen unreachable after a termination — in-memory only | No evidence of what happened before a crash/jetsam | DiagLog **disk session files**: per-session `session-<unixtime>.log`, clean-end marker via `markSessionClean` (wired to scenePhase), previous-session abnormal-end report shown on next launch. Session-begin drains pending writes **synchronously** and filenames are collision-proof (same-second relaunches get `-N` suffixes); event writes are synchronous so a kill right after an event cannot lose the line. Privacy: events never contain coordinates or city names |
| 9 | `barButton` label lacked a hit-area shape | Buttons "dead" despite correct routing logic | `.contentShape(Rectangle())` |

## What would count as a proven root cause

The next device run with this IPA: open Diagnostics screen → note the
"PREVIOUS SESSION — ABNORMAL END" panel (or use "Copy previous session"). That
text is the actual pre-termination Diag trail. If the app terminates **before**
any diagnostic can be seen, the session file on disk (Application Support/
weather-diag/) holds the same trail and can be pulled from the device
by the user (no tooling on our side required). **Until then: no runtime root
cause is claimed.**

## Falsifiable claim

If the on-device termination is caused by defect class #1 (leaked
cancellation-immune loops), the fix removes the growth pattern; if it is
something else (e.g. watchdog on main-thread stall), the DiagLog channel will
show it in the abnormal-session text. Either way the next run produces evidence
rather than guesswork.
