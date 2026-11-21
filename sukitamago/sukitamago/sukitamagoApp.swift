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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        #if DEBUG
        // UI tests can start from a deterministic first-launch state; no release hook.
        if ProcessInfo.processInfo.arguments.contains("-resetOnboardingForUITests") {
            UserDefaults.standard.removeObject(forKey: OnboardingStorage.completed)
            UserDefaults.standard.removeObject(forKey: OnboardingStorage.mood)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
