import XCTest
import Foundation
@testable import WeatherLogic

// Linux-host logic tests for DataCodec. Fixtures mirror actual Open-Meteo /
// RainViewer response schemas (traced from the Android Data.kt contract).
final class CodecTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        // Fixtures live in the package Fixtures directory; locate via #filePath.
        let url = URL(fileURLWithPath: #filePath)
        let dir = url.deletingLastPathComponent()  // Tests/WeatherLogicTests
        let packageRoot = dir.deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: packageRoot.appendingPathComponent("Fixtures/\(name)"))
    }

    private func jsonFixture(_ name: String) throws -> [String: Any] {
        let data = try fixture(name)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeCity() -> City {
        City(id: "1", name: "Berlin", country: "Germany",
             latitude: 52.52437, longitude: 13.41053, timezone: "Europe/Berlin")
    }

    // MARK: - Forecast decoding

    func testForecastDecode() throws {
        let raw = try jsonFixture("forecast.json")
        let air = try jsonFixture("air-quality.json")
        let weather = try DataCodec.forecastCodec(raw, city: makeCity(), airRaw: air, fetchedAt: 1731312100)

        XCTAssertEqual(weather.timezone, "Europe/Berlin")
        XCTAssertEqual(weather.city.timezone, "Europe/Berlin")  // zone overrides the requested city
        XCTAssertEqual(weather.current.temperature, 8.2)
        XCTAssertEqual(weather.current.feelsLike, 6.1)
        XCTAssertEqual(weather.current.code, 61)
        XCTAssertEqual(weather.current.isDay, true)
        XCTAssertEqual(weather.current.humidity, 85)
        XCTAssertEqual(weather.current.wind, 12.3)
        XCTAssertEqual(weather.current.gusts, 24.5)
        XCTAssertEqual(weather.current.windDirection, 250)
        XCTAssertEqual(weather.current.pressure, 1013.2)

        XCTAssertEqual(weather.hours.count, 4)
        XCTAssertEqual(weather.hours[0].time, 1731308400)
        XCTAssertEqual(weather.hours[0].temperature, 7.1)
        XCTAssertEqual(weather.hours[2].precipitationProbability, 80)
        XCTAssertEqual(weather.hours[1].visibility, 15000)

        XCTAssertEqual(weather.days.count, 2)
        // Daily time 1731312000 + utc_offset 3600 evaluated at UTC -> 2024-11-11.
        XCTAssertEqual(weather.days[0].date, "2024-11-11")
        XCTAssertEqual(weather.days[1].date, "2024-11-12")
        XCTAssertEqual(weather.days[0].high, 11.2)
        XCTAssertEqual(weather.days[0].low, 4.1)
        XCTAssertEqual(weather.days[0].sunrise, 1731337200)
        XCTAssertEqual(weather.days[0].sunset, 1731368400)
        XCTAssertEqual(weather.days[0].uv, 1.5)
        XCTAssertEqual(weather.days[0].precipitation, 2.4)
        XCTAssertEqual(weather.days[0].precipitationProbability, 80)

        let airQuality = try XCTUnwrap(weather.air)
        XCTAssertEqual(airQuality.europeanAqi, 35.2)
        XCTAssertEqual(airQuality.usAqi, 42.1)
        XCTAssertEqual(airQuality.pm25, 8.4)
        XCTAssertEqual(airQuality.pm10, 12.7)
        XCTAssertEqual(weather.fetchedAt, 1731312100)
    }

    func testForecastWithoutAirQuality() throws {
        let raw = try jsonFixture("forecast.json")
        let weather = try DataCodec.forecastCodec(raw, city: makeCity(), airRaw: nil, fetchedAt: 100)
        XCTAssertNil(weather.air)
    }

    func testForecastMissingCurrentTimeThrows() throws {
        let raw = try jsonFixture("forecast.json")
        var broken = raw
        broken["current"] = ["temperature_2m": 1.0]  // no valid time
        XCTAssertThrowsError(try DataCodec.forecastCodec(broken, city: makeCity(), airRaw: nil, fetchedAt: 1)) { error in
            XCTAssertEqual((error as? CodecError)?.errorDescription, "The forecast has no valid update time.")
        }
    }

    func testNullHourlyEntriesAreSkipped() throws {
        var raw = try jsonFixture("forecast.json")
        var hourly = try XCTUnwrap(raw["hourly"] as? [String: Any])
        hourly["time"] = [1731308400, NSNull(), 1731315600, 1731319200]
        raw["hourly"] = hourly
        let weather = try DataCodec.forecastCodec(raw, city: makeCity(), airRaw: nil, fetchedAt: 1)
        XCTAssertEqual(weather.hours.count, 3)  // the null entry is dropped, list stays aligned
        XCTAssertEqual(weather.hours[1].time, 1731315600)
    }

    func testInvalidTimezoneFallsBackToUTC() throws {
        var raw = try jsonFixture("forecast.json")
        raw["timezone"] = "Not/AZone"
        let weather = try DataCodec.forecastCodec(raw, city: makeCity(), airRaw: nil, fetchedAt: 1)
        XCTAssertEqual(weather.timezone, "UTC")
    }

    // MARK: - Cached envelope

    func testCachedForecastUsesRequestedCityIdentity() throws {
        let raw = try jsonFixture("forecast.json")
        let envelope: [String: Any] = [
            "city": DataCodec.cityJson(makeCity()),
            "forecast": raw,
            "air": NSNull(),
            "fetchedAt": 1731312100
        ]
        let requested = City(id: "9", name: "Renamed", country: "Elsewhere",
                             latitude: 52.52437, longitude: 13.41053, timezone: "UTC")
        let weather = try DataCodec.cachedForecast(envelope, requestedCity: requested)
        // Display identity belongs to the request, zone comes from the forecast payload.
        XCTAssertEqual(weather.city.name, "Renamed")
        XCTAssertEqual(weather.city.id, "9")
        XCTAssertEqual(weather.timezone, "Europe/Berlin")
        XCTAssertEqual(weather.current.temperature, 8.2)
    }

    func testCachedForecastMissingFetchedAtThrows() throws {
        let envelope: [String: Any] = ["city": [:], "forecast": [:]]
        XCTAssertThrowsError(try DataCodec.cachedForecast(envelope, requestedCity: makeCity()))
    }

    // MARK: - Cities / geocoding

    func testCityRoundTrip() throws {
        let city = makeCity()
        let decoded = try DataCodec.city(DataCodec.cityJson(city))
        XCTAssertEqual(decoded, city)
    }

    func testCityMissingIdThrows() throws {
        XCTAssertThrowsError(try DataCodec.city(["name": "X", "latitude": 1.0, "longitude": 2.0]))
        XCTAssertThrowsError(try DataCodec.city(["id": "x", "name": "X"]))
    }

    func testCityMissingTimezoneDefaultsToUTC() throws {
        let city = try DataCodec.city(["id": "x", "name": "X", "latitude": 1.5, "longitude": -2.5])
        XCTAssertEqual(city.timezone, "UTC")
        XCTAssertEqual(city.latitude, 1.5)
        XCTAssertEqual(city.longitude, -2.5)
    }

    // MARK: - Radar

    func testRadarParseFixture() throws {
        let raw = try jsonFixture("rainviewer.json")
        let timeline = try DataCodec.radar(raw, fetchedAt: 1731312001)
        XCTAssertEqual(timeline.host, "https://tilecache.rainviewer.com")  // trailing slash stripped
        XCTAssertEqual(timeline.fetchedAt, 1731312001)
        // v1 path excluded, duplicate time excluded, sorted ascending.
        XCTAssertEqual(timeline.frames.map { $0.time }, [1731304800, 1731308400, 1731315600])
        XCTAssertEqual(timeline.frames[0].path, "/v2/radar/1731304800")
    }

    func testRadarRejectsInsecureHost() throws {
        let raw = try jsonFixture("rainviewer-insecure.json")
        XCTAssertThrowsError(try DataCodec.radar(raw, fetchedAt: 1)) { error in
            XCTAssertEqual((error as? CodecError)?.errorDescription, "Radar requires a secure tile source.")
        }
    }

    func testRadarEmptyFramesThrows() throws {
        let raw: [String: Any] = [
            "host": "https://tilecache.rainviewer.com",
            "radar": ["past": [[ "time": 1731312000, "path": "/v1/radar/x" ]]]
        ]
        XCTAssertThrowsError(try DataCodec.radar(raw, fetchedAt: 1)) { error in
            XCTAssertEqual((error as? CodecError)?.errorDescription,
                           "Rain radar has no recent frames. Try again later.")
        }
    }

    func testRadarMissingHostThrows() throws {
        XCTAssertThrowsError(try DataCodec.radar(["radar": [:]], fetchedAt: 1))
    }

    // MARK: - Temperature grid

    func testGridFixtureRoundTrip() throws {
        let raw = try jsonFixture("grid.json")
        let grid = try DataCodec.grid(raw)
        XCTAssertEqual(grid.west, -10.0)
        XCTAssertEqual(grid.south, 40.0)
        XCTAssertEqual(grid.north, 50.0)
        XCTAssertEqual(grid.fetchedAt, 1731312000)
        XCTAssertEqual(grid.points.count, 3)
        XCTAssertEqual(grid.points[0].temperature, 8.3)
        XCTAssertNil(grid.points[1].temperature)  // null survives as nil
        XCTAssertEqual(grid.points[1].time, 0)
    }

    func testGridJsonEncodesNullTemperature() throws {
        let grid = TemperatureGrid(
            west: 0, south: 0, east: 1, north: 1,
            points: [TemperaturePoint(latitude: 0.5, longitude: 0.5, temperature: nil, time: 0)],
            fetchedAt: 42)
        let json = DataCodec.gridJson(grid)
        let points = try XCTUnwrap(json["points"] as? [[String: Any]])
        XCTAssertTrue(points[0]["temperature"] is NSNull)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try DataCodec.grid(try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]))
        XCTAssertNil(decoded.points[0].temperature)
    }

    func testNormalizeLongitude() {
        XCTAssertEqual(DataCodec.normalizeLongitude(180.0), -180.0)
        XCTAssertEqual(DataCodec.normalizeLongitude(190.0), -170.0)
        XCTAssertEqual(DataCodec.normalizeLongitude(-190.0), 170.0)
        XCTAssertEqual(DataCodec.normalizeLongitude(0.0), 0.0)
        XCTAssertEqual(DataCodec.normalizeLongitude(-180.0), -180.0)
    }

    func testGridCoordinatesSeventySeven() throws {
        let grid = try DataCodec.gridCoordinates(west: -10, south: 40, east: 10, north: 50)
        XCTAssertEqual(grid.points.count, 49)
        XCTAssertEqual(grid.west, -10)
        XCTAssertEqual(grid.south, 40)
        XCTAssertEqual(grid.east, 10)
        XCTAssertEqual(grid.north, 50)
        XCTAssertEqual(grid.points[0].latitude, 40)
        XCTAssertEqual(grid.points[0].longitude, -10)
        XCTAssertEqual(grid.points[48].latitude, 50, accuracy: 1e-9)
        XCTAssertEqual(grid.points[48].longitude, 10, accuracy: 1e-9)
    }

    func testGridCoordinatesWrapsAndClamps() throws {
        // Longitude span wrapping: west 170 -> east -170 spans 20 degrees.
        let grid = try DataCodec.gridCoordinates(west: 170, south: -90, east: -170, north: 90)
        XCTAssertEqual(grid.west, 170)
        XCTAssertEqual(grid.east, -170 + 360)  // w + span
        XCTAssertEqual(grid.south, -85)        // latitude clamped
        XCTAssertEqual(grid.north, 85)
        // Reversed corners still produce a sane box.
        let flipped = try DataCodec.gridCoordinates(west: 10, south: 50, east: -10, north: 40)
        XCTAssertEqual(flipped.south, 40)
        XCTAssertEqual(flipped.north, 50)
    }

    func testGridCoordinatesGuards() throws {
        XCTAssertThrowsError(try DataCodec.gridCoordinates(west: .nan, south: 0, east: 1, north: 1)) { error in
            XCTAssertEqual((error as? CodecError)?.errorDescription, "Invalid map area.")
        }
        // Span below the 1e-5 guard asks the user to zoom out.
        XCTAssertThrowsError(try DataCodec.gridCoordinates(west: 0, south: 0, east: 0.000005, north: 0.000005)) { error in
            XCTAssertEqual((error as? CodecError)?.errorDescription,
                           "Zoom out slightly to load this area.")
        }
    }

    // MARK: - Repository cache keys

    func testCacheKeyUsesBitPattern() {
        let a = OpenWeatherRepository.cacheKey(City(id: "1", name: "A", country: "",
            latitude: 52.52437, longitude: 13.41053, timezone: "UTC"))
        let b = OpenWeatherRepository.cacheKey(City(id: "2", name: "B", country: "",
            latitude: 52.52437, longitude: 13.41053, timezone: "UTC"))
        XCTAssertEqual(a, b)  // same coordinates -> same key regardless of identity

        let zero = OpenWeatherRepository.cacheKey(City(id: "1", name: "", country: "",
            latitude: 0.0, longitude: 0.0, timezone: "UTC"))
        let negativeZero = OpenWeatherRepository.cacheKey(City(id: "1", name: "", country: "",
            latitude: -0.0, longitude: 0.0, timezone: "UTC"))
        XCTAssertNotEqual(zero, negativeZero)  // bit-level identity, like Kotlin toBits()
    }

    // MARK: - Error strings

    func testRepositoryErrorStrings() {
        XCTAssertEqual(RepositoryError.providerBusy.errorDescription,
                       "The weather provider is busy. Please try again later.")
        XCTAssertEqual(RepositoryError.http(503).errorDescription,
                       "Weather data could not be loaded (503).")
        XCTAssertEqual(RepositoryError.noData.errorDescription,
                       "The weather provider returned no data.")
    }
}
