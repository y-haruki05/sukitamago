import XCTest

final class sukitamagoUITests: XCTestCase {
    @MainActor
    func testHomeNavigationAndTabs() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-experienceTestStore", UUID().uuidString, "-resetOnboardingForUITests"]
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
        XCTAssertTrue(app.buttons["mission.start"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeUp()
        app.buttons["recommendedExperience"].tap()
        XCTAssertTrue(app.buttons["mission.start"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["さがす"].tap()
        XCTAssertTrue(app.staticTexts["小さな『好き』を探そう"].waitForExistence(timeout: 5))
        app.tabBars.buttons["たまご"].tap()
        XCTAssertEqual(app.staticTexts["growth.stage"].label, "はじまり")
        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.staticTexts["まだ、最初の一歩の前だね。"].waitForExistence(timeout: 5))
        app.tabBars.buttons["ホーム"].tap()
        app.swipeDown()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
