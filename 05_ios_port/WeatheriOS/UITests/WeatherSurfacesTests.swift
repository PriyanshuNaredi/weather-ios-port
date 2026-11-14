import XCTest

/// Coverage for the surfaces the Linux pipeline could never exercise: the
/// hand-rolled Web-Mercator map (the watchdog freeze reproducer), the settings
/// screen and the bundled `legal/` texts (a SwiftPM `.copy` resource that has to
/// be re-plumbed as a folder reference in the Xcode target).
final class WeatherSurfacesTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// The historic defect: panning a mostly-cached map spun a MainActor task
    /// loop forever, freezing the UI until the watchdog killed the app. The fix
    /// added an `iteratorExhausted` flag. This test pans/zooms repeatedly and
    /// then proves the UI is still responsive by navigating with a tap.
    func testMapPanAndZoomStaysResponsive() {
        let app = XCUIApplication.launchWithCity()

        let mapButton = app.buttons["Map"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 15), "Map entry point missing from the bottom bar")
        mapButton.tap()

        let map = app.otherElements.containing(
            NSPredicate(format: "label BEGINSWITH 'Weather map centered on'")).firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 25), "map view did not appear")
        attach(app, "01-map-initial")

        // Let the first tile batch land, then pan across cached and uncached areas.
        Thread.sleep(forTimeInterval: 4)
        for i in 1...6 {
            let start = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + 0.09 * Double(i % 3 - 1),
                                                                  dy: 0.5 + 0.07 * Double(i % 2)))
            start.press(forDuration: 0.05, thenDragTo: end)
            Thread.sleep(forTimeInterval: 1.0)
        }
        attach(app, "02-map-after-pans")

        // Back to a cached area and zoom in/out — the freeze trigger combined
        // "most tiles cached" with "few pending than the concurrency limit".
        // NOTE: a synthesized pinch can be claimed by a simulator system gesture
        // (observed: it backgrounded the app and surfaced another app), so a
        // background state is recovered from, while .notRunning would be a crash.
        map.pinch(withScale: 2.0, velocity: 2.0)
        Thread.sleep(forTimeInterval: 1.5)
        if app.state == .runningBackground { app.activate(); Thread.sleep(forTimeInterval: 2) }
        map.pinch(withScale: 0.5, velocity: -2.0)
        Thread.sleep(forTimeInterval: 1.5)
        if app.state == .runningBackground { app.activate(); Thread.sleep(forTimeInterval: 2) }
        attach(app, "03-map-after-zoom")

        // The watchdog symptom was dead buttons. A tap must still navigate.
        XCTAssertNotEqual(app.state, .notRunning, "app died after map gestures")
        let back = app.buttons["Back"]
        XCTAssertTrue(back.waitForExistence(timeout: 10), "map Back button vanished")
        back.tap()
        XCTAssertTrue(app.buttons["Map"].waitForExistence(timeout: 15),
                      "UI was unresponsive after map gestures (Back did not return to the forecast)")
    }

    /// Settings: units switch round-trip and the bundled legal texts.
    /// The page indicator must sit on the screen's centre line. Kotlin's
    /// asymmetric bar (one icon left, two right) centres the dots in the leftover
    /// gap instead, which put them 24 pt left of centre on a 393 pt screen.
    func testPageIndicatorIsCentred() {
        let app = XCUIApplication.launchWithCity()

        let dots = app.otherElements["Page indicator"]
        XCTAssertTrue(dots.waitForExistence(timeout: 20), "page indicator missing")
        let screenMid = app.windows.firstMatch.frame.midX
        XCTAssertEqual(dots.frame.midX, screenMid, accuracy: 1.0,
                       "page indicator is \(dots.frame.midX - screenMid) pt off centre")
        XCTAssertEqual(dots.frame.height, 8, accuracy: 1.0, "dot size should be 8 pt")
    }

    func testSettingsUnitsAndLegalTexts() {
        let app = XCUIApplication.launchWithCity()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "Settings button missing")
        settings.tap()

        // The units row is a Button with a custom switch (the SwiftUI Toggle never
        // fired here), so the state is exposed as its accessibility value.
        let units = app.buttons["Use imperial units"]
        XCTAssertTrue(units.waitForExistence(timeout: 10), "units switch missing")
        XCTAssertEqual(units.value as? String, "Off", "expected metric to be the default")
        attach(app, "04-settings")

        units.tap()
        XCTAssertTrue(app.staticTexts["Fahrenheit · mph · inches"].waitForExistence(timeout: 10)
                      || (units.value as? String) == "On",
                      "imperial toggle did not take effect")

        // Legal texts come from the bundled `legal/` folder reference.
        let licenses = app.buttons["Open-source licenses"]
        XCTAssertTrue(licenses.waitForExistence(timeout: 10), "licenses button missing")
        licenses.tap()
        XCTAssertTrue(app.staticTexts["Open-source licenses"].waitForExistence(timeout: 10),
                      "licenses sheet did not open")
        // Apache-2.0.txt must have been found in the bundle, i.e. the resource copy worked.
        let apache = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Apache'")).firstMatch
        XCTAssertTrue(apache.waitForExistence(timeout: 10),
                      "bundled legal texts were not found in the app bundle (legal/ resource copy broken)")
        attach(app, "05-legal")

        app.buttons["Done"].tap()
        // Restore metric so the simulator state stays comparable between runs.
        if (units.value as? String) == "On" { units.tap() }
        XCTAssertEqual(units.value as? String, "Off")
    }

    /// Metric detail screens (Workstream D) and pager navigation between cities.
    func testMetricDetailAndCityPager() {
        let app = XCUIApplication.launchWithCity()

        // Add a second city to exercise the pager.
        app.buttons["Cities"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Tokyo")
        let tokyo = app.staticTexts["Tokyo"].firstMatch
        XCTAssertTrue(tokyo.waitForExistence(timeout: 25), "second geocoding search failed")
        tokyo.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label ENDSWITH '°'")).firstMatch
                        .waitForExistence(timeout: 40), "second city forecast never rendered")
        attach(app, "06-second-city")

        // Scroll to the metric grid and open a metric detail screen.
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)

        let humidity = app.staticTexts["HUMIDITY"].firstMatch
        guard humidity.waitForExistence(timeout: 10) else {
            // Grid is below the fold on some sizes; one more scroll, then require it.
            app.swipeUp()
            XCTAssertTrue(humidity.waitForExistence(timeout: 10), "metric grid (HUMIDITY tile) not found")
            return
        }
        humidity.tap()
        attach(app, "07-metric-detail")
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 10),
                      "metric detail screen did not open / no way back")
        app.buttons["Back"].tap()
        XCTAssertNotEqual(app.state, .notRunning, "app died after closing a metric detail screen")
    }
}
