import SwiftUI
import UIKit
import Testing
@testable import sukitamago

@MainActor
struct ReflectionNoteEditorTests {
    @Test func markedTextIsPreservedUntilCompositionCommits() {
        var committed = ""
        var composing = false
        let editor = ReflectionNoteEditor(text: Binding(get: { committed }, set: { committed = $0 }),
                                          isComposing: Binding(get: { composing }, set: { composing = $0 }))
        let coordinator = editor.makeCoordinator()
        let view = UITextView()
        view.setMarkedText(String(repeating: "あ", count: 201), selectedRange: NSRange(location: 201, length: 0))
        coordinator.textViewDidChange(view)
        #expect(view.markedTextRange != nil)
        #expect(view.text.count == 201)
        #expect(committed.isEmpty)
        #expect(composing)
        view.unmarkText()
        coordinator.textViewDidChange(view)
        #expect(committed.count == 200)
        #expect(view.text.count == 200)
        #expect(!composing)
    }
}
