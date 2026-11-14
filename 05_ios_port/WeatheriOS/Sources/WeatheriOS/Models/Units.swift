import Foundation

// iOS port of the formatting helpers in `Models.kt`.
// Semantics preserved: nil renders as "—"; temp appends "°" only for non-nil values;
// speed always appends the unit; imperial conversions match the Kotlin constants.

extension Double? {
    /// Kotlin `Double?.display(decimals)` — US locale fixed-decimal or "—".
    func display(decimals: Int = 0) -> String {
        guard let self else { return "—" }
        return String(format: "%.\(decimals)f", locale: Locale(identifier: "en_US"), self)
    }
}

/// Kotlin `display` is defined on `Double?` but also called on plain `Double`
/// values (e.g. MainActivity.kt:328 `it.display()`); this forwards to the
/// optional overload.
extension Double {
    func display(decimals: Int = 0) -> String {
        (self as Double?).display(decimals: decimals)
    }
}

func temp(_ value: Double?, imperial: Bool = false) -> String {
    (value.map { imperial ? $0 * 9 / 5 + 32 : $0 }).display() + (value == nil ? "" : "°")
}

func speed(_ value: Double?, imperial: Bool) -> String {
    (value.map { imperial ? $0 / 1.609344 : $0 }).display() + (imperial ? " mph" : " km/h")
}

/// Kotlin `localTime(epoch, zone, pattern)` — formats an epoch second in the city's zone.
/// `DisplayClock.pattern` ("HH:mm") becomes the default format parameter.
///
/// macOS-build fix: this used to build a fresh `DateFormatter` per call, and it
/// is called per item — 48 hourly labels per layout pass, plus the radar frames.
/// Sampled live, the main thread was inside `NSDateFormatter.__allocating_init`
/// from `hourLabel`, which starved the UI for tens of seconds (XCTest's
/// accessibility snapshot timed out). Formatters are now cached per
/// (pattern, zone); `DateFormatter` is only mutated between calls, never while
/// formatting, and the cache is lock-guarded because lookups can come from
/// background projections too.
private let localTimeFormatters = NSMutableDictionary()
private let localTimeFormattersLock = NSLock()

func localTime(_ epoch: Int, zone: String, pattern: String = "HH:mm") -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(epoch))
    let zoneID = TimeZone(identifier: zone) != nil ? zone : "UTC"
    let cacheKey = pattern + "|" + zoneID

    localTimeFormattersLock.lock()
    let cached = localTimeFormatters.object(forKey: cacheKey) as? DateFormatter
    localTimeFormattersLock.unlock()

    if let cached {
        cached.locale = Locale(identifier: "en_US")
        return cached.string(from: date)
    }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = pattern
    // Kotlin falls back to UTC when the zone id is invalid.
    formatter.timeZone = TimeZone(identifier: zoneID) ?? TimeZone(identifier: "UTC")

    localTimeFormattersLock.lock()
    localTimeFormatters.setObject(formatter, forKey: cacheKey as NSString)
    localTimeFormattersLock.unlock()

    return formatter.string(from: date)
}
