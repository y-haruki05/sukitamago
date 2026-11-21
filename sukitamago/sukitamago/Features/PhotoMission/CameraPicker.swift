import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CameraPicker: UIViewControllerRepresentable {
    enum Outcome { case photo(UIImage), cancelled, failed }
    let onResult: (Outcome) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    func makeUIViewController(context: Context) -> UIViewController {
        // Recheck at presentation time. A blank controller avoids accidentally
        // opening UIImagePickerController's default photo-library source on failure.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DispatchQueue.main.async { context.coordinator.finish(.failed) }
            return UIViewController()
        }
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) { }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onResult: (Outcome) -> Void
        private var didFinish = false
        init(onResult: @escaping (Outcome) -> Void) { self.onResult = onResult }
        func finish(_ outcome: Outcome) {
            guard !didFinish else { return }
            didFinish = true
            onResult(outcome)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { finish(.cancelled) }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { finish(.failed); return }
            finish(.photo(image))
        }
    }
}
