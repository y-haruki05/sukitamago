import XCTest

final class ExperienceReflectionUITests: XCTestCase {
    @MainActor
    func testReflectionDraftCompletionAndFreshRetry() {
        continueAfterFailure = false
        // Launch configuration tests can leave the shared Simulator in landscape.
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboardingForUITests"]
        app.launch()
        completeOnboarding(app)
        openMission(app)
        reachReflection(app)
        let finish = app.buttons["reflection.finish"]
        app.swipeUp()
        XCTAssertFalse(finish.isEnabled)
        let fun = app.buttons["reflection.feeling.fun"]
        if !fun.isHittable { app.swipeUp() }
        fun.tap()
        let different = app.buttons["reflection.feeling.notForMe"]
        if !different.isHittable { app.swipeUp() }
        different.tap()
        XCTAssertEqual(different.value as? String, "選択中")
        XCTAssertEqual(fun.value as? String, "未選択")
        let note = app.textViews["reflection.note"]
        if !note.isHittable { app.swipeUp() }
        note.tap()
        note.typeText("  Sky was beautiful.  ")
        app.buttons["キーボードを閉じる"].tap()
        app.navigationBars.buttons["戻る"].tap()
        XCTAssertTrue(app.buttons["mission.confirm"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.buttons["mission.confirm"].tap()
        app.swipeUp()
        XCTAssertEqual(different.value as? String, "選択中")
        if !note.isHittable { app.swipeUp() }
        XCTAssertEqual(note.value as? String, "  Sky was beautiful.  ")
        if !finish.isHittable { app.swipeUp() }
        XCTAssertTrue(finish.isEnabled)
        snapshot(app, name: "振り返り入力")
        finish.tap()
        XCTAssertTrue(app.staticTexts["小さな一歩、おめでとう！"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["自分に合うものを知るための、大切な一歩だよ。"].exists)
        XCTAssertEqual(app.staticTexts["reflection.completedNote"].label, "Sky was beautiful.")
        XCTAssertTrue(app.descendants(matching: .any)["reflection.completedFeeling"].exists)
        snapshot(app, name: "振り返り完了")
        app.swipeUp()
        if !app.buttons["mission.home"].isHittable { app.swipeUp() }
        app.buttons["mission.home"].tap()
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
        openMission(app)
        reachReflection(app)
        app.swipeUp()
        XCTAssertFalse(finish.isEnabled)
        XCTAssertEqual(fun.value as? String, "未選択")
        if !note.isHittable { app.swipeUp() }
        XCTAssertTrue(note.exists)
        XCTAssertEqual(note.value as? String ?? "", "")
    }

    @MainActor private func reachReflection(_ app: XCUIApplication) {
        selectPhoto(app)
        XCTAssertTrue(app.buttons["mission.confirm"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["mission.confirm"].tap()
        XCTAssertTrue(app.staticTexts["やってみて、どうだった？"].waitForExistence(timeout: 5))
    }

    @MainActor private func snapshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
