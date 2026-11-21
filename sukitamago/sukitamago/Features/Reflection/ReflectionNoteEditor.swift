import SwiftUI
import UIKit

/// Publish only committed text so SwiftUI never replaces an active Japanese IME range.
struct ReflectionNoteEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isComposing: Bool

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        context.coordinator.view = view
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.textColor = UIColor(AppTheme.text)
        view.tintColor = UIColor(AppTheme.outline)
        view.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        view.accessibilityLabel = "ひとこと感想"
        view.accessibilityHint = "任意で200文字まで入力できます"
        view.accessibilityIdentifier = "reflection.note"
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "キーボードを閉じる", style: .done,
                            target: context.coordinator, action: #selector(Coordinator.closeKeyboard))
        ]
        toolbar.sizeToFit()
        view.inputAccessoryView = toolbar
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.view = view
        view.textColor = UIColor(AppTheme.text)
        guard view.markedTextRange == nil, view.text != text else { return }
        view.text = text
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ReflectionNoteEditor
        weak var view: UITextView?
        init(parent: ReflectionNoteEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            guard textView.markedTextRange == nil else {
                parent.isComposing = true
                return
            }
            publish(textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) { publish(textView) }

        private func publish(_ textView: UITextView) {
            let limited = ExperienceReflection.limitedNote(textView.text ?? "")
            if textView.text != limited {
                let selection = textView.selectedRange
                textView.text = limited
                textView.selectedRange = NSRange(location: min(selection.location, limited.utf16.count), length: 0)
            }
            parent.isComposing = false
            parent.text = limited
        }

        @objc func closeKeyboard() { view?.resignFirstResponder() }
    }
}
