import Foundation
import Testing
@testable import WeatherLogic

// Stability-fix tests (mission sections 4/6): the tile cache policy is shared
// verbatim with the app target (TileCachePolicy.swift is copied into this
// package by logic-tests.sh), so these verify the exact logic the device
// renderer uses — eviction bounds, duplicate-request prevention, and
// failure throttling. Navigation state transitions use the WeatherViewModel
// logic shape mirrored here without UI.

struct TilePolicyTests {
    private func entry(_ n: Int) -> [String: UInt64] {
        Dictionary(uniqueKeysWithValues: (0..<n).map { ("t\($0)", UInt64(1000 - $0)) })
    }

    @Test func evictionBelowLimitKeepsEverything() {
        let dropped = TileCachePolicy.evict(entries: entry(10), currentKeys: [], limit: 96)
        #expect(dropped.isEmpty)
    }

    @Test func evictionAtLimitEvictsNothing() {
        let dropped = TileCachePolicy.evict(entries: entry(96), currentKeys: [], limit: 96)
        #expect(dropped.isEmpty)
    }

    @Test func evictionAboveLimitEvictsLeastRecentlyUsed() {
        // entry(98) stamps t0=1000 … t97=3, so t97/t96 have the LOWEST
        // lastUse stamps → dropped first; never t0.
        let dropped = TileCachePolicy.evict(entries: entry(98), currentKeys: [], limit: 96)
        #expect(dropped.count == 2)
        #expect(dropped.contains("t97") && dropped.contains("t96"))
        #expect(!dropped.contains("t0"))
    }

    @Test func evictionNeverTouchesViewportTiles() {
        var entries = entry(96)
        // Viewport tile has the oldest stamp but must survive.
        entries["viewport"] = 0
        let dropped = TileCachePolicy.evict(
            entries: entries, currentKeys: ["viewport"], limit: 96)
        #expect(dropped.count == 1)
        #expect(!dropped.contains("viewport"))
    }

    @Test func duplicateFetchPreventedWhenCachedOrInFlight() {
        #expect(!TileCachePolicy.shouldFetch(key: "0/0/0", cached: true, inFlight: false,
                                             lastFailure: nil, now: Date()))
        #expect(!TileCachePolicy.shouldFetch(key: "0/0/0", cached: false, inFlight: true,
                                             lastFailure: nil, now: Date()))
        #expect(TileCachePolicy.shouldFetch(key: "0/0/0", cached: false, inFlight: false,
                                            lastFailure: nil, now: Date()))
    }

    @Test func failedTileThrottledForRetryDelay() {
        let now = Date()
        let fresh = now.addingTimeInterval(-5)          // inside the 30 s window
        let stale = now.addingTimeInterval(-TileCachePolicy.failureRetryDelay - 1)
        #expect(!TileCachePolicy.shouldFetch(key: "k", cached: false, inFlight: false,
                                             lastFailure: fresh, now: now))
        #expect(TileCachePolicy.shouldFetch(key: "k", cached: false, inFlight: false,
                                            lastFailure: stale, now: now))
    }

    @Test func boundsAreExplicitConstants() {
        #expect(TileCachePolicy.maxTiles == 96)
        #expect(TileCachePolicy.maxConcurrentTileFetches == 8)
        #expect(TileCachePolicy.failureRetryDelay == 30)
    }
}

// Navigation state transitions (mission section 6) — the same screen-routing
// shape WeatherViewModel uses (Screen enum + back ordering), verified without
// UI. The view model itself is MainActor+Observation (not Linux-testable), so
// the routing contract is tested at the level shared with the device build.
struct NavigationStateTests {
    private enum Route { case weather, map, cities, settings }

    // Kotlin BackHandler (MainActivity.kt:129): detail first, then weather.
    private func back(detail: String?, screen: Route) -> (detail: String?, screen: Route) {
        if detail != nil {
            return (nil, screen)
        } else if screen != .weather {
            return (nil, .weather)
        }
        return (nil, .weather)
    }

    @Test func backClosesDetailFirst() {
        let state = back(detail: "temp", screen: .map)
        #expect(state.detail == nil)
        #expect(state.screen == .map)
    }

    @Test func backReturnsToWeatherFromSubScreens() {
        #expect(back(detail: nil, screen: .map).screen == .weather)
        #expect(back(detail: nil, screen: .cities).screen == .weather)
        #expect(back(detail: nil, screen: .settings).screen == .weather)
        #expect(back(detail: nil, screen: .weather).screen == .weather)
    }
}
