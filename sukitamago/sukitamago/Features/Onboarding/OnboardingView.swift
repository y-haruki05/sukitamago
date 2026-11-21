import SwiftUI

struct OnboardingView: View {
    let onComplete: (StartingMood) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state = OnboardingState()
    @State private var finishing = false
    @AccessibilityFocusState private var headingFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if state.step != .mood { EggCharacterView() }
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($headingFocused)
                    Text(description)
                        .font(.body).foregroundStyle(AppTheme.secondaryText)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                if state.step == .mood {
                    moodChoices
                } else if state.step == .firstExperience {
                    // Informational preview, not a link to the unfinished mission.
                    ExperienceCard(experience: .first)
                        .font(.caption).foregroundStyle(AppTheme.secondaryText)
                    Text("趣味を決めなくても大丈夫。\nまずは、ちょっと試すだけでいいよ。")
                        .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(AppTheme.pagePadding).padding(.top, 24)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
            .id(state.step)
            .transition(.opacity)
        }
        .background(AppTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .task(id: state.step) {
            // Lock controls through the transition to prevent rapid taps skipping a page.
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            state.finishTransition()
            headingFocused = true
        }
    }

    private var moodChoices: some View {
        VStack(spacing: 14) {
            ForEach(StartingMood.allCases) { mood in
                let selected = state.selectedMood == mood
                Button { state.selectedMood = mood } label: {
                    HStack(spacing: 14) {
                        Image(systemName: mood.symbol).font(.title3)
                            .foregroundStyle(AppTheme.outline).frame(width: 28)
                        Text(mood.title).font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? AppTheme.outline : AppTheme.secondaryText)
                    }
                    .padding(20).frame(minHeight: 72)
                    .background(selected ? AppTheme.lightBlue : AppTheme.subBackground,
                                in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22)
                        .stroke(selected ? AppTheme.outline : AppTheme.lightBlue, lineWidth: selected ? 2 : 1))
                    .contentShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.title)
                .accessibilityValue(selected ? "選択中" : "未選択")
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("mood.\(mood.rawValue)")
            }
        }
        .disabled(state.isTransitioning)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                ForEach(0..<3) { index in
                    Circle().fill(index == state.step.rawValue ? AppTheme.outline : AppTheme.lightBlue)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("ステップ\(state.step.rawValue + 1)、全3ステップ")
            PrimaryButton(title: buttonTitle) {
                guard !state.isTransitioning, !finishing else { return }
                if state.step == .firstExperience {
                    guard let mood = state.selectedMood else { return }
                    finishing = true
                    onComplete(mood)
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { state.advance() }
                }
            }
            .disabled(!state.canAdvance || state.isTransitioning || finishing)
            .opacity(state.canAdvance && !state.isTransitioning ? 1 : 0.5)
            .accessibilityIdentifier("onboarding.next")
            if state.step != .welcome {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { state.back() }
                } label: {
                    Text("戻る").font(.body.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(state.isTransitioning || finishing)
                .accessibilityIdentifier("onboarding.back")
            }
        }
        .padding(.horizontal, AppTheme.pagePadding).padding(.vertical, 12)
        .frame(maxWidth: 600).frame(maxWidth: .infinity)
        .background(AppTheme.background)
    }

    private var title: String {
        switch state.step {
        case .welcome: "まだ知らない『好き』に、会いにいこう。"
        case .mood: "今、どんな気分？"
        case .firstExperience: "小さな一歩から、始めよう。"
        }
    }
    private var description: String {
        switch state.step {
        case .welcome: "小さな体験を重ねながら、あなただけの『好き』を育てていこう。"
        case .mood: "今の気持ちに近いものを選んでね。"
        case .firstExperience: "まずは、身近な『きれい』を探してみよう。"
        }
    }
    private var buttonTitle: String {
        switch state.step {
        case .welcome: "はじめる"
        case .mood: "次へ"
        case .firstExperience: "すきたまごを始める"
        }
    }
}

#Preview { OnboardingView { _ in } }
