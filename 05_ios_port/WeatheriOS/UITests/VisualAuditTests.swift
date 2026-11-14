import XCTest

/// Visual audit walk-through. Not an assertion suite — it drives every surface
/// in a fixed order and attaches a full-resolution screenshot for each, so the
/// cosmetics can be reviewed against the Android original outside of XCTest.
///
/// Run with: xcodebuild test ... -only-testing:WeatheriOSUITests/VisualAuditTests
/// then export the attachments (see 07_tools/visual-audit.sh).
final class VisualAuditTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // Excluded from ordinary runs by 07_tools/macos-tests.sh (-skip-testing):
    // it asserts nothing, costs ~60 s and writes 8 screenshots. Run it through
    // 07_tools/visual-audit.sh, which targets it with -only-testing.
    func testCaptureAllSurfaces() {
        let app = XCUIApplication.weather()

        // 1. Empty state (city screen with the "Weather / Your day, at a glance." hero).
        XCTAssertTrue(app.staticTexts["Weather"].waitForExistence(timeout: 20))
        shot(app, "audit-01-empty")

        // 2. Search results as glass cards.
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Tokyo")
        _ = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Tokyo'"))
            .firstMatch.waitForExistence(timeout: 20)
        Thread.sleep(forTimeInterval: 2.5)
        shot(app, "audit-02-search-results")

        // 3. Forecast page + bottom bar.
        let tokyoRow = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Tokyo'")).firstMatch
        if tokyoRow.exists { tokyoRow.tap() } else { app.staticTexts["Tokyo"].firstMatch.tap() }
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 25))
        Thread.sleep(forTimeInterval: 4)
        shot(app, "audit-03-forecast")

        // 4. Scrolled forecast (metric grid + 10-day list).
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.5)
        shot(app, "audit-04-forecast-scrolled")

        // 5. Settings, top of the list (Units card must be ONE panel).
        app.buttons["Settings"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot(app, "audit-05-settings-top")

        // 6. Settings, scrolled (attribution + footer + diagnostics).
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.2)
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.2)
        shot(app, "audit-06-settings-bottom")

        // 7. Cities screen (glass rows, not list chrome).
        app.buttons["Back"].tap()
        Thread.sleep(forTimeInterval: 1)
        app.buttons["Cities"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot(app, "audit-07-cities")
        app.buttons["Back"].tap()
        Thread.sleep(forTimeInterval: 1)

        // 8. Map, captured twice: while the radar window is playing (playhead at
        // the oldest frame) and after it stops on the newest frame.
        app.buttons["Map"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        shot(app, "audit-08-map-playing")
        // The window is ~13 frames at 0.7 s each (~10 s); wait past that so the
        // settled capture shows the finished state.
        Thread.sleep(forTimeInterval: 13)
        shot(app, "audit-09-map-settled")
    }
}
