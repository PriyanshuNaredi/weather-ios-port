import XCTest

/// macOS/simulator smoke suite for the WeatheriOS port.
///
/// The Linux pipeline (`07_tools/logic-tests.sh`) could only run Foundation
/// logic tests — no SwiftUI, no networking, no gesture handling. These UI tests
/// are the first end-to-end proof that the port launches, searches the live
/// GeoNames/Open-Meteo endpoints, renders a forecast and navigates.
final class WeatherSmokeTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// Full journey: empty state -> search -> add city -> forecast rendered.
    func testSearchAddCityAndRenderForecast() {
        let app = XCUIApplication.weather()

        // City screen empty state (Kotlin MainActivity CityScreen branding block).
        XCTAssertTrue(app.staticTexts["Your day, at a glance."].waitForExistence(timeout: 20),
                      "city screen branding did not appear")

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10), "search field missing")
        field.tap()
        field.typeText("Berlin")

        // 350 ms debounce + geocoding round trip.
        let result = app.staticTexts["Berlin"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 25), "geocoding search returned no Berlin row")
        result.tap()

        // Forecast loaded: a temperature string ("21°") and the country are shown.
        let temperature = app.staticTexts.containing(NSPredicate(format: "label ENDSWITH '°'")).firstMatch
        XCTAssertTrue(temperature.waitForExistence(timeout: 40),
                      "forecast temperature never rendered after adding the city")

        // Bottom bar exists => the pager (not the city screen) is on screen.
        XCTAssertTrue(app.buttons["Cities"].waitForExistence(timeout: 10), "bottom navigation bar missing")
        XCTAssertFalse(app.staticTexts["Your day, at a glance."].exists, "still stuck on city screen")
    }

    /// Bottom-bar navigation: Settings -> Cities.
    func testBottomBarNavigation() {
        let app = XCUIApplication.launchWithCity()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "settings button missing")
        settings.tap()
        XCTAssertTrue(app.staticTexts["Units"].waitForExistence(timeout: 10),
                      "settings screen did not render")

        // The settings screen replaces the pager, so it leaves via its header back arrow.
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Cities"].waitForExistence(timeout: 10),
                      "bottom bar did not return after leaving settings")

        app.buttons["Cities"].tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10),
                      "cities screen did not render after nav")
    }

    /// The diagnostics cover (runtime instrumentation surface).
    func testDiagnosticsScreenOpens() {
        let app = XCUIApplication.launchWithCity()

        let diagnostics = app.buttons["Diagnostics"]
        XCTAssertTrue(diagnostics.waitForExistence(timeout: 15), "diagnostics button missing")
        diagnostics.tap()
        XCTAssertTrue(app.switches.firstMatch.waitForExistence(timeout: 10)
                      || app.buttons["Close"].waitForExistence(timeout: 5),
                      "diagnostics cover did not appear")
    }

    /// Cold-start stability: the app must stay in the foreground while idle.
    func testStaysAliveWhenIdle() {
        let app = XCUIApplication.launchWithCity()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 5)
        XCTAssertEqual(app.state, .runningForeground, "app left the foreground while idle")
    }
}
