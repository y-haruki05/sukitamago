import XCTest

final class PhotoMissionUITests: XCTestCase {
    @MainActor
    func testLibraryPreviewRetakeCompletionAndRetry() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboardingForUITests"]
        app.launch()
        completeOnboarding(app)
        openMission(app)
        XCTAssertTrue(app.staticTexts["この環境ではカメラを使えません"].exists)
        capture(app, name: "写真取得")
        app.buttons["mission.library"].tap()
        let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "キャンセル"])).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        XCTAssertTrue(app.buttons["mission.library"].waitForExistence(timeout: 5))
        selectPhoto(app)
        XCTAssertTrue(app.staticTexts["いい瞬間、見つけたね！"].waitForExistence(timeout: 10))
        capture(app, name: "写真プレビュー")
        app.swipeUp()
        app.buttons["mission.retake"].tap()
        selectPhoto(app)
        XCTAssertTrue(app.buttons["mission.confirm"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["mission.confirm"].tap()
        XCTAssertTrue(app.staticTexts["やってみて、どうだった？"].waitForExistence(timeout: 5))
        app.swipeUp()
        let finish = app.buttons["reflection.finish"]
        XCTAssertFalse(finish.isEnabled)
        let choice = app.buttons["reflection.feeling.neutral"]
        if !choice.isHittable { app.swipeUp() }
        choice.tap()
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        XCTAssertTrue(app.staticTexts["小さな一歩、おめでとう！"].waitForExistence(timeout: 5))
        capture(app, name: "体験完了")
        app.swipeUp()
        app.buttons["mission.home"].tap()
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
        openMission(app)
        app.buttons["とじる"].tap()
        XCTAssertTrue(app.buttons["mission.start"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}

extension XCTestCase {
    @MainActor func openMission(_ app: XCUIApplication) {
        let start = app.buttons["startExperience"]
        if !start.isHittable { app.swipeUp() }
        start.tap()
        let mission = app.buttons["mission.start"]
        XCTAssertTrue(mission.waitForExistence(timeout: 5))
        if !mission.isHittable { app.swipeUp() }
        mission.tap()
        let appeared = app.buttons["mission.library"].waitForExistence(timeout: 5)
        if !appeared {
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertTrue(appeared, app.debugDescription)
    }

    @MainActor func selectPhoto(_ app: XCUIApplication) {
        let library = app.buttons["mission.library"]
        let ready = expectation(for: NSPredicate(format: "enabled == true AND hittable == true"), evaluatedWith: library)
        XCTAssertTrue(XCTWaiter.wait(for: [ready], timeout: 5) == .completed, app.debugDescription)
        library.tap()
        // iOS 18's PhotosPicker exposes image grid items, earlier versions use cells.
        let image = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        if image.waitForExistence(timeout: 5) {
            image.tap()
        } else {
            let cell = app.collectionViews.cells.firstMatch
            XCTAssertTrue(cell.waitForExistence(timeout: 5), app.debugDescription)
            cell.tap()
        }
    }
}
