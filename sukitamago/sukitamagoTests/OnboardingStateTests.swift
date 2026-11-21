import Testing
@testable import sukitamago

struct OnboardingStateTests {
    @Test func selectionGateAndTransitionLock() {
        let state = OnboardingState()
        state.advance()
        #expect(state.step == .mood)
        state.advance()
        #expect(state.step == .mood)
        state.finishTransition()
        #expect(!state.canAdvance)
        state.advance()
        #expect(state.step == .mood)
        state.selectedMood = .findInterest
        state.advance()
        #expect(state.step == .firstExperience)
        state.back()
        #expect(state.step == .firstExperience)
        state.finishTransition()
        state.back()
        #expect(state.step == .mood)
        #expect(state.selectedMood == .findInterest)
    }
}
