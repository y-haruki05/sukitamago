import XCTest

final class EggGrowthUITests: XCTestCase {
    @MainActor func testZeroAndHomeNavigation() {
        let app = launch(count: 0)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 0, stage: "はじまり")
        XCTAssertFalse(app.buttons["growth.foundLike"].exists)
        snapshot(app, "成長はじまりSE")
        explore(app)
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
    }

    @MainActor func testThirdExperienceUpdatesAndDeletionRecalculates() { transition(startingAt: 2, stage: "芽生え") }
    @MainActor func testFifthExperienceUpdatesAndDeletionRecalculates() { transition(startingAt: 4, stage: "芽生え") }

    @MainActor func testFunPhotoHatchesAndStartsNextEgg() {
        let app = launch(count: 0)
        snapshot(app, "ホームSE")
        openMission(app); selectPhoto(app)
        let confirm = app.buttons["mission.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        if !confirm.isHittable { app.swipeUp() }
        confirm.tap()
        snapshot(app, "振り返りSE")
        let fun = app.buttons["reflection.feeling.fun"]
        if !fun.isHittable { app.swipeUp() }
        fun.tap()
        let finish = app.buttons["reflection.finish"]
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        XCTAssertTrue(app.staticTexts["カメラねこが生まれたよ！"].waitForExistence(timeout: 10))
        snapshot(app, "カメラねこ孵化SE")
        let next = app.buttons["mission.nextEgg"]
        if !next.isHittable { app.swipeUp() }
        next.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: next)], timeout: 5) == .completed)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 1, stage: "はじまり")
        snapshot(app, "次の卵SE")
        XCTAssertEqual(app.buttons["あなたの好きのたまご"].value as? String, "卵")
        let collection = app.buttons["すきのずかんを見る"]
        if !collection.isHittable { app.swipeUp() }
        collection.tap()
        XCTAssertTrue(app.staticTexts["登録した仲間：1匹"].waitForExistence(timeout: 5))
        snapshot(app, "カメラねこ図鑑SE")
        let cat = app.buttons.containing(.staticText, identifier: "1匹目のカメラねこ").firstMatch
        XCTAssertTrue(cat.waitForExistence(timeout: 5))
        cat.tap()
        XCTAssertTrue(app.staticTexts["カメラねこ"].waitForExistence(timeout: 5))
        snapshot(app, "カメラねこ詳細SE")
    }

    @MainActor func testNeutralPhotoDoesNotHatch() { verifyNoHatching(feeling: "neutral") }
    @MainActor func testNotForMePhotoDoesNotHatch() { verifyNoHatching(feeling: "notForMe") }

    @MainActor private func verifyNoHatching(feeling: String) {
        let app = launch(count: 0)
        openMission(app); selectPhoto(app)
        let confirm = app.buttons["mission.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        if !confirm.isHittable { app.swipeUp() }
        confirm.tap()
        let choice = app.buttons["reflection.feeling.\(feeling)"]
        if !choice.isHittable { app.swipeUp() }
        choice.tap()
        let finish = app.buttons["reflection.finish"]
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        XCTAssertTrue(app.staticTexts["小さな一歩、おめでとう！"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["カメラねこが生まれたよ！"].exists)
        snapshot(app, "通常完了\(feeling)SE")
        let home = app.buttons["mission.home"]
        if !home.isHittable { app.swipeUp() }
        home.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: home)], timeout: 5) == .completed)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 1, stage: "はじまり")
        XCTAssertEqual(app.buttons["あなたの好きのたまご"].value as? String, "卵")
        XCTAssertFalse(app.buttons["growth.nextEgg"].exists)
        let collection = app.buttons["すきのずかんを見る"]
        if !collection.isHittable { app.swipeUp() }
        collection.tap()
        XCTAssertTrue(app.staticTexts["登録した仲間：0匹"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["まだ、図鑑はからっぽ。"].exists)
        snapshot(app, "図鑑未登録\(feeling)SE")
    }

    @MainActor private func launch(count: Int) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-experienceTestStore", UUID().uuidString, "-resetOnboardingForUITests",
                               "-growthTestRecordCount", String(count)]
        app.launch(); completeOnboarding(app)
        return app
    }

    @MainActor private func transition(startingAt count: Int, stage: String) {
        let app = launch(count: count)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count, stage: count < 3 ? "はじまり" : "芽生え")
        explore(app)
        openMission(app); selectPhoto(app)
        let confirm = app.buttons["mission.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        if !confirm.isHittable { app.swipeUp() }
        confirm.tap()
        let feeling = app.buttons["reflection.feeling.notForMe"]
        if !feeling.isHittable { app.swipeUp() }
        feeling.tap()
        let finish = app.buttons["reflection.finish"]
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        XCTAssertTrue(app.staticTexts["小さな一歩、おめでとう！"].waitForExistence(timeout: 10))
        let home = app.buttons["mission.home"]
        if !home.isHittable { app.swipeUp() }
        home.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: home)], timeout: 5) == .completed)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count + 1, stage: stage)
        XCTAssertFalse(app.buttons["growth.foundLike"].exists)
        XCTAssertFalse(app.progressIndicators["growth.progress"].exists)
        snapshot(app, "成長\(stage)SE")
        app.tabBars.buttons["ホーム"].tap()
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count + 1, stage: stage)
        app.terminate()
        app.launchArguments.removeAll { $0 == "-resetOnboardingForUITests" }
        app.launch()
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count + 1, stage: stage)
        app.tabBars.buttons["きろく"].tap()
        let record = app.buttons.matching(identifier: "history.record").firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5)); record.tap()
        let delete = app.buttons["history.delete"]
        if !delete.isHittable { app.swipeUp() }
        delete.tap(); app.buttons["削除する"].tap()
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count, stage: count < 3 ? "はじまり" : "芽生え")
        app.terminate(); app.launch()
        app.tabBars.buttons["たまご"].tap()
        check(app, count: count, stage: count < 3 ? "はじまり" : "芽生え")
    }

    @MainActor private func check(_ app: XCUIApplication, count: Int, stage: String) {
        let label = app.staticTexts["growth.stage"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertEqual(label.label, stage)
        XCTAssertEqual(app.staticTexts["growth.count"].label, "これまでの体験：\(count)回")
    }

    @MainActor private func explore(_ app: XCUIApplication) {
        let button = app.buttons["growth.explore"]
        if !button.isHittable { app.swipeUp() }
        button.tap()
    }

    @MainActor private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
