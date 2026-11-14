import Foundation
#if canImport(FoundationNetworking)
// Linux test host: URLSession/URLCache live in FoundationNetworking there.
// No behavioral change on iOS; this exists so the pure-logic test package can compile this file.
import FoundationNetworking
#endif

// iOS port of `Data.kt` network layer. Endpoint URLs, parameters, headers and
// HTTP error strings trace to the Kotlin source; response parsing lives in
// DataCodec.swift, the error hierarchy (RepositoryError) in OpenWeatherRepository.swift.

/// HTTP constants traced from `Data.kt` (exact endpoints/params).
enum OpenMeteo {
    static let forecastURL = "https://api.open-meteo.com/v1/forecast"
    static let airQualityURL = "https://air-quality-api.open-meteo.com/v1/air-quality"
    static let geocodingURL = "https://geocoding-api.open-meteo.com/v1/search"
    static let rainViewerURL = "https://api.rainviewer.com/public/weather-maps.json"
    static let openFreeMapDarkStyle = "https://tiles.openfreemap.org/styles/dark"
    /// Kotlin `Data.kt:77-78` hourly/daily variable lists (exact order preserved).
    static let hourly = "temperature_2m,weather_code,precipitation_probability,precipitation," +
        "wind_speed_10m,wind_gusts_10m,relative_humidity_2m,dew_point_2m,pressure_msl," +
        "visibility,uv_index,apparent_temperature,wind_direction_10m"
    static let daily = "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset," +
        "uv_index_max,precipitation_sum,precipitation_probability_max"
    /// Kotlin `Maps.kt:84` OkHttp User-Agent header.
    static let userAgent = "Weather/1.1.1 (https://github.com/Kian-hdr/Weather; dev.kiankonrad.weather)"
}

/// URLSession client replacing the Kotlin OkHttp `get(endpoint, params)` helper.
/// Kotlin also configures a 24 MB OkHttp `Cache`; on iOS this maps to `URLCache`
/// (configured once at app start).
// Sendable: the only stored state is an immutable URLSession (itself Sendable).
// Swift 6 strict concurrency requires this for the `shared` singleton.
final class OpenMeteoClient: Sendable {
    static let shared = OpenMeteoClient()

    let session: URLSession

    init() {
        #if canImport(FoundationNetworking)
        // Linux (swift-corelibs-foundation): minimal session, cache config is Darwin-only here.
        session = URLSession(configuration: .default)
        #else
        let config = URLSessionConfiguration.default
        // Kotlin `Data.kt:33`: Cache(cacheDir/"provider-http", 24 MB)
        config.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024,
                                   diskCapacity: 24 * 1024 * 1024,
                                   directory: nil)
        // Kotlin connect 12 s / read 20 s / call 30 s → URLSession: idle 20 s,
        // whole-resource 30 s (URLSession has no separate connect timeout).
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
        #endif
    }

    /// Kotlin `get(endpoint, params)` returning a parsed JSON object.
    func getJSON(_ endpoint: String, params: [String: String] = [:]) async throws -> [String: Any] {
        let data = try await get(endpoint, params: params)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RepositoryError.noData
        }
        return object
    }

    /// Multi-point Open-Meteo responses return a JSON array of objects.
    func getJSONList(_ endpoint: String, params: [String: String] = [:]) async throws -> [[String: Any]] {
        let data = try await get(endpoint, params: params)
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw RepositoryError.noData
        }
        return array.compactMap { $0 as? [String: Any] }
    }

    /// Kotlin `Data.kt:159 get(endpoint, params)` — GET with query string, UA header,
    /// timeouts (connect 12 / read 20 / call 30 s → URLSession request 20 / resource 30)
    /// and exact error strings.
    func get(_ endpoint: String, params: [String: String] = [:]) async throws -> Data {
        guard var components = URLComponents(string: endpoint) else {
            throw RepositoryError.network("invalid endpoint")
        }
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw RepositoryError.network("invalid URL") }
        var request = URLRequest(url: url)
        request.setValue(OpenMeteo.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20            // Kotlin readTimeout 20 s
        request.allowsCellularAccess = true
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.network("non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            // Kotlin `Data.kt:162-165` exact messages.
            throw http.statusCode == 429 ? RepositoryError.providerBusy : RepositoryError.http(http.statusCode)
        }
        if data.isEmpty { throw RepositoryError.noData }
        return data
    }
}
