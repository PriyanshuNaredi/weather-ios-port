import Foundation

// iOS port of `Data.kt` `DataCodec` — pure parsers kept separate so missing-value,
// timezone and persistence behavior can be tested (comment preserved from Kotlin).
// Uses JSONSerialization dictionaries; helper `number` mirrors the Kotlin
// `JSONObject.number` semantics: present, non-null, finite Double or nil.

enum CodecError: Error, LocalizedError {
    case missing(String)
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .missing(let what): return what
        case .invalid(let what): return what
        }
    }
}

/// Kotlin `JSONObject.number(key)`: only finite numbers qualify; null/absent → nil.
func jsonNumber(_ dict: [String: Any]?, _ key: String) -> Double? {
    guard let dict, let raw = dict[key], !(raw is NSNull) else { return nil }
    let value: Double?
    if let d = raw as? Double { value = d }
    else if let n = raw as? NSNumber { value = n.doubleValue }
    else if let i = raw as? Int { value = Double(i) }
    else { value = nil }
    return value?.takeIf { $0.isFinite }
}

func jsonLongNumber(_ dict: [String: Any]?, _ key: String) -> Int? {
    jsonNumber(dict, key).map { Int($0) }
}

/// Kotlin `arrayNumber(key, index)`: element present, non-null, finite.
private func jsonArrayNumber(_ dict: [String: Any]?, _ key: String, _ index: Int) -> Double? {
    guard let array = dict?[key] as? [Any], index < array.count, !(array[index] is NSNull) else {
        return nil
    }
    let value: Double?
    if let d = array[index] as? Double { value = d }
    else if let n = array[index] as? NSNumber { value = n.doubleValue }
    else if let i = array[index] as? Int { value = Double(i) }
    else { value = nil }
    return value?.takeIf { $0.isFinite }
}

private extension Double {
    func takeIf(_ predicate: (Double) -> Bool) -> Double? { predicate(self) ? self : nil }
}

// MARK: - City JSON

enum DataCodec {

    /// Kotlin `cityJson` — exact key set.
    static func cityJson(_ city: City) -> [String: Any] {
        ["id": city.id, "name": city.name, "country": city.country,
         "latitude": city.latitude, "longitude": city.longitude, "timezone": city.timezone]
    }

    /// Kotlin `city(json)` — id/name/lat/lon required (throws when missing).
    static func city(_ json: [String: Any]) throws -> City {
        guard let id = json["id"] as? String else { throw CodecError.missing("city id missing") }
        guard let name = json["name"] as? String else { throw CodecError.missing("city name missing") }
        let country = json["country"] as? String ?? ""
        guard let lat = jsonNumber(json, "latitude"), let lon = jsonNumber(json, "longitude") else {
            throw CodecError.missing("city coordinates missing")
        }
        let timezone = json["timezone"] as? String ?? "UTC"
        return City(id: id, name: name, country: country, latitude: lat, longitude: lon, timezone: timezone)
    }

    static func cities(_ json: [Any]) throws -> [City] {
        try json.compactMap { $0 as? [String: Any] }.map(city)
    }

    /// Kotlin `cachedForecast(envelope, requestedCity)` — display identity belongs to
    /// the current request, not the cached coordinate key.
    static func cachedForecast(_ envelope: [String: Any], requestedCity: City) throws -> Weather {
        guard let forecast = envelope["forecast"] as? [String: Any] else {
            throw CodecError.missing("cached forecast envelope is missing forecast data")
        }
        let air = envelope["air"] as? [String: Any]
        guard let fetchedAt = jsonLongNumber(envelope, "fetchedAt") else {
            throw CodecError.missing("cached forecast envelope has no fetch time")
        }
        return try forecastCodec(forecast, city: requestedCity, airRaw: air, fetchedAt: fetchedAt)
    }

    // MARK: - Forecast

    /// Kotlin `DataCodec.forecast`. Zone validity is checked against the IANA database;
    /// invalid zones fall back to UTC (Kotlin `ZoneId.of` runCatching).
    static func forecastCodec(_ raw: [String: Any], city: City, airRaw: [String: Any]?, fetchedAt: Int) throws -> Weather {
        let rawZone = raw["timezone"] as? String ?? city.timezone
        let zone = TimeZone(identifier: rawZone) != nil ? rawZone : "UTC"
        guard let c = raw["current"] as? [String: Any] else {
            throw CodecError.missing("The forecast has no valid update time.")
        }
        guard let currentTime = jsonLongNumber(c, "time"), currentTime > 0 else {
            throw CodecError.missing("The forecast has no valid update time.")
        }
        let current = Conditions(
            time: currentTime,
            temperature: jsonNumber(c, "temperature_2m"),
            feelsLike: jsonNumber(c, "apparent_temperature"),
            code: jsonNumber(c, "weather_code").map { Int($0) },
            isDay: (c["is_day"] as? Int ?? 1) == 1,
            humidity: jsonNumber(c, "relative_humidity_2m"),
            wind: jsonNumber(c, "wind_speed_10m"),
            gusts: jsonNumber(c, "wind_gusts_10m"),
            windDirection: jsonNumber(c, "wind_direction_10m"),
            pressure: jsonNumber(c, "pressure_msl")
        )
        let h = raw["hourly"] as? [String: Any] ?? [:]
        let times = h["time"] as? [Any] ?? []
        let hours: [Hour] = times.indices.compactMap { i in
            guard let time = jsonArrayNumber(h, "time", i).map({ Int($0) }), time > 0 else { return nil }
            return Hour(
                time: time,
                temperature: jsonArrayNumber(h, "temperature_2m", i),
                code: jsonArrayNumber(h, "weather_code", i).map { Int($0) },
                precipitationProbability: jsonArrayNumber(h, "precipitation_probability", i),
                precipitation: jsonArrayNumber(h, "precipitation", i),
                wind: jsonArrayNumber(h, "wind_speed_10m", i),
                gusts: jsonArrayNumber(h, "wind_gusts_10m", i),
                humidity: jsonArrayNumber(h, "relative_humidity_2m", i),
                dewPoint: jsonArrayNumber(h, "dew_point_2m", i),
                pressure: jsonArrayNumber(h, "pressure_msl", i),
                visibility: jsonArrayNumber(h, "visibility", i),
                uv: jsonArrayNumber(h, "uv_index", i),
                feelsLike: jsonArrayNumber(h, "apparent_temperature", i),
                windDirection: jsonArrayNumber(h, "wind_direction_10m", i)
            )
        }
        let d = raw["daily"] as? [String: Any] ?? [:]
        let dailyTimes = d["time"] as? [Any] ?? []
        let utcOffset = jsonLongNumber(raw, "utc_offset_seconds")
        let days: [Day] = dailyTimes.indices.compactMap { (i: Int) -> Day? in
            guard let time = jsonArrayNumber(d, "time", i).map({ Int($0) }), time > 0 else { return nil }
            // Daily timestamps encode calendar buckets with the provider's fixed response
            // offset; hourly instants still use the IANA zone (comment preserved).
            let date: String
            if let offset = utcOffset {
                date = isoDate(epoch: time + offset, zone: "UTC")
            } else {
                date = isoDate(epoch: time, zone: zone)
            }
            return Day(
                date: date,
                code: jsonArrayNumber(d, "weather_code", i).map { Int($0) },
                high: jsonArrayNumber(d, "temperature_2m_max", i),
                low: jsonArrayNumber(d, "temperature_2m_min", i),
                sunrise: jsonArrayNumber(d, "sunrise", i).flatMap { (v: Double) -> Int? in
                    let value = Int(v); return value > 0 ? value : nil },
                sunset: jsonArrayNumber(d, "sunset", i).flatMap { (v: Double) -> Int? in
                    let value = Int(v); return value > 0 ? value : nil },
                uv: jsonArrayNumber(d, "uv_index_max", i),
                precipitation: jsonArrayNumber(d, "precipitation_sum", i),
                precipitationProbability: jsonArrayNumber(d, "precipitation_probability_max", i)
            )
        }
        var air: AirQuality?
        if let a = airRaw?["current"] as? [String: Any], let time = jsonLongNumber(a, "time"), time > 0 {
            air = AirQuality(time: time, europeanAqi: jsonNumber(a, "european_aqi"),
                             usAqi: jsonNumber(a, "us_aqi"), pm25: jsonNumber(a, "pm2_5"),
                             pm10: jsonNumber(a, "pm10"))
        }
        let cityWithZone = city
        var resolved = cityWithZone
        resolved.timezone = zone
        return Weather(city: resolved, current: current, hours: hours, days: days,
                       air: air, fetchedAt: fetchedAt, timezone: zone)
    }

    /// Daily/ISO date bucket formatting (java.time `toLocalDate().toString()` equivalent).
    static func isoDate(epoch: Int, zone: String) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day],
            from: Date(timeIntervalSince1970: TimeInterval(epoch)))
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    // MARK: - Radar

    /// Kotlin `DataCodec.radar` — secure-tile check, /v2/radar/ path filter,
    /// distinct-by-time, sorted ascending, empty throws.
    static func radar(_ raw: [String: Any], fetchedAt: Int) throws -> RadarTimeline {
        guard let host = raw["host"] as? String else {
            throw CodecError.missing("Radar requires a secure tile source.")
        }
        guard host.hasPrefix("https://") else {
            throw CodecError.invalid("Radar requires a secure tile source.")
        }
        let array = (raw["radar"] as? [String: Any])?["past"] as? [Any] ?? []
        var seen: Set<Int> = []
        let frames: [RadarFrame] = array.compactMap { element in
            guard let frame = element as? [String: Any] else { return nil }
            let path = frame["path"] as? String ?? ""
            guard let time = jsonLongNumber(frame, "time"), time > 0 else { return nil }
            guard path.hasPrefix("/v2/radar/") else { return nil }
            return RadarFrame(time: time, path: path)
        }.filter { seen.insert($0.time).inserted }
         .sorted { $0.time < $1.time }
        if frames.isEmpty {
            throw CodecError.missing("Rain radar has no recent frames. Try again later.")
        }
        // Kotlin trimEnd('/') — strip all trailing slashes.
        var trimmedHost = host
        while trimmedHost.hasSuffix("/") { trimmedHost.removeLast() }
        return RadarTimeline(host: trimmedHost, frames: frames, fetchedAt: fetchedAt)
    }

    // MARK: - Temperature grid

    /// Kotlin `normalizeLongitude` — wrap into [-180, 180).
    static func normalizeLongitude(_ value: Double) -> Double {
        ((value + 180.0).truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) - 180.0
    }

    /// Kotlin `gridCoordinates` — 7×7 sample grid, clamped latitudes, min-span guard.
    static func gridCoordinates(west: Double, south: Double, east: Double, north: Double) throws -> TemperatureGrid {
        guard [west, south, east, north].allSatisfy({ $0.isFinite }) else {
            throw CodecError.invalid("Invalid map area.")
        }
        let w = normalizeLongitude(west)
        let rawSpan = east - west
        let span = abs(rawSpan) >= 360 ? 360.0
            : ((rawSpan.truncatingRemainder(dividingBy: 360.0)) + 360.0)
                .truncatingRemainder(dividingBy: 360.0)
        let s = min(south, north).clamped(-85.0, 85.0)
        let n = max(south, north).clamped(-85.0, 85.0)
        guard span > 0.00001, n - s > 0.00001 else {
            throw CodecError.invalid("Zoom out slightly to load this area.")
        }
        var points: [TemperaturePoint] = []
        for row in 0...6 {
            for column in 0...6 {
                points.append(TemperaturePoint(
                    latitude: s + (n - s) * Double(row) / 6.0,
                    longitude: w + span * Double(column) / 6.0,
                    temperature: nil, time: 0))
            }
        }
        return TemperatureGrid(west: w, south: s, east: w + span, north: n, points: points, fetchedAt: 0)
    }

    /// Kotlin `gridJson` — point keys are lat/lon/temperature/time.
    static func gridJson(_ grid: TemperatureGrid) -> [String: Any] {
        ["west": grid.west, "south": grid.south, "east": grid.east, "north": grid.north,
         "fetchedAt": grid.fetchedAt,
         "points": grid.points.map { p in
             ["lat": p.latitude, "lon": p.longitude,
              "temperature": p.temperature.map { $0 } ?? NSNull(), "time": p.time] as [String: Any]
         }]
    }

    /// Kotlin `grid(raw)` — rebuilds a saved grid from its JSON form.
    static func grid(_ raw: [String: Any]) throws -> TemperatureGrid {
        guard let pointsRaw = raw["points"] as? [Any] else {
            throw CodecError.missing("grid points missing")
        }
        guard let west = jsonNumber(raw, "west"), let south = jsonNumber(raw, "south"),
              let east = jsonNumber(raw, "east"), let north = jsonNumber(raw, "north"),
              let fetchedAt = jsonLongNumber(raw, "fetchedAt") else {
            throw CodecError.missing("grid bounds missing")
        }
        let points: [TemperaturePoint] = try pointsRaw.compactMap { element in
            guard let p = element as? [String: Any],
                  let lat = jsonNumber(p, "lat"), let lon = jsonNumber(p, "lon"),
                  let time = jsonLongNumber(p, "time") else {
                throw CodecError.missing("grid point malformed")
            }
            return TemperaturePoint(latitude: lat, longitude: lon,
                                    temperature: jsonNumber(p, "temperature"), time: time)
        }
        return TemperatureGrid(west: west, south: south, east: east, north: north,
                               points: points, fetchedAt: fetchedAt)
    }
}

private extension Double {
    func clamped(_ lower: Double, _ upper: Double) -> Double {
        Swift.min(Swift.max(self, lower), upper)
    }
}
