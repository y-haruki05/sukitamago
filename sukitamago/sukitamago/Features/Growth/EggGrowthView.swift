import SwiftUI
import SwiftData

struct EggGrowthView: View {
    let growth: EggGrowth
    let onExplore: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirming = false
    @State private var failed = false
    @State private var saving = false
    @State private var hatching = false
    @State private var showCat = false
    @State private var shake = false
    @State private var opacity = 1.0
    @State private var previousStage = EggGrowthStage.beginning
    @State private var animationTask: Task<Void, Never>?

    private var displayedStage: EggGrowthStage { hatching && !showCat ? previousStage : growth.stage }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("あなたのすきたまご").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text("小さな体験から、あなたの『好き』を育てよう。")
                        .foregroundStyle(AppTheme.secondaryText)
                    VStack(spacing: 20) {
                        mascot
                        Text(displayedStage.title).font(.title2.bold()).foregroundStyle(AppTheme.outline)
                            .accessibilityIdentifier("growth.stage")
                        Text(displayedStage.message).foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22).frame(maxWidth: .infinity)
                    .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.cardRadius).stroke(AppTheme.lightBlue))
                    Text("これまでの体験：\(growth.experienceCount)回").font(.headline)
                        .accessibilityIdentifier("growth.count")
                    if !growth.stage.showsCat {
                        Text("回数よりも、あなたの気づきを大切に。好きが見つかったら教えてね。")
                            .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                        PrimaryButton(title: "好きが見つかった！") { confirming = true }
                            .disabled(saving).accessibilityIdentifier("growth.foundLike")
                    }
                    if saving { ProgressView(hatching ? "すきたまごが孵化しています…" : "気づきを残しています…") }
                    PrimaryButton(title: "次の小さな体験へ", action: onExplore)
                        .disabled(saving).accessibilityIdentifier("growth.explore")
                }
                .multilineTextAlignment(.center).padding(AppTheme.pagePadding)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(AppTheme.background).navigationTitle("たまご").navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog("新しい『好き』が見つかった？", isPresented: $confirming, titleVisibility: .visible) {
            Button("まだ探してみる", role: .cancel) { }
            Button("見つかった！") { confirmHatch() }
        } message: { Text("夢中になれることを見つけたら、すきたまごが孵化するよ。") }
        .alert("孵化の状態を保存できませんでした", isPresented: $failed) {
            Button("とじる", role: .cancel) { }
        } message: { Text("空き容量などを確認して、もう一度試してください。体験記録はそのまま残っています。") }
        .onDisappear(perform: finishPresentation)
        .onChange(of: scenePhase) { _, phase in if phase != .active { finishPresentation() } }
        .onChange(of: reduceMotion) { _, reduced in if reduced { finishPresentation() } }
    }

    private var mascot: some View {
        ZStack {
            Circle().fill(AppTheme.lightBlue.opacity(0.6)).frame(width: 216, height: 216)
            EggCharacterView(hatched: hatching ? showCat : growth.stage.showsCat,
                             sways: displayedStage == .sprouting && !hatching)
                .allowsHitTesting(!saving)
                .rotationEffect(.degrees(shake ? 4 : 0)).opacity(opacity)
            if displayedStage != .beginning {
                Image(systemName: displayedStage.showsCat ? "heart.fill" : "sparkle")
                    .font(.title2).foregroundStyle(displayedStage.showsCat ? AppTheme.pink : AppTheme.outline)
                    .offset(x: -96, y: 68).accessibilityHidden(true)
                Image(systemName: "sparkles").font(.title2).foregroundStyle(AppTheme.outline)
                    .offset(x: 96, y: -68).accessibilityHidden(true)
            }
        }.frame(maxWidth: .infinity, minHeight: 240)
    }

    private func confirmHatch() {
        guard !saving, !growth.stage.showsCat else { return }
        saving = true
        previousStage = growth.stage
        animationTask = Task { @MainActor in
            defer { saving = false; hatching = false; shake = false; opacity = 1 }
            await Task.yield()
            guard !Task.isCancelled else { return }
            do {
                let newlyHatched = try EggHatchingStore.hatch(in: context.container)
                guard newlyHatched, !reduceMotion else { return }
                // Durable confirmation happens first. Only this explicit action starts playback.
                hatching = true; showCat = false
                withAnimation(.easeInOut(duration: 0.12).repeatCount(4, autoreverses: true)) { shake = true }
                try await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeOut(duration: 0.2)) { opacity = 0 }
                try await Task.sleep(for: .milliseconds(220))
                showCat = true; shake = false
                withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
                try await Task.sleep(for: .milliseconds(320))
            } catch is CancellationError {
                // The saved state remains hatched when an animation is interrupted.
            } catch { failed = true }
        }
    }

    private func finishPresentation() {
        animationTask?.cancel()
        hatching = false; shake = false; opacity = 1
    }
}
