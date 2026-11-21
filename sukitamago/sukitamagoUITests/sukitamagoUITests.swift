import XCTest

final class sukitamagoUITests: XCTestCase {
    @MainActor
    func testHomeNavigationAndTabs() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboardingForUITests"]
        app.launch()
        completeOnboarding(app)
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 10))
        app.buttons["設定"].tap()
        XCTAssertTrue(app.alerts["設定は準備中です"].exists)
        app.alerts.buttons["とじる"].tap()
        app.buttons["あなたの好きのたまご"].tap()
        let start = app.buttons["startExperience"]
        if !start.isHittable { app.swipeUp() }
        start.tap()
        XCTAssertTrue(app.staticTexts["写真ミッションは準備中です"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeUp()
        app.buttons["recommendedExperience"].tap()
        XCTAssertTrue(app.staticTexts["写真ミッションは準備中です"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        for title in ["さがす", "たまご", "きろく"] {
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(app.staticTexts["\(title)は準備中です"].exists)
        }
        app.tabBars.buttons["ホーム"].tap()
        app.swipeDown()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
