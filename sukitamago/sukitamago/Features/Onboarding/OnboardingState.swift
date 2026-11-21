import SwiftUI

/// Stable raw values are persistence identifiers, independent of display copy.
enum StartingMood: String, CaseIterable, Identifiable {
    case newExperience, findInterest, justTry
    var id: String { rawValue }
    var title: String {
        switch self {
        case .newExperience: "何か新しいことを始めたい！"
        case .findInterest: "好きなことを見つけたい"
        case .justTry: "とりあえず試してみたい"
        }
    }
    var symbol: String {
        switch self {
        case .newExperience: "sparkles"
        case .findInterest: "heart"
        case .justTry: "leaf"
        }
    }
}

enum OnboardingStorage {
    static let completed = "onboarding.completed"
    static let mood = "onboarding.startingMood"
}

@Observable
final class OnboardingState {
    enum Step: Int { case welcome, mood, firstExperience }
    private(set) var step: Step = .welcome
    var selectedMood: StartingMood?
    private(set) var isTransitioning = false

    var canAdvance: Bool { step != .mood || selectedMood != nil }

    func advance() {
        guard !isTransitioning, canAdvance,
              let next = Step(rawValue: step.rawValue + 1) else { return }
        isTransitioning = true
        step = next
    }

    func back() {
        guard !isTransitioning, let previous = Step(rawValue: step.rawValue - 1) else { return }
        isTransitioning = true
        step = previous
    }

    func finishTransition() { isTransitioning = false }
}
