import Foundation

// iOS port of `Data.kt` `OpenWeatherRepository` — full implementation.
// Behavioral spec: Kotlin Data.kt lines 25–178. Storage mapping:
//   SharedPreferences("weather")        -> UserDefaults(suiteName: "weather")
//   filesDir/"weather-cache" + AtomicFile -> Application Support/"weather-cache" + .atomic writes
//   OkHttp timeouts (connect 12 / read 20 / call 30 s) -> URLSession request 20 s / resource 30 s
//   OkHttp 24 MB cache                  -> URLCache disk 24 MB (see OpenMeteoClient)

/// Error hierarchy — user-facing strings trace to the Kotlin IOException messages.
enum RepositoryError: Error, LocalizedError {
    case providerBusy
    case http(Int)
    case noData
    case network(String)
    case storage(String)

    var errorDescription: String? {
        switch self {
        case .providerBusy: return "The weather provider is busy. Please try again later."
        case .http(let code): return "Weather data could not be loaded (\(code))."
        case .noData: return "The weather provider returned no data."
        case .network(let detail): return "Weather data could not be loaded (\(detail))."
        case .storage(let detail): return "Storage error: \(detail)"
        }
    }
}

/// Sendable wrapper for parsed-JSON dictionaries. JSON-derived payloads are treated
/// as immutable after parsing, but Swift 6 cannot prove that for `Any` — this box
/// carries that invariant across task boundaries (used for the parallel air fetch).
final class JSONBox: @unchecked Sendable {
    let value: [String: Any]
    init(_ value: [String: Any]) { self.value = value }
}

// @unchecked Sendable: mutable in-memory `cache` is guarded by `lock`; all other
// stored state is immutable. (Kotlin counterpart is a single-threaded
// ViewModel-scoped object; the lock preserves equivalent safety under Swift concurrency.)
final class OpenWeatherRepository: WeatherRepository, MapRepository, @unchecked Sendable {
    /// Kotlin `Data.kt:27` — "weather" preferences name.
    private static let prefsName = "weather"
    /// Kotlin `Data.kt:28` — cache directory name.
    private static let cacheDirName = "weather-cache"
    /// Kotlin `Data.kt:112` — radar refresh window (300 s).
    private static let radarFreshSeconds = 300
    /// Kotlin `Data.kt:123` — stale radar fallback window (2 h).
    private static let radarStaleSeconds = 2 * 60 * 60
    /// Kotlin `Data.kt:135` — temperature grid fresh window (30 min).
    private static let gridFreshSeconds = 30 * 60
    /// Kotlin `Data.kt:153-154` — bounded grid cache: keep 12 newest.
    private static let gridCacheLimit = 12

    private let lock = NSLock()
    private var cache: [String: Weather] = [:]
    private let defaults: UserDefaults
    private let directory: URL

    init() {
        defaults = UserDefaults(suiteName: Self.prefsName) ?? .standard
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent(Self.cacheDirName)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - WeatherRepository

    var imperial: Bool {
        get { defaults.bool(forKey: "imperial") }
        set { defaults.set(newValue, forKey: "imperial") }
    }

    /// Kotlin `Data.kt:63-89` — parallel air-quality fetch (failure tolerated, nil),
    /// forecast fetch required, parse, then persist envelope only on parse success.
    // Stability fix: the air-quality side fetch previously ran as an
    // UNSTRUCTURED `Task { }`. If the forecast request failed/threw (or the
    // caller was cancelled), the unstructured task was never cancelled — it
    // kept running to completion, holding its connection and memory. Now it is
    // a structured `async let` child of `forecast`, so it inherits the caller's
    // cancellation and is awaited exactly once.
    func forecast(city: City) async throws -> Weather {
        async let airJson = Self.airQualityQuiet(city: city)
        let params: [String: String] = [
            "latitude": "\(city.latitude)", "longitude": "\(city.longitude)",
            "current": "temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m,wind_gusts_10m,wind_direction_10m,pressure_msl",
            "hourly": OpenMeteo.hourly,
            "daily": OpenMeteo.daily,
            "forecast_days": "10", "timezone": "auto", "timeformat": "unixtime"
        ]
        let raw = try await OpenMeteoClient.shared.getJSON(OpenMeteo.forecastURL, params: params)
        let air = await airJson
        let now = Int(Date().timeIntervalSince1970)
        let result = try DataCodec.forecastCodec(raw, city: city, airRaw: air?.value, fetchedAt: now)
        // Only a successfully parsed forecast may replace last-good data.
        var envelope: [String: Any] = ["city": DataCodec.cityJson(city),
                                       "forecast": raw,
                                       "fetchedAt": now]
        envelope["air"] = air?.value ?? NSNull()
        if let data = try? JSONSerialization.data(withJSONObject: envelope) {
            write("forecast-\(Self.cacheKey(city)).json", data)
        }
        return result
    }

    /// Non-throwing air-quality child fetch (Kotlin: air failure is swallowed
    /// to nil, non-cancellation only). Structured child of `forecast`.
    private static func airQualityQuiet(city: City) async -> JSONBox? {
        guard let json = try? await OpenMeteoClient.shared.getJSON(OpenMeteo.airQualityURL, params: [
            "latitude": "\(city.latitude)", "longitude": "\(city.longitude)",
            "current": "european_aqi,us_aqi,pm2_5,pm10", "timeformat": "unixtime"
        ]) else { return nil }
        return JSONBox(json)
    }

    func cached(city: City) -> Weather? {
        lock.lock(); defer { lock.unlock() }
        if let memory = cache[Self.cacheKey(city)] { return memory }
        guard let data = read("forecast-\(Self.cacheKey(city)).json"),
              let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let weather = try? DataCodec.cachedForecast(envelope, requestedCity: city) else {
            return nil
        }
        cache[Self.cacheKey(city)] = weather
        return weather
    }

    /// Kotlin `Data.kt:91-107` — trimmed query, <2 chars returns empty,
    /// name capped at 100, count 12, language en, format json.
    func search(query: String) async throws -> [City] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { return [] }
        let capped = String(text.prefix(100))
        let result = try await OpenMeteoClient.shared.getJSON(OpenMeteo.geocodingURL, params: [
            "name": capped, "count": "12", "language": "en", "format": "json"
        ])
        guard let rows = result["results"] as? [Any] else { return [] }
        return rows.compactMap { element in
            guard let row = element as? [String: Any],
                  let lat = jsonNumber(row, "latitude"),
                  let lon = jsonNumber(row, "longitude") else { return nil }
            let admin1 = row["admin1"] as? String ?? ""
            let country = row["country"] as? String ?? ""
            // Kotlin: distinct non-blank admin1 + country joined with ", ".
            let parts = [admin1, country].filter { !$0.isBlank }
            var distinctParts: [String] = []
            for part in parts where !distinctParts.contains(part) { distinctParts.append(part) }
            let id = row["id"] as? String ?? "\(lat),\(lon)"
            let name = row["name"] as? String ?? ""
            let timezone = row["timezone"] as? String ?? "UTC"
            return City(id: id, name: name,
                        country: distinctParts.joined(separator: ", "),
                        latitude: lat, longitude: lon, timezone: timezone)
        }
    }

    /// Kotlin `Data.kt:44-46` — cities parse failure yields an empty list, never throws.
    func cities() -> [City] {
        guard let string = defaults.string(forKey: "cities"),
              let data = string.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let parsed = try? DataCodec.cities(array) else { return [] }
        return parsed
    }

    /// Kotlin `Data.kt:48-56` — distinct by id, persist, garbage-collect forecast
    /// cache files not in the retained set.
    func saveCities(_ cities: [City]) {
        var unique: [City] = []
        for city in cities where !unique.contains(where: { $0.id == city.id }) {
            unique.append(city)
        }
        let array = unique.map { DataCodec.cityJson($0) }
        if let data = try? JSONSerialization.data(withJSONObject: array),
           let string = String(data: data, encoding: .utf8) {
            defaults.set(string, forKey: "cities")
        }
        let retained = Set(unique.map { "forecast-\(Self.cacheKey($0)).json" })
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("forecast-")
            && file.lastPathComponent.hasSuffix(".json") && !retained.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - MapRepository

    /// Kotlin `Data.kt:109-127` — 300 s fresh window; on fetch failure falls back to
    /// a saved snapshot younger than 2 h, else throws.
    func radar() async throws -> RadarTimeline {
        let now = Int(Date().timeIntervalSince1970)
        let savedEnvelope = readJSON("radar.json")
        if let savedEnvelope,
           let fetchedAt = jsonLongNumber(savedEnvelope, "fetchedAt"),
           (0..<Self.radarFreshSeconds).contains(now - fetchedAt),
           let data = savedEnvelope["data"] as? [String: Any],
           let timeline = try? DataCodec.radar(data, fetchedAt: fetchedAt) {
            return timeline
        }
        do {
            let data = try await OpenMeteoClient.shared.getJSON(OpenMeteo.rainViewerURL)
            let result = try DataCodec.radar(data, fetchedAt: now)
            let envelope: [String: Any] = ["data": data, "fetchedAt": now]
            if let payload = try? JSONSerialization.data(withJSONObject: envelope) {
                write("radar.json", payload)
            }
            return result
        } catch {
            // Recent cached frames may still exist; callers must show their actual timestamp.
            if let savedEnvelope,
               let fetchedAt = jsonLongNumber(savedEnvelope, "fetchedAt"),
               (0..<Self.radarStaleSeconds).contains(now - fetchedAt),
               let data = savedEnvelope["data"] as? [String: Any],
               let timeline = try? DataCodec.radar(data, fetchedAt: fetchedAt) {
                return timeline
            }
            throw RepositoryError.network("Rain radar is unavailable. Try again shortly.")
        }
    }

    /// Kotlin `Data.kt:129-156` — bounded 7×7 grid fetch with 30-min cache and
    /// keep-newest-12 garbage collection.
    func temperatures(west: Double, south: Double, east: Double, north: Double) async throws -> TemperatureGrid {
        let area = try DataCodec.gridCoordinates(west: west, south: south, east: east, north: north)
        let key = "temperature-" + [area.west, area.south, area.east, area.north]
            .map { Int(($0 * 1000).rounded()).description }.joined(separator: "_") + ".json"
        let now = Int(Date().timeIntervalSince1970)
        if let savedRaw = readJSON(key), let saved = try? DataCodec.grid(savedRaw),
           (0..<Self.gridFreshSeconds).contains(now - saved.fetchedAt) {
            return saved
        }
        let coordinates = area.points
        let latList = coordinates.map { String(format: "%.5f", $0.latitude) }.joined(separator: ",")
        let lonList = coordinates.map {
            String(format: "%.5f", DataCodec.normalizeLongitude($0.longitude))
        }.joined(separator: ",")
        let rows: [[String: Any]]
        if coordinates.count == 1 {
            // Single-point responses are a JSON object.
            rows = [try await OpenMeteoClient.shared.getJSON(OpenMeteo.forecastURL, params: [
                "latitude": latList, "longitude": lonList,
                "current": "temperature_2m", "forecast_days": "1",
                "timeformat": "unixtime", "cell_selection": "nearest"
            ])]
        } else {
            // Multi-point responses arrive as a JSON array.
            rows = try await OpenMeteoClient.shared.getJSONList(OpenMeteo.forecastURL, params: [
                "latitude": latList, "longitude": lonList,
                "current": "temperature_2m", "forecast_days": "1",
                "timeformat": "unixtime", "cell_selection": "nearest"
            ])
        }
        var result = area
        result.points = coordinates.enumerated().map { index, coordinate in
            let current = rows.indices.contains(index) ? (rows[index]["current"] as? [String: Any]) : nil
            let time = jsonLongNumber(current, "time") ?? 0
            let temperature = time > 0 ? jsonNumber(current, "temperature_2m") : nil
            return TemperaturePoint(latitude: coordinate.latitude, longitude: coordinate.longitude,
                                    temperature: temperature, time: time)
        }
        result.fetchedAt = now
        if !result.points.contains(where: { $0.temperature != nil && $0.time > 0 }) {
            throw RepositoryError.network("Temperature data is unavailable for this area. Try again.")
        }
        if let payload = try? JSONSerialization.data(withJSONObject: DataCodec.gridJson(result)) {
            write(key, payload)
        }
        // Keep a bounded private disk cache; never accumulate an unlimited travel history.
        let gridFiles = ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("temperature-") }
            .sorted { (lhs, rhs) in
                let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return l > r
            }
        if gridFiles.count > Self.gridCacheLimit {
            for file in gridFiles.dropFirst(Self.gridCacheLimit) {
                try? FileManager.default.removeItem(at: file)
            }
        }
        return result
    }

    // MARK: - Cache helpers

    /// Kotlin `"${city.latitude.toBits()}_${city.longitude.toBits()}"` — exact raw-bit
    /// identity so ±0.0 vs 0.0 and other bit-level differences produce distinct keys.
    static func cacheKey(_ city: City) -> String {
        "\(city.latitude.bitPattern)_\(city.longitude.bitPattern)"
    }

    /// AtomicFile-equivalent: `.atomic` write to the weather-cache directory.
    private func write(_ name: String, _ data: Data) {
        do {
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
        } catch {
            // Kotlin rethrows write failures; storage errors surface as repository errors.
        }
    }

    private func read(_ name: String) -> Data? {
        try? Data(contentsOf: directory.appendingPathComponent(name))
    }

    private func readJSON(_ name: String) -> [String: Any]? {
        guard let data = read(name) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
