import XCTest

final class SlipUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDashboardNavigationAndDock() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify Floating Dock elements exist
        XCTAssertTrue(app.buttons["house.fill"].exists, "Home dock icon should exist")
        XCTAssertTrue(app.buttons["qrcode.viewfinder"].exists, "Scan dock icon should exist")
        XCTAssertTrue(app.buttons["slider.horizontal.3"].exists, "Settings dock icon should exist")
        XCTAssertTrue(app.buttons["New Pass"].exists, "New Pass dock button should exist")

        // Test navigation to Scanner
        app.buttons["qrcode.viewfinder"].tap()
        XCTAssertTrue(app.staticTexts["Scan Pass"].exists || app.buttons["Cancel"].exists, "Should navigate to Scanner")

        // Test navigation back to Home
        app.buttons["Cancel"].tap() // Or tap Home dock icon if visible
        app.buttons["house.fill"].tap()
        
        // Test navigation to Settings
        app.buttons["slider.horizontal.3"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists || app.staticTexts["Account"].exists, "Should navigate to Settings")
    }
}
