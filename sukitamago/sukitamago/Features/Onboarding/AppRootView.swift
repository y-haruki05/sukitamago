import SwiftUI
import SwiftData

struct AppRootView: View {
    @Query private var hatchingStates: [EggHatchingState]
    @AppStorage(OnboardingStorage.completed) private var completed = false
    @AppStorage(OnboardingStorage.mood) private var mood = ""

    var body: some View {
        Group {
            if completed {
                ContentView()
            } else {
                OnboardingView { selection in
                    guard !completed else { return }
                    mood = selection.rawValue
                    completed = true
                }
            }
        }
        .environment(\.eggHasHatched, !hatchingStates.isEmpty)
        .tint(AppTheme.outline)
        .foregroundStyle(AppTheme.text)
    }
}
