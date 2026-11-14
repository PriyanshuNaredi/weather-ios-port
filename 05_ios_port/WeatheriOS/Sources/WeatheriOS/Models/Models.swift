import Foundation

// iOS port of `Models.kt` (data classes + repository interfaces).
// Field names and nullability trace 1:1 to the Kotlin source.

struct City: Equatable, Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var country: String
    var latitude: Double
    var longitude: Double
    var timezone: String = "UTC"
}

struct Hour: Equatable, Codable, Hashable {
    var time: Int
    var temperature: Double?
    var code: Int?
    var precipitationProbability: Double?
    var precipitation: Double?
    var wind: Double?
    var gusts: Double?
    var humidity: Double?
    var dewPoint: Double?
    var pressure: Double?
    var visibility: Double?
    var uv: Double?
    var feelsLike: Double?
    var windDirection: Double?
}

/// Kotlin `Hour.copy(...)` data-class helper (MainActivity.kt:236 overrides
/// time/temperature/code for the "Now" slot in the hourly strip).
extension Hour {
    func copy(time: Int? = nil, temperature: Double? = nil, code: Int? = nil) -> Hour {
        var copy = self
        if let time { copy.time = time }
        if let temperature { copy.temperature = temperature }
        if let code { copy.code = code }
        return copy
    }
}

struct Day: Equatable, Codable, Hashable {
    var date: String
    var code: Int?
    var high: Double?
    var low: Double?
    var sunrise: Int?
    var sunset: Int?
    var uv: Double?
    var precipitation: Double?
    var precipitationProbability: Double?
}

struct Conditions: Equatable, Codable, Hashable {
    var time: Int
    var temperature: Double?
    var feelsLike: Double?
    var code: Int?
    var isDay: Bool
    var humidity: Double?
    var wind: Double?
    var gusts: Double?
    var windDirection: Double?
    var pressure: Double?
}

struct AirQuality: Equatable, Codable, Hashable {
    var time: Int
    var europeanAqi: Double?
    var usAqi: Double?
    var pm25: Double?
    var pm10: Double?
}

struct Weather: Equatable, Codable {
    var city: City
    var current: Conditions
    var hours: [Hour]
    var days: [Day]
    var air: AirQuality?
    var fetchedAt: Int
    var timezone: String
}

struct RadarFrame: Equatable, Codable {
    var time: Int
    var path: String
}

struct RadarTimeline: Equatable, Codable {
    var host: String
    var frames: [RadarFrame]
    var fetchedAt: Int
}

struct TemperaturePoint: Equatable, Codable {
    var latitude: Double
    var longitude: Double
    var temperature: Double?
    var time: Int
}

struct TemperatureGrid: Equatable, Codable {
    var west: Double
    var south: Double
    var east: Double
    var north: Double
    var points: [TemperaturePoint]
    var fetchedAt: Int
}

// Repository protocols — direct ports of the Kotlin interfaces. `async` replaces
// Kotlin `suspend`; the `WeatherRepository & MapRepository` intersection preserves
// the Android `OpenWeatherRepository : WeatherRepository, MapRepository` shape.
// Sendable: repositories are shared across actors (UI / Task contexts), matching the
// Kotlin singletons which are thread-safe by construction.
protocol WeatherRepository: AnyObject, Sendable {
    func forecast(city: City) async throws -> Weather
    func cached(city: City) -> Weather?
    func search(query: String) async throws -> [City]
    func cities() -> [City]
    func saveCities(_ cities: [City])
    var imperial: Bool { get set }
}

protocol MapRepository: AnyObject, Sendable {
    func radar() async throws -> RadarTimeline
    func temperatures(west: Double, south: Double, east: Double, north: Double) async throws -> TemperatureGrid
}
