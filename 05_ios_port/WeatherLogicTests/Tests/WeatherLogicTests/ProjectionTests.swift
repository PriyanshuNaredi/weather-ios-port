import XCTest
import Foundation
@testable import WeatherLogic

// Linux-host logic tests for ForecastProjection (Kotlin ForecastProjection.kt parity)
// and the Models.kt formatting helpers.

final class ProjectionTests: XCTestCase {

    private func makeWeather(hours: [Hour], days: [Day] = [], air: AirQuality? = nil) -> Weather {
        Weather(
            city: City(id: "1", name: "Berlin", country: "Germany",
                       latitude: 52.52437, longitude: 13.41053, timezone: "Europe/Berlin"),
            current: Conditions(time: 1000, temperature: 10.0, feelsLike: 8.0, code: 2, isDay: true,
                                humidity: 60, wind: 5, gusts: 9, windDirection: 180, pressure: 1013),
            hours: hours, days: days, air: air, fetchedAt: 1000, timezone: "Europe/Berlin")
    }

    // MARK: - conditionSourceAt

    func testConditionSourceFreshCurrent() {
        let weather = makeWeather(hours: [])
        XCTAssertEqual(conditionSourceAt(weather, now: 1000), .current)
        XCTAssertEqual(conditionSourceAt(weather, now: 1900), .current)   // within 900 s
        XCTAssertEqual(conditionSourceAt(weather, now: 1901), .unavailable) // no hours
    }

    func testConditionSourceForecastCovered() {
        let weather = makeWeather(hours: [Hour(time: 1000, temperature: 10, code: 2),
                                          Hour(time: 4600, temperature: 12, code: 3)])
        XCTAssertEqual(conditionSourceAt(weather, now: 1901), .forecast)
        XCTAssertEqual(conditionSourceAt(weather, now: 4600), .forecast)  // gap 3600 > 900 -> forecast exact-hour hit
    }

    func testConditionSourceBeyondHorizon() {
        let weather = makeWeather(hours: [Hour(time: 1000, temperature: 10)])
        XCTAssertEqual(conditionSourceAt(weather, now: 10000), .unavailable)
    }

    // MARK: - forecastHourAt interpolation

    func testExactHourHit() {
        let hour = Hour(time: 2000, temperature: 11.5, code: 61)
        let weather = makeWeather(hours: [Hour(time: 1000, temperature: 10), hour])
        let projected = try? XCTUnwrap(forecastHourAt(weather, now: 2000))
        XCTAssertEqual(projected, hour)
    }

    func testLinearInterpolation() throws {
        let weather = makeWeather(hours: [
            Hour(time: 1000, temperature: 10.0, code: 3, wind: 10, gusts: 20,
                 windDirection: 350),
            Hour(time: 2000, temperature: 12.0, code: 61, wind: 20, gusts: 30,
                 windDirection: 10)
        ])
        let hour = try XCTUnwrap(forecastHourAt(weather, now: 1500))
        XCTAssertEqual(hour.temperature!, 11.0, accuracy: 1e-9)   // halfway
        XCTAssertEqual(hour.wind!, 15.0, accuracy: 1e-9)
        XCTAssertEqual(hour.gusts!, 25.0, accuracy: 1e-9)
        // Wind direction blends the short way around the circle: 350 -> 10 crosses 0.
        XCTAssertEqual(hour.windDirection!, 0.0, accuracy: 1e-9)
        XCTAssertEqual(hour.code, 3)  // code comes from the containing (left) hour
    }

    func testInterpolationNeverBridgesGaps() throws {
        // Adjacent samples 2 h apart: outside the 1...3600 s span rule.
        let weather = makeWeather(hours: [
            Hour(time: 1000, temperature: 10),
            Hour(time: 4600, temperature: 12)
        ])
        // now = 1500: rightIndex = index of 4600 = 1, span 3600 -> allowed, fraction 500/3600.
        let within = try XCTUnwrap(forecastHourAt(weather, now: 1500))
        XCTAssertEqual(within.temperature!, 10.0 + 2.0 * (500.0 / 3600.0), accuracy: 1e-9)
        // now = 4700 is beyond the last sample -> nil.
        XCTAssertNil(forecastHourAt(weather, now: 4700))
        // Duplicate times are distinct-collapsed; left sample only -> before-first is nil.
        XCTAssertNil(forecastHourAt(weather, now: 500))
    }

    func testInterpolationWithMissingSideNil() {
        let weather = makeWeather(hours: [
            Hour(time: 1000, temperature: nil, precipitationProbability: 10),
            Hour(time: 2000, temperature: 12, precipitationProbability: nil)
        ])
        let hour = forecastHourAt(weather, now: 1500)
        XCTAssertNotNil(hour)
        XCTAssertNil(hour?.temperature)              // both sides required
        XCTAssertNil(hour?.precipitationProbability)
    }

    // MARK: - atTime projection

    func testAtTimeCurrentCaseKeepsValues() {
        let weather = makeWeather(hours: [], days: [Day(date: "1970-01-01")])
        let projected = atTime(weather, now: 1500)
        XCTAssertEqual(projected.current.temperature, 10.0)  // fresh current values kept
        XCTAssertEqual(projected.current.time, 1500)         // but timestamp is the display clock
    }

    func testAtTimeForecastCaseDropsCurrentValues() throws {
        // now = 1901: current (time 1000) is 901 s stale — beyond the 900 s fresh
        // window — so the projection interpolates from the hourly samples instead.
        let weather = makeWeather(hours: [
            Hour(time: 1000, temperature: 10.0, code: 3, windDirection: 180),
            Hour(time: 2000, temperature: 12.0, code: 61, windDirection: 180)
        ], days: [Day(date: "1970-01-01")])
        let projected = atTime(weather, now: 1901)
        // fraction = 901/1000 -> temp = 10 + 2 * 0.901
        XCTAssertEqual(try XCTUnwrap(projected.current.temperature), 11.802, accuracy: 1e-9)
        XCTAssertEqual(projected.current.code, 3)            // containing-hour code
        // 1901 s epoch = 00:31 Berlin time -> 6..<18 hour fallback says night.
        XCTAssertEqual(projected.current.isDay, false)
        XCTAssertEqual(projected.current.time, 1901)
    }

    func testAtTimeUnavailableCaseClearsEverything() {
        let weather = makeWeather(hours: [Hour(time: 1000, temperature: 10)])
        let projected = atTime(weather, now: 100000)
        XCTAssertNil(projected.current.temperature)
        XCTAssertNil(projected.current.code)
        XCTAssertEqual(projected.current.time, 100000)
    }

    func testAtTimeFiltersPastDaysAndStaleAir() {
        let days = [
            Day(date: "1970-01-01", high: 1),   // epoch-ish past date -> dropped
            Day(date: "2100-01-01", high: 2)    // future -> kept
        ]
        let weather = makeWeather(hours: [], days: days,
                                  air: AirQuality(time: 0, europeanAqi: 10, usAqi: 10, pm25: 1, pm10: 1))
        let projected = atTime(weather, now: 100000)
        XCTAssertEqual(projected.days.map { $0.date }, ["2100-01-01"])
        XCTAssertNil(projected.air)  // air older than 3600 s is dropped in projection

        let fresh = makeWeather(hours: [], days: days,
                                air: AirQuality(time: 100000, europeanAqi: 10, usAqi: 10, pm25: 1, pm10: 1))
        XCTAssertNotNil(atTime(fresh, now: 100000).air)
    }

    func testAtTimeDropsUnparseableDates() {
        let days = [Day(date: "not-a-date", high: 1), Day(date: "2100-01-01", high: 2)]
        let projected = atTime(makeWeather(hours: [], days: days), now: 100000)
        XCTAssertEqual(projected.days.map { $0.date }, ["2100-01-01"])
    }

    // MARK: - daylightAt via atTime.isDay

    func testDaylightUsesSunriseSunsetWhenAvailable() {
        // 1970-01-01 in Europe/Berlin; sunrise 07:00 UTC, sunset 17:00 UTC.
        let sunrise = 7 * 3600, sunset = 17 * 3600
        let days = [Day(date: "1970-01-01", sunrise: sunrise, sunset: sunset)]
        let dayWeather = makeWeather(hours: [], days: days)
        let morning = atTime(dayWeather, now: 8 * 3600)   // 08:00 UTC = 09:00 Berlin -> day
        let night = atTime(dayWeather, now: 18 * 3600)    // 18:00 UTC = 19:00 Berlin -> night
        XCTAssertEqual(morning.current.isDay, true)
        XCTAssertEqual(night.current.isDay, false)
    }

    // MARK: - Units (Models.kt helpers)

    func testTempFormatting() {
        XCTAssertEqual(temp(21.0), "21°")
        XCTAssertEqual(temp(21.567), "22°")        // 0 decimals
        XCTAssertEqual(temp(21.5, imperial: true), "71°")  // 21.5*9/5+32 = 70.7 -> 0 decimals
        XCTAssertEqual(temp(nil), "—")             // no degree sign on the dash
        XCTAssertEqual(temp(nil, imperial: true), "—")
    }

    func testSpeedFormatting() {
        XCTAssertEqual(speed(100, imperial: false), "100 km/h")
        XCTAssertEqual(speed(100, imperial: true), "62 mph")   // 100/1.609344 = 62.13...
        XCTAssertEqual(speed(nil, imperial: true), "— mph")
        XCTAssertEqual(speed(nil, imperial: false), "— km/h")
    }

    func testDisplayDecimals() {
        XCTAssertEqual(Optional(1.234).display(decimals: 2), "1.23")
        XCTAssertEqual((nil as Double?).display(decimals: 2), "—")
    }

    func testLocalTimeFormatsInCityZone() {
        // 1970-01-01 12:00 UTC -> 13:00 in Europe/Berlin (CET, +1).
        XCTAssertEqual(localTime(12 * 3600, zone: "Europe/Berlin"), "13:00")
        XCTAssertEqual(localTime(12 * 3600, zone: "UTC"), "12:00")
        XCTAssertEqual(localTime(12 * 3600, zone: "Not/AZone"), "12:00")  // invalid zone -> UTC
    }

    func testLocalTimeCustomPattern() {
        XCTAssertEqual(localTime(12 * 3600, zone: "UTC", pattern: "HH:mm:ss"), "12:00:00")
    }

    // MARK: - WMO codes

    func testConditionTable() {
        XCTAssertEqual(condition(0), "Clear sky")
        XCTAssertEqual(condition(1), "Mostly clear")
        XCTAssertEqual(condition(2), "Partly cloudy")
        XCTAssertEqual(condition(3), "Cloudy")
        XCTAssertEqual(condition(45), "Fog")
        XCTAssertEqual(condition(48), "Fog")
        XCTAssertEqual(condition(53), "Drizzle")
        XCTAssertEqual(condition(57), "Freezing drizzle")
        XCTAssertEqual(condition(65), "Rain")
        XCTAssertEqual(condition(66), "Freezing rain")
        XCTAssertEqual(condition(75), "Snow")
        XCTAssertEqual(condition(77), "Snow")
        XCTAssertEqual(condition(82), "Rain showers")
        XCTAssertEqual(condition(86), "Snow showers")
        XCTAssertEqual(condition(99), "Thunderstorms")
        XCTAssertEqual(condition(nil), "Conditions unavailable")
        XCTAssertEqual(condition(1234), "Conditions unavailable")
    }
}
