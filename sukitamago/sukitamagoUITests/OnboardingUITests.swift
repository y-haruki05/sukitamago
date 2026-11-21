import XCTest

extension XCTestCase {
    @MainActor
    func tapOnboardingNext(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["onboarding.next"]
        let ready = NSPredicate(format: "exists == true AND enabled == true")
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: ready, evaluatedWith: button)], timeout: 5) == .completed,
                      file: file, line: line)
        button.tap()
    }

    @MainActor
    func completeOnboarding(_ app: XCUIApplication) {
        tapOnboardingNext(app)
        let choice = app.buttons["mood.findInterest"]
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: choice)], timeout: 5) == .completed)
        choice.tap()
        tapOnboardingNext(app)
        tapOnboardingNext(app)
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
    }
}

final class OnboardingUITests: XCTestCase {
    @MainActor
    func testFirstLaunchSelectionBackPersistenceAndReset() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-experienceTestStore", UUID().uuidString, "-resetOnboardingForUITests"]
        app.launch()
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        tapOnboardingNext(app)
        let next = app.buttons["onboarding.next"]
        XCTAssertFalse(next.isEnabled)
        let first = app.buttons["mood.newExperience"]
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: first)], timeout: 5) == .completed)
        first.tap()
        XCTAssertEqual(first.value as? String, "選択中")
        app.buttons["mood.findInterest"].tap()
        XCTAssertEqual(first.value as? String, "未選択")
        XCTAssertEqual(app.buttons["mood.findInterest"].value as? String, "選択中")
        app.buttons["onboarding.back"].tap()
        tapOnboardingNext(app)
        XCTAssertEqual(app.buttons["mood.findInterest"].value as? String, "選択中")
        tapOnboardingNext(app)
        XCTAssertTrue(app.staticTexts["小さな一歩から、始めよう。"].waitForExistence(timeout: 3))
        let back = app.buttons["onboarding.back"]
        XCTAssertTrue(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: back)], timeout: 5) == .completed)
        back.tap()
        XCTAssertEqual(app.buttons["mood.findInterest"].value as? String, "選択中")

        // An interrupted flow must restart at step 1, without a completion write.
        app.terminate()
        app.launchArguments.removeAll { $0 == "-resetOnboardingForUITests" }
        app.launch()
        XCTAssertTrue(app.staticTexts["まだ知らない『好き』に、会いにいこう。"].waitForExistence(timeout: 5))
        tapOnboardingNext(app)
        XCTAssertFalse(app.buttons["onboarding.next"].isEnabled)
        app.terminate()
        app.launch()
        completeOnboarding(app)

        // A normal relaunch must retain completion and reveal the existing home.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["設定"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["ホーム"].exists)
        XCTAssertFalse(app.buttons["onboarding.next"].exists)
        app.buttons["設定"].tap()
        app.alerts.buttons["オンボーディングをリセット"].tap()
        XCTAssertTrue(app.staticTexts["まだ知らない『好き』に、会いにいこう。"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        tapOnboardingNext(app)
        XCTAssertFalse(app.buttons["onboarding.next"].isEnabled)
    }
}
