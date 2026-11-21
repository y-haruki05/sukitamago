import XCTest

final class ExperienceHistoryUITests: XCTestCase {
    @MainActor
    func testSaveRelaunchDetailAndDelete() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-experienceTestStore", UUID().uuidString, "-resetOnboardingForUITests"]
        app.launch()
        completeOnboarding(app)
        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.staticTexts["まだ、最初の一歩の前だね。"].waitForExistence(timeout: 5))
        let explore = app.buttons["history.explore"]
        if !explore.isHittable { app.swipeUp() }
        explore.tap()
        openMission(app)
        selectPhoto(app)
        let confirm = app.buttons["mission.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        if !confirm.isHittable { app.swipeUp() }
        confirm.tap()
        let feeling = app.buttons["reflection.feeling.fun"]
        if !feeling.isHittable { app.swipeUp() }
        feeling.tap()
        let note = app.textViews["reflection.note"]
        if !note.isHittable { app.swipeUp() }
        note.tap(); note.typeText("A small beautiful moment.")
        app.buttons["キーボードを閉じる"].tap()
        let finish = app.buttons["reflection.finish"]
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        XCTAssertTrue(app.staticTexts["カメラねこが生まれたよ！"].waitForExistence(timeout: 10))
        let home = app.buttons["mission.nextEgg"]
        if !home.isHittable { app.swipeUp() }
        home.tap()
        // The tab bar is already in the underlying hierarchy during cover dismissal.
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "exists == false"),
                                                     evaluatedWith: home)], timeout: 5) == .completed)
        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.buttons["history.record"].waitForExistence(timeout: 5))
        snapshot(app, "履歴一覧SE")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-resetOnboardingForUITests" }
        app.launch()
        app.tabBars.buttons["きろく"].tap()
        let card = app.buttons["history.record"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.navigationBars["あなたの小さな一歩"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["history.photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["楽しかった！"].exists)
        let savedNote = app.staticTexts["history.note"]
        if !savedNote.isHittable { app.swipeUp() }
        XCTAssertEqual(savedNote.label, "A small beautiful moment.")
        snapshot(app, "履歴詳細SE")
        let delete = app.buttons["history.delete"]
        if !delete.isHittable { app.swipeUp() }
        delete.tap()
        app.buttons["キャンセル"].tap()
        XCTAssertTrue(delete.exists)
        delete.tap()
        app.buttons["削除する"].tap()
        XCTAssertTrue(app.staticTexts["まだ、最初の一歩の前だね。"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["history.record"].exists)
        app.terminate(); app.launch()
        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.staticTexts["まだ、最初の一歩の前だね。"].waitForExistence(timeout: 5))
    }

    @MainActor private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
