import SwiftUI
import PhotosUI

struct PhotoMissionView: View {
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var state: PhotoMissionState
    @State private var showsCamera = false
    @State private var showsLibrary = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingCameraResult: CameraPicker.Outcome?
    @State private var work: Task<Void, Never>?
    @State private var operationID = UUID()

    init(experience: SmallExperience = .first, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        _state = State(initialValue: PhotoMissionState(experience: experience))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch state.phase {
                    case .preview: preview
                    case .reflecting: ExperienceReflectionView(state: state)
                    case .completed: completion
                    default: acquisition
                    }
                }
                .multilineTextAlignment(.center)
                .padding(AppTheme.pagePadding).padding(.top, 16)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            // A new step starts at the top rather than inheriting a scrolled preview.
            .id(state.phase)
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background)
            .navigationTitle(state.phase == .completed ? "体験完了" : "あなたの小さな体験")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if state.phase != .completed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(state.phase == .preview || state.phase == .reflecting ? "戻る" : "とじる") {
                            if state.phase == .reflecting {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                to: nil, from: nil, for: nil)
                                state.backToPreview()
                            }
                            else if state.phase == .preview { state.retake() }
                            else { dismiss() }
                        }.frame(minHeight: 44)
                    }
                }
            }
        }
        .tint(AppTheme.outline).foregroundStyle(AppTheme.text)
        .fullScreenCover(isPresented: $showsCamera, onDismiss: handleCameraDismissal) {
            CameraPicker { result in
                pendingCameraResult = result
                showsCamera = false
            }.ignoresSafeArea()
        }
        .photosPicker(isPresented: $showsLibrary, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            load(item)
        }
        .alert("写真についてのお知らせ", isPresented: Binding(
            get: { state.notice != nil }, set: { if !$0 { state.notice = nil } }
        )) {
            if state.notice?.offersSettings == true {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("とじる", role: .cancel) { state.notice = nil }
        } message: { Text(state.notice?.message ?? "") }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            operationID = UUID()
            work?.cancel()
            pendingCameraResult = nil
            showsCamera = false
            showsLibrary = false
            selectedItem = nil
            state.interrupt()
        }
        .onDisappear { operationID = UUID(); work?.cancel() }
    }

    private var acquisition: some View {
        VStack(spacing: 24) {
            CameraIllustration().padding(16)
            Text("あなたの『きれい』を1枚")
                .font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text("上手に撮れなくても大丈夫。\nちょっといいな、と思った瞬間を写してみよう。")
                .foregroundStyle(AppTheme.secondaryText)
            if !CameraAccess.isAvailable {
                Label("この環境ではカメラを使えません", systemImage: "camera.badge.ellipsis")
                    .font(.subheadline.weight(.medium))
                Text("写真ライブラリから、お気に入りの1枚を選んで体験してみよう。")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
            }
            if state.isBusy { ProgressView("写真を準備しています…") }
            if CameraAccess.isAvailable {
                PrimaryButton(title: "写真を撮る", action: openCamera)
                    .disabled(state.isBusy || showsCamera || showsLibrary)
                    .accessibilityIdentifier("mission.camera")
            }
            if !CameraAccess.isAvailable {
                PrimaryButton(title: "写真ライブラリから選ぶ", action: openLibrary)
                    .disabled(state.isBusy || showsLibrary)
                    .accessibilityIdentifier("mission.library")
            } else {
                Button(action: openLibrary) {
                    Text("写真ライブラリから選ぶ")
                        .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(state.isBusy || showsCamera || showsLibrary)
                .accessibilityIdentifier("mission.library")
            }
            temporaryNotice
        }
    }

    private var preview: some View {
        VStack(spacing: 24) {
            Text("いい瞬間、見つけたね！").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text("あなたが見つけた『きれい』を残しておこう。")
                .foregroundStyle(AppTheme.secondaryText)
            photo(maxHeight: 350)
            temporaryNotice
            PrimaryButton(title: "この写真にする") { state.confirm() }
                .disabled(state.photo == nil).accessibilityIdentifier("mission.confirm")
            Button {
                selectedItem = nil
                state.retake()
            } label: {
                Text("撮り直す").frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityIdentifier("mission.retake")
        }
    }

    private var completion: some View {
        VStack(spacing: 24) {
            EggCharacterView(expression: .happy)
            Text("小さな一歩、おめでとう！").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            if let reflection = state.reflection {
                Text(reflection.feeling.completionMessage).foregroundStyle(AppTheme.secondaryText)
                Label(reflection.feeling.title, systemImage: "checkmark.circle")
                    .font(.headline).accessibilityIdentifier("reflection.completedFeeling")
                if !reflection.note.isEmpty {
                    Text(reflection.note).font(.body).padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityIdentifier("reflection.completedNote")
                }
            }
            photo(maxHeight: 160)
            Text("写真と回答は、この体験中だけ表示されます。保存はされません。")
                .font(.footnote).foregroundStyle(AppTheme.secondaryText)
            PrimaryButton(title: "ホームに戻る", action: onFinish)
                .accessibilityIdentifier("mission.home")
        }
    }

    @ViewBuilder private func photo(maxHeight: CGFloat) -> some View {
        if let image = state.photo {
            Image(uiImage: image).resizable().scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("あなたが見つけた『きれい』の写真")
        }
    }

    private var temporaryNotice: some View {
        Text("写真はこの体験中だけ表示されます。\nアプリや写真ライブラリには保存されません。")
            .font(.footnote).foregroundStyle(AppTheme.secondaryText)
    }

    private func openLibrary() {
        guard !state.isBusy, !showsCamera, !showsLibrary else { return }
        selectedItem = nil
        showsLibrary = true
    }

    private func openCamera() {
        guard !showsCamera, !showsLibrary, state.beginPermissionRequest() else { return }
        guard CameraAccess.isAvailable else { state.resolveCamera(.unavailable); return }
        let id = UUID()
        operationID = id
        work = Task { @MainActor in
            let decision = await CameraAccess.request()
            guard !Task.isCancelled, operationID == id else { return }
            state.resolveCamera(decision)
            if state.phase == .capturing { showsCamera = true }
        }
    }

    private func handleCameraDismissal() {
        guard let result = pendingCameraResult else { state.cancelCapture(); return }
        pendingCameraResult = nil
        switch result {
        case .photo(let image): state.receive(image)
        case .cancelled: state.cancelCapture()
        case .failed: state.fail("写真を受け取れませんでした。もう一度撮影するか、写真を選び直してください。")
        }
    }

    private func load(_ item: PhotosPickerItem) {
        guard state.beginLoading() else { return }
        let id = UUID()
        operationID = id
        work = Task { @MainActor in
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = await MissionPhotoLoader.image(from: data) else {
                    if !Task.isCancelled, operationID == id {
                        state.fail("写真を読み込めませんでした。別の写真を選んでみてください。")
                    }
                    return
                }
                guard !Task.isCancelled, operationID == id else { return }
                state.receive(image)
            } catch {
                guard !Task.isCancelled, operationID == id else { return }
                state.fail("写真を読み込めませんでした。通信状態を確認するか、別の写真を選んでみてください。")
            }
        }
    }
}
