import Foundation

// Pure policy helpers extracted from the crash/navigation/scroll mission fixes
// so the Linux logic-test package can test them (Foundation-only, no SwiftUI).

/// Screen routing — Kotlin `MainActivity.kt` screen string state + BackHandler.
/// The bottom bar routes raw strings through `Screen(rawValue:)`; the parity
/// tests pin those raw values.
enum Screen: String {
    case weather, map, cities, settings
}

/// Pager index clamping (used by `WeatherViewModel.pagerMoved`). A stale
/// `scrollPosition` binding can fire after city removal with an out-of-range
/// index; clamping keeps the current page a valid index.
enum PagerIndexPolicy {
    static func clamp(_ index: Int, count: Int) -> Int {
        min(max(index, 0), max(count - 1, 0))
    }
}

/// Pager page identity (parity: Android keys `HorizontalPager` pages by city
/// id, `key={cities[it].id}`, MainActivity.kt:144 — page state survives
/// add/remove/reorder because the key follows the city). The pager's
/// `scrollPosition` binding speaks city ids; the view model's `currentIndex`
/// is derived from the reported id via `index(for:)`, and `pageID(at:)`
/// converts back for programmatic scrolls. Nothing here mirrors state — both
/// directions are pure functions of the cities list.
enum PagerPagePolicy {
    /// Page index for a city id; nil when the id is not present.
    static func index(for id: String, in cities: [City]) -> Int? {
        cities.firstIndex { $0.id == id }
    }

    /// City id of the page at `index`; nil when the index is out of range.
    static func pageID(at index: Int, in cities: [City]) -> String? {
        cities.indices.contains(index) ? cities[index].id : nil
    }
}

/// Range-bar band geometry (used by `RangeBar`'s Canvas). Returns the band's
/// left/right fractions of the track width; the band is never thinner than
/// `minBandFraction`, and degenerate ranges (max - min <= 0) fall back to the
/// same fallback span the Kotlin Canvas used.
enum RangeSpan {
    static let minBandFraction = 0.02

    /// nil when either endpoint is missing (Kotlin: draw track only).
    static func band(low: Double?, high: Double?, min: Double, max: Double) -> (left: Double, right: Double)? {
        guard let low, let high else { return nil }
        let range = Swift.max(max - min, 1.0)
        let left = (low - min) / range
        let right = Swift.max((high - min) / range, left + Self.minBandFraction)
        return (left, right)
    }
}
