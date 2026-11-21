//
//  sukitamagoApp.swift
//  sukitamago
//
//  Created by 山本悠生 on 2026/11/21.
//

import SwiftUI
import SwiftData

@main
struct sukitamagoApp: App {
    private let persistence: Result<(ExperiencePersistence, UserDefaults), Error>

    init() {
        var testID: String?
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-experienceTestStore"), arguments.indices.contains(index + 1) {
            testID = arguments[index + 1]
        }
        #endif
        persistence = Result {
            let defaults = try ExperiencePersistence.preferences(testID: testID)
            let persistence = try ExperiencePersistence.make(testID: testID)
            #if DEBUG
            // Never reset the real preferences when a test-store argument is absent.
            if testID != nil, arguments.contains("-resetOnboardingForUITests") {
                defaults.removeObject(forKey: OnboardingStorage.completed)
                defaults.removeObject(forKey: OnboardingStorage.mood)
            }
            #endif
            return (persistence, defaults)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch persistence {
            case .success(let (persistence, defaults)):
                AppRootView()
                    .defaultAppStorage(defaults)
                    .modelContainer(persistence.container)
                    .environment(\.experiencePhotos, persistence.photos)
            case .failure:
                ContentUnavailableView("記録を開けませんでした", systemImage: "externaldrive.badge.exclamationmark",
                                       description: Text("空き容量などを確認して、アプリを起動し直してください。記録は削除されません。"))
            }
        }
    }
}
