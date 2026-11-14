import Testing
@testable import WeatherLogic

// Parity regression tests (REA mission, ANDROID_IOS_PARITY.md §6). Ground
// truth: Android HorizontalPager keyed by city id (MainActivity.kt:144),
// currentIndex fed from pager.currentPage (line 104), bottom bar as a layout
// sibling, and the 48 MiB map disk cache (Maps.kt:81). All policies here are
// pure so they run in the Linux logic package.

@Suite("Pager page identity (parity)")
struct PagerIdentityTests {
    let cities = [
        City(id: "a", name: "A", country: "", latitude: 0, longitude: 0, timezone: ""),
        City(id: "b", name: "B", country: "", latitude: 0, longitude: 0, timezone: ""),
        City(id: "c", name: "C", country: "", latitude: 0, longitude: 0, timezone: ""),
    ]

    @Test func idIndexRoundTrip() {
        for (i, city) in cities.enumerated() {
            #expect(PagerPagePolicy.index(for: city.id, in: cities) == i)
            #expect(PagerPagePolicy.pageID(at: i, in: cities) == city.id)
        }
    }

    @Test func unknownIDMapsToNil() {
        #expect(PagerPagePolicy.index(for: "missing", in: cities) == nil)
    }

    @Test func outOfRangeIndexMapsToNil() {
        #expect(PagerPagePolicy.pageID(at: -1, in: cities) == nil)
        #expect(PagerPagePolicy.pageID(at: 3, in: cities) == nil)
    }

    @Test func identityFollowsCityNotPosition() {
        // Removing a city shifts indices but the id→page mapping still resolves
        // each surviving city to its (new) page — Android key semantics.
        let after = Array(cities.dropFirst())
        #expect(PagerPagePolicy.index(for: "b", in: after) == 0)
        #expect(PagerPagePolicy.index(for: "c", in: after) == 1)
        #expect(PagerPagePolicy.index(for: "a", in: after) == nil)
    }

    @Test func emptyListMapsToNilBothWays() {
        #expect(PagerPagePolicy.index(for: "a", in: []) == nil)
        #expect(PagerPagePolicy.pageID(at: 0, in: []) == nil)
    }
}

@Suite("Disk cache policy (parity, 48 MiB)")
struct DiskCachePolicyTests {
    @Test func budgetIs48MiB() {
        #expect(TileCachePolicy.maxDiskBytes == 48 * 1024 * 1024)
    }

    @Test func underBudgetEvictsNothing() {
        let entries: [(key: String, size: Int, stamp: UInt64)] = [
            ("a", 100, 1), ("b", 200, 2),
        ]
        #expect(TileCachePolicy.evictDisk(entries: entries, protected: [], budgetBytes: 1024) == [])
    }

    @Test func overBudgetEvictsLeastRecentlyUsedFirst() {
        let entries: [(key: String, size: Int, stamp: UInt64)] = [
            ("old", 600, 1), ("mid", 600, 2), ("new", 600, 3),
        ]
        // Budget 1500 of 1800 bytes → 300 over → evict oldest until fit.
        let evicted = TileCachePolicy.evictDisk(entries: entries, protected: [], budgetBytes: 1500)
        #expect(evicted == ["old"])
    }

    @Test func protectedTilesNeverEvicted() {
        let entries: [(key: String, size: Int, stamp: UInt64)] = [
            ("protected-old", 600, 1), ("new", 600, 2),
        ]
        let evicted = TileCachePolicy.evictDisk(
            entries: entries, protected: ["protected-old"], budgetBytes: 0)
        #expect(!evicted.contains("protected-old"))
        #expect(evicted == ["new"])
    }

    @Test func evictionContinuesUntilBudgetFits() {
        let entries: [(key: String, size: Int, stamp: UInt64)] = [
            ("k1", 1000, 1), ("k2", 1000, 2), ("k3", 1000, 3),
        ]
        let evicted = TileCachePolicy.evictDisk(entries: entries, protected: [], budgetBytes: 1200)
        #expect(evicted == ["k1", "k2"])
    }

    @Test func oversizedUnprotectedEntryIsEvictable() {
        // One entry bigger than the whole budget self-heals instead of pinning.
        let entries: [(key: String, size: Int, stamp: UInt64)] = [("huge", 100, 9)]
        #expect(TileCachePolicy.evictDisk(entries: entries, protected: [], budgetBytes: 50) == ["huge"])
    }
}

@Suite("Navigation destinations (parity)")
struct ScreenReachabilityTests {
    // Parity: Android `when(screen)` covers "weather"/"map"/"cities"/"settings"
    // and the iOS barButton routes raw strings through Screen(rawValue:).
    // These assertions pin the raw values the bottom bar depends on.
    @Test func screenRawValuesResolve() {
        #expect(Screen(rawValue: "weather") == .weather)
        #expect(Screen(rawValue: "map") == .map)
        #expect(Screen(rawValue: "cities") == .cities)
        #expect(Screen(rawValue: "settings") == .settings)
    }

    @Test func allBarDestinationsAreDistinct() {
        let screens: [Screen] = [.weather, .map, .cities, .settings]
        #expect(Set(screens.map(\.rawValue)).count == 4)
    }
}
