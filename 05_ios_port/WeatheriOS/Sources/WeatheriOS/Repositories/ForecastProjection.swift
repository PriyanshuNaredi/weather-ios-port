// iOS port of `ForecastProjection.kt` (verbatim logic port; pure, no platform APIs
// beyond Foundation date/time — mirrors the Kotlin leaf-pure constraint).

import Foundation

/// Describes the data used for a display instant, not the device's connectivity.
enum ConditionSource {
    case current
    case forecast
    case unavailable
}

/// Evaluate this on the original provider snapshot, before applying `atTime`.
func conditionSourceAt(_ weather: Weather, now: Int) -> ConditionSource {
    if (0...900).contains(now - weather.current.time) { return .current }
    if forecastHourAt(weather, now: now) != nil { return .forecast }
    return .unavailable
}

/// Project a saved provider response onto the display clock without making it look
/// freshly fetched. Interpolation stays between adjacent hourly samples; it never
/// bridges a missing hour or extends the forecast beyond its final sample. Codes use
/// the containing hour, not a numeric interpolation.
func atTime(_ weather: Weather, now: Int) -> Weather {
    let source = conditionSourceAt(weather, now: now)
    let hour = source == .forecast ? forecastHourAt(weather, now: now) : nil
    var projected: Conditions
    switch source {
    case .current:
        projected = weather.current
        projected.time = now
    case .forecast:
        projected = Conditions(
            time: now, temperature: hour?.temperature, feelsLike: hour?.feelsLike,
            code: hour?.code, isDay: daylightAt(weather, now: now),
            humidity: hour?.humidity, wind: hour?.wind, gusts: hour?.gusts,
            windDirection: hour?.windDirection, pressure: hour?.pressure
        )
    case .unavailable:
        projected = Conditions(
            time: now, temperature: nil, feelsLike: nil, code: nil,
            isDay: daylightAt(weather, now: now),
            humidity: nil, wind: nil, gusts: nil, windDirection: nil, pressure: nil
        )
    }
    let today = localDateString(epoch: now, zone: weather.timezone)
    var projectedWeather = weather
    projectedWeather.current = projected
    // Kotlin: keep days not before today; unparseable dates are dropped.
    projectedWeather.days = weather.days.filter { day in
        guard let parsed = parseLocalDate(day.date) else { return false }
        return parsed >= today
    }
    if let air = weather.air, !(0...3600).contains(now - air.time) {
        projectedWeather.air = nil
    }
    return projectedWeather
}

/// A modeled hourly value at this exact instant, or nil when the cached horizon does not cover it.
func forecastHourAt(_ weather: Weather, now: Int) -> Hour? {
    let ordered = weather.hours.sorted { $0.time < $1.time }.uniqued { $0.time }
    if let exact = ordered.first(where: { $0.time == now }) { return exact }
    let rightIndex = ordered.firstIndex { $0.time > now } ?? -1
    if rightIndex <= 0 { return nil }
    let left = ordered[rightIndex - 1]
    let right = ordered[rightIndex]
    let span = right.time - left.time
    if !(1...3600).contains(span) { return nil }
    let fraction = Double(now - left.time) / Double(span)
    func blend(_ a: Double?, _ b: Double?) -> Double? {
        guard let a, let b, a.isFinite, b.isFinite else { return nil }
        return a + (b - a) * fraction
    }
    var direction: Double?
    if let leftDir = left.windDirection, leftDir.isFinite,
       let rightDir = right.windDirection, rightDir.isFinite {
        let a = ((leftDir.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let b = ((rightDir.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let delta = ((b - a + 540).truncatingRemainder(dividingBy: 360)) - 180
        direction = ((a + delta * fraction).truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
    }
    return Hour(
        time: now, temperature: blend(left.temperature, right.temperature), code: left.code,
        precipitationProbability: blend(left.precipitationProbability, right.precipitationProbability),
        precipitation: blend(left.precipitation, right.precipitation),
        wind: blend(left.wind, right.wind), gusts: blend(left.gusts, right.gusts),
        humidity: blend(left.humidity, right.humidity), dewPoint: blend(left.dewPoint, right.dewPoint),
        pressure: blend(left.pressure, right.pressure), visibility: blend(left.visibility, right.visibility),
        uv: blend(left.uv, right.uv), feelsLike: blend(left.feelsLike, right.feelsLike),
        windDirection: direction
    )
}

/// This only chooses background artwork when solar data is missing (including polar
/// locations). It is not presented as a measured sunrise/sunset or a fresh provider
/// is_day value (comment preserved from Kotlin `daylightAt`).
private func daylightAt(_ weather: Weather, now: Int) -> Bool {
    let zone = TimeZone(identifier: weather.timezone) ?? TimeZone(identifier: "UTC")!
    let today = localDateString(epoch: now, zone: weather.timezone)
    let day = weather.days.first { $0.date == today }
    if let sunrise = day?.sunrise, let sunset = day?.sunset, sunset > sunrise {
        return now >= sunrise && now < sunset
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    let hour = calendar.component(.hour, from: Date(timeIntervalSince1970: TimeInterval(now)))
    return (6..<18).contains(hour)
}

// MARK: - Date helpers (replace java.time usage; behavior-equivalent)

private func localDateString(epoch: Int, zone: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: zone) ?? TimeZone(identifier: "UTC")
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(epoch)))
}

private func parseLocalDate(_ string: String) -> String? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "UTC")
    guard let date = formatter.date(from: string) else { return nil }
    return formatter.string(from: date)
}

private extension Array {
    /// Kotlin `distinctBy` on a key selector.
    func uniqued<Key: Equatable>(_ key: (Element) -> Key) -> [Element] {
        var seen: [Key] = []
        return filter { element in
            let k = key(element)
            if seen.contains(k) { return false }
            seen.append(k)
            return true
        }
    }
}
