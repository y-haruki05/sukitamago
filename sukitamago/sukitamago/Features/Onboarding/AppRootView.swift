import SwiftUI

struct AppRootView: View {
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
        .tint(AppTheme.outline)
        .foregroundStyle(AppTheme.text)
    }
}
