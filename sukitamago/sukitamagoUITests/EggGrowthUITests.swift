import XCTest

final class EggGrowthUITests: XCTestCase {
    @MainActor func testZeroAndHomeNavigation() {
        let app = launch(count: 0)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 0, stage: "はじまり")
        XCTAssertTrue(app.buttons["growth.foundLike"].exists)
        snapshot(app, "成長はじまりSE")
        explore(app)
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
    }

    @MainActor func testThirdExperienceUpdatesAndDeletionRecalculates() { transition(startingAt: 2, stage: "芽生え") }
    @MainActor func testFifthExperienceUpdatesAndDeletionRecalculates() { transition(startingAt: 4, stage: "芽生え") }

    @MainActor func testExplicitHatchingPersistsAfterRelaunchAndHistoryDeletion() {
        let app = launch(count: 5)
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 5, stage: "芽生え")
        let character = app.buttons["あなたの好きのたまご"]
        XCTAssertEqual(character.value as? String, "卵")
        snapshot(app, "孵化前の卵SE")
        let found = app.buttons["growth.foundLike"]
        if !found.isHittable { app.swipeUp() }
        found.tap()
        app.buttons["まだ探してみる"].tap()
        XCTAssertEqual(app.staticTexts["growth.stage"].label, "芽生え")
        XCTAssertEqual(character.value as? String, "卵")
        found.tap()
        app.buttons["見つかった！"].tap()
        let hatched = NSPredicate(format: "label == %@", "孵化")
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: hatched,
            evaluatedWith: app.staticTexts["growth.stage"])], timeout: 5) == .completed)
        let ready = NSPredicate(format: "exists == true AND enabled == true")
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: ready,
            evaluatedWith: app.buttons["growth.explore"])], timeout: 5) == .completed)
        XCTAssertEqual(character.value as? String, "猫")
        XCTAssertFalse(found.exists)
        app.swipeDown()
        snapshot(app, "孵化後の猫SE")
        app.tabBars.buttons["ホーム"].tap()
        XCTAssertEqual(app.buttons["あなたの好きのたまご"].value as? String, "猫")
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 5, stage: "孵化")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-resetOnboardingForUITests" }
        app.launch()
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 5, stage: "孵化")
        XCTAssertEqual(character.value as? String, "猫")
        app.tabBars.buttons["きろく"].tap()
        let record = app.buttons.matching(identifier: "history.record").firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5)); record.tap()
        let delete = app.buttons["history.delete"]
        if !delete.isHittable { app.swipeUp() }
        delete.tap(); app.buttons["削除する"].tap()
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        app.tabBars.buttons["たまご"].tap()
        check(app, count: 4, stage: "孵化")
        XCTAssertEqual(character.value as? String, "猫")
        XCTAssertFalse(found.exists)
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
        XCTAssertTrue(app.buttons["growth.foundLike"].exists)
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
