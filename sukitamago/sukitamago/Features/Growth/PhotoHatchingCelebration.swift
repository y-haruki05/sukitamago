import SwiftUI
import SwiftData

/// Shown only after the record and character transaction has committed.
struct PhotoHatchingCelebration: View {
    let characterID: UUID
    let onFinish: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var played = false
    @State private var showCat = false
    @State private var shake = false
    @State private var animating = false
    @State private var saving = false
    @State private var failed = false

    var body: some View {
        VStack(spacing: 24) {
            EggCharacterView(hatched: showCat || reduceMotion)
                .rotationEffect(.degrees(shake ? 5 : 0))
                .allowsHitTesting(false)
            if showCat || reduceMotion {
                Text("カメラねこが生まれたよ！").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text("好きが見つかったね！")
                Text("図鑑に登録されたよ！").foregroundStyle(AppTheme.secondaryText)
            } else {
                Text("たまごに、小さな変化が…！").font(.title2.bold())
            }
            Text("写真と振り返りも保存しました。「きろく」で見返せるよ。")
                .font(.footnote).foregroundStyle(AppTheme.secondaryText)
            PrimaryButton(title: "次の卵を育てる") {
                guard !saving else { return }
                saving = true
                defer { saving = false }
                do {
                    _ = try EggHatchingStore.startNextEgg(in: context.container, after: characterID)
                    onFinish()
                } catch { failed = true }
            }
            .disabled(animating || saving).accessibilityIdentifier("mission.nextEgg")
        }
        .task {
            guard !played else { return }
            played = true
            guard !reduceMotion else { showCat = true; return }
            animating = true
            defer { showCat = true; shake = false; animating = false }
            withAnimation(.easeInOut(duration: 0.12).repeatCount(4, autoreverses: true)) { shake = true }
            do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
            withAnimation(.easeInOut(duration: 0.3)) { shake = false; showCat = true }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { showCat = true; shake = false; animating = false }
        }
        .alert("新しい卵を準備できませんでした", isPresented: $failed) {
            Button("とじる", role: .cancel) { }
        } message: { Text("もう一度試してください。猫と体験記録は保存されています。") }
    }
}
