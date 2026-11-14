import Foundation

// iOS port of `MainActivity.kt:314-348` — the Metric enum, the per-tile value /
// summary strings, and the label helpers (uvLabel, aqiLabel, compass, isDayAt).
// Every conversion and user-facing string traces to the Kotlin source.

/// Kotlin `Metric` (MainActivity.kt:314-318). The 11 titles/wording are exact.
enum Metric: String, CaseIterable, Identifiable {
    case temperature = "Temperature"
    case feels = "Feels like"
    case rain = "Precipitation"
    case wind = "Wind"
    case humidity = "Humidity"
    case dew = "Dew point"
    case uv = "UV index"
    case visibility = "Visibility"
    case pressure = "Pressure"
    case sun = "Sunrise & sunset"
    case air = "Air quality"

    var id: String { rawValue }

    /// Kotlin `Metric.icon` material icon mapped to the closest SF Symbol.
    var iconName: String {
        switch self {
        case .temperature: return "thermometer"
        case .feels: return "person"
        case .rain: return "drop"
        case .wind: return "wind"
        case .humidity: return "humidity"
        case .dew: return "drop"
        case .uv: return "sun.max"
        case .visibility: return "eye"
        case .pressure: return "gauge"
        case .sun: return "sunset"
        case .air: return "aqi.medium"
        }
    }

    /// Kotlin `MetricScreen` date-filter parameter (`Metric.selectedDate`,
    /// MainActivity.kt:316-317). The static-side channel in Compose becomes an
    /// explicit parameter here.
    func copyForDate(_ date: String?) -> (Metric, String?) { (self, date) }
}

/// Kotlin `nearest(w)` (MainActivity.kt:319).
func nearest(_ w: Weather) -> Hour? {
    forecastHourAt(w, now: w.current.time)
}

/// Kotlin `metricValue` (MainActivity.kt:320-332) — exact conversion factors and
/// unit strings.
func metricValue(_ m: Metric, _ w: Weather, _ imperial: Bool) -> String {
    let h = nearest(w)
    switch m {
    case .temperature: return temp(w.current.temperature, imperial: imperial)
    case .feels: return temp(w.current.feelsLike, imperial: imperial)
    case .rain:
        guard let mm = w.days.first?.precipitation else { return "—" }
        return imperial ? "\((mm / 25.4).display(decimals: 2)) in" : "\(mm.display(decimals: 1)) mm"
    case .wind: return speed(w.current.wind, imperial: imperial)
    case .humidity: return w.current.humidity.map { "\($0.display())%" } ?? "—"
    case .dew: return temp(h?.dewPoint, imperial: imperial)
    case .uv: return (w.days.first?.uv).display(decimals: 1)
    case .visibility:
        guard let meters = h?.visibility else { return "—" }
        let divisor = imperial ? 1609.344 : 1000.0
        return "\((meters / divisor).display(decimals: 1)) \(imperial ? "mi" : "km")"
    case .pressure:
        guard let hpa = w.current.pressure else { return "—" }
        return imperial ? "\((hpa * 0.029529983).display(decimals: 2)) inHg" : "\(hpa.display()) hPa"
    case .sun: return w.days.first?.sunset.map { localTime($0, zone: w.timezone) } ?? "—"
    case .air: return (w.air?.europeanAqi).display()
    }
}

/// Kotlin `metricSummary` (MainActivity.kt:333-345) — exact strings.
func metricSummary(_ m: Metric, _ w: Weather, _ imperial: Bool) -> String {
    switch m {
    case .temperature:
        return "Today’s high \(temp(w.days.first?.high, imperial: imperial)). Tap to explore the forecast."
    case .feels:
        return "Apparent temperature combines temperature, humidity and wind."
    case .rain:
        let chance = w.days.first?.precipitationProbability.display() ?? (nil as Double?).display()
        return "Today’s total. Chance \(chance)%."
    case .wind:
        return "Gusts \(speed(w.current.gusts, imperial: imperial)) · \(compass(w.current.windDirection))"
    case .humidity:
        return "Relative humidity near ground level."
    case .dew:
        return "Temperature at which air becomes saturated."
    case .uv:
        return "Today’s peak · \(uvLabel(w.days.first?.uv))"
    case .visibility:
        return "Model estimate of horizontal visibility."
    case .pressure:
        return "Atmospheric pressure at sea level."
    case .sun:
        let sunrise = w.days.first?.sunrise.map { localTime($0, zone: w.timezone) } ?? "unavailable"
        return "Sunset · Sunrise \(sunrise)"
    case .air:
        if w.air == nil { return "Air-quality data unavailable for this location." }
        return "European AQI · \(aqiLabel(w.air?.europeanAqi))\nModel estimate, not a local sensor."
    }
}

/// Kotlin `uvLabel` (MainActivity.kt:346).
func uvLabel(_ v: Double?) -> String {
    switch v {
    case nil: return "Unavailable"
    case let x?: 
        if x < 3 { return "Low" }
        if x < 6 { return "Moderate" }
        if x < 8 { return "High" }
        if x < 11 { return "Very high" }
        return "Extreme"
    }
}

/// Kotlin `aqiLabel` (MainActivity.kt:347).
func aqiLabel(_ v: Double?) -> String {
    guard let v else { return "Unavailable" }
    if v <= 20 { return "Good" }
    if v <= 40 { return "Fair" }
    if v <= 60 { return "Moderate" }
    if v <= 80 { return "Poor" }
    if v <= 100 { return "Very poor" }
    return "Extremely poor"
}

/// Kotlin `compass` (MainActivity.kt:348) — 8-point wind rose, wrapping mod 8.
func compass(_ v: Double?) -> String {
    guard let v else { return "Direction unavailable" }
    let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    let index = Int((v / 45).rounded()) % 8
    return names[((index % 8) + 8) % 8]
}

/// Kotlin `isDayAt` (MainActivity.kt:349) — sunrise..sunset of the matching
/// calendar day, else the snapshot's current is_day flag.
func isDayAt(time: Int, w: Weather) -> Bool {
    let day = w.days.first { $0.date == LocalDateKeys.dateKey(epoch: time, zone: w.timezone) }
    if let sunrise = day?.sunrise, let sunset = day?.sunset {
        return time >= sunrise && time <= sunset
    }
    return w.current.isDay
}
