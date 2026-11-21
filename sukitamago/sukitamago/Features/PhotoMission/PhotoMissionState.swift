import SwiftUI
import AVFoundation

/// The draft shares one image; completion is published only after durable saving.
@MainActor @Observable
final class PhotoMissionState {
    enum Phase: Hashable { case ready, requestingPermission, capturing, loading, preview, reflecting, completed }
    enum CameraDecision { case available, unavailable, denied, restricted }
    struct Notice: Identifiable {
        let id = UUID()
        let message: String
        var offersSettings = false
    }
    private(set) var phase: Phase = .ready
    private(set) var photo: UIImage?
    let sessionID = UUID()
    private(set) var isSaving = false
    let experience: SmallExperience
    private(set) var selectedFeeling: ExperienceFeeling?
    private(set) var note = ""
    private(set) var hatchedCharacterID: UUID?
    private(set) var reflection: ExperienceReflection?
    var notice: Notice?

    init(experience: SmallExperience = .first) { self.experience = experience }

    var canFinishReflection: Bool { phase == .reflecting && photo != nil && selectedFeeling != nil && !isSaving }

    func selectFeeling(_ feeling: ExperienceFeeling) {
        guard phase == .reflecting, !isSaving else { return }
        selectedFeeling = feeling
    }

    func updateNote(_ value: String) {
        guard phase == .reflecting, !isSaving else { return }
        note = ExperienceReflection.limitedNote(value)
    }

    func backToPreview() {
        guard phase == .reflecting, !isSaving, photo != nil else { return }
        phase = .preview
    }

    func finishReflection(using store: ExperienceRecordStore) async {
        guard canFinishReflection, let feeling = selectedFeeling, let photo else { return }
        isSaving = true
        defer { isSaving = false }
        let result = ExperienceReflection(feeling: feeling, note: note)
        await Task.yield()
        do {
            hatchedCharacterID = try store.save(id: sessionID, experience: experience, photo: photo, reflection: result)
            reflection = result
            phase = .completed
        } catch {
            notice = Notice(message: "記録を保存できませんでした。空き容量などを確認して、もう一度『振り返りを終える』を押してください。写真と回答はそのまま残っています。")
        }
    }

    var isBusy: Bool { phase == .requestingPermission || phase == .capturing || phase == .loading }

    func beginPermissionRequest() -> Bool {
        guard phase == .ready, experience.execution == .photo else { return false }
        phase = .requestingPermission
        return true
    }

    func resolveCamera(_ decision: CameraDecision) {
        guard phase == .requestingPermission else { return }
        switch decision {
        case .available: phase = .capturing
        case .unavailable:
            fail("この環境ではカメラを使えません。写真ライブラリから1枚選んで体験できます。")
        case .denied:
            fail("カメラへのアクセスが許可されていません。設定アプリでカメラを許可してください。", settings: true)
        case .restricted:
            fail("この端末ではカメラの利用が制限されています。端末の利用制限を確認してください。")
        }
    }

    func beginLoading() -> Bool {
        guard phase == .ready, experience.execution == .photo else { return false }
        phase = .loading
        return true
    }

    func receive(_ image: UIImage) {
        guard phase == .capturing || phase == .loading else { return }
        photo = image
        phase = .preview
    }

    func cancelCapture() { if phase == .capturing { phase = .ready } }

    func fail(_ message: String, settings: Bool = false) {
        phase = .ready
        notice = Notice(message: message, offersSettings: settings)
    }

    func retake() {
        guard phase == .preview else { return }
        photo = nil
        selectedFeeling = nil
        note = ""
        reflection = nil
        phase = .ready
    }

    func confirm() {
        guard phase == .preview, photo != nil else { return }
        phase = .reflecting
    }

    func interrupt() {
        if isBusy { phase = .ready }
    }
}

enum CameraAccess {
    @MainActor static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        // Some Simulator runtimes report camera support without an iPhone camera.
        // Keep Simulator verification on the explicit PhotosPicker path.
        return false
        #else
        return UIImagePickerController.isSourceTypeAvailable(.camera)
        #endif
    }

    static func request() async -> PhotoMissionState.CameraDecision {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .available
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .available : .denied
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .restricted
        }
    }
}
