import Testing
import UIKit
@testable import sukitamago

@MainActor
struct ExperienceReflectionTests {
    private func session() -> PhotoMissionState {
        let state = PhotoMissionState()
        _ = state.beginLoading()
        state.receive(UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in })
        state.confirm()
        return state
    }

    @Test func cannotFinishWithoutPhotoOrFeeling() {
        let empty = PhotoMissionState()
        empty.selectFeeling(.fun)
        empty.finishReflection()
        #expect(empty.phase == .ready)
        #expect(empty.reflection == nil)
        let state = session()
        #expect(state.selectedFeeling == nil)
        #expect(!state.canFinishReflection)
        state.finishReflection()
        #expect(state.phase == .reflecting)
    }

    @Test func singleSelectionAndOptionalNote() {
        let state = session()
        state.selectFeeling(.fun)
        #expect(state.selectedFeeling == .fun)
        state.selectFeeling(.notForMe)
        #expect(state.selectedFeeling == .notForMe)
        #expect(state.canFinishReflection)
        let image = state.photo
        state.finishReflection()
        #expect(state.reflection == ExperienceReflection(feeling: .notForMe, note: ""))
        #expect(state.phase == .completed)
        #expect(state.photo === image)
        state.selectFeeling(.fun)
        state.finishReflection()
        #expect(state.reflection?.feeling == .notForMe)
    }

    @Test func notesLimitGraphemesAndTrimOnlyOnCompletion() {
        let state = session()
        let emoji = "👨‍👩‍👧‍👦"
        state.updateNote(String(repeating: emoji, count: 201))
        #expect(state.note.count == 200)
        #expect(state.note == String(repeating: emoji, count: 200))
        state.updateNote(" \n 空の色がきれいだった。 \n")
        #expect(state.note.hasPrefix(" "))
        state.selectFeeling(.neutral)
        state.finishReflection()
        #expect(state.reflection?.note == "空の色がきれいだった。")
        #expect(ExperienceReflection(feeling: .fun, note: String(repeating: "あ", count: 201)).note.count == 200)
    }

    @Test func draftSurvivesBackButNotRetakeOrNewSession() {
        let state = session()
        let photo = state.photo
        state.selectFeeling(.fun)
        state.updateNote("花が好き")
        state.backToPreview()
        #expect(state.phase == .preview)
        state.confirm()
        #expect(state.selectedFeeling == .fun)
        #expect(state.note == "花が好き")
        #expect(state.photo === photo)
        state.backToPreview()
        state.retake()
        #expect(state.selectedFeeling == nil)
        #expect(state.note.isEmpty)
        #expect(state.photo == nil)
        let next = session()
        #expect(next.selectedFeeling == nil)
        #expect(next.note.isEmpty)
        #expect(next.reflection == nil)
    }

    @Test func everyFeelingHasAffirmingMessage() {
        #expect(ExperienceFeeling.fun.completionMessage == "その『楽しい』が、好きのはじまりかも！")
        #expect(ExperienceFeeling.neutral.completionMessage == "やってみたからこそ、わかったことがあるね。")
        #expect(ExperienceFeeling.notForMe.completionMessage == "自分に合うものを知るための、大切な一歩だよ。")
    }
}
