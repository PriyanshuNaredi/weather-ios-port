import XCTest

/// Shared launch helpers for the macOS/simulator UI suite.
///
/// The app starts on the city screen when no cities are saved (Kotlin
/// `MainActivity` `cities.isEmpty()` branch), so the bottom navigation bar —
/// Map / Settings / Cities / Diagnostics — only exists once a city is added.
/// Every test that needs the bar goes through `launchWithCity(_:)`.
extension XCUIApplication {

    static func weather(resetState: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if resetState { app.launchArguments += ["-resetState"] }
        app.launch()
        return app
    }

    /// Launches with a clean state, searches `city` through the real geocoder and
    /// waits for its forecast to render.
    static func launchWithCity(_ city: String = "Berlin",
                               file: StaticString = #filePath,
                               line: UInt = #line) -> XCUIApplication {
        let app = weather()

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 25), "search field missing on first launch",
                      file: file, line: line)
        field.tap()
        field.typeText(city)

        let result = app.staticTexts[city].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 25), "geocoding returned no \(city) row",
                      file: file, line: line)
        result.tap()

        let temperature = app.staticTexts.containing(NSPredicate(format: "label ENDSWITH '°'")).firstMatch
        XCTAssertTrue(temperature.waitForExistence(timeout: 40), "forecast never rendered for \(city)",
                      file: file, line: line)
        return app
    }
}
