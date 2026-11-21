import SwiftUI
import SwiftData

struct EggGrowthView: View {
    let growth: EggGrowth
    let eggID: UUID?
    let onExplore: () -> Void
    @Environment(\.modelContext) private var context
    @State private var failed = false
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("あなたのすきたまご").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text("小さな体験から、あなたの『好き』を育てよう。")
                        .foregroundStyle(AppTheme.secondaryText)
                    VStack(spacing: 20) {
                        EggCharacterView(hatched: growth.stage.showsCat, sways: growth.stage == .sprouting)
                        Text(growth.stage.title).font(.title2.bold()).foregroundStyle(AppTheme.outline)
                            .accessibilityIdentifier("growth.stage")
                        Text(growth.stage.showsCat ? "図鑑に登録されたよ！" : "写真の体験を楽しむと、カメラねこが生まれるよ。")
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22).frame(maxWidth: .infinity)
                    .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    Text("これまでの体験：\(growth.experienceCount)回").font(.headline)
                        .accessibilityIdentifier("growth.count")
                    if growth.stage.showsCat {
                        PrimaryButton(title: "次の卵を育てる") { startNextEgg() }
                            .disabled(saving).accessibilityIdentifier("growth.nextEgg")
                    }
                    NavigationLink { CharacterCollectionView() } label: {
                        Label("すきのずかんを見る", systemImage: "book.closed")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    PrimaryButton(title: "次の小さな体験へ", action: onExplore)
                        .disabled(saving).accessibilityIdentifier("growth.explore")
                }
                .multilineTextAlignment(.center).padding(AppTheme.pagePadding)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(AppTheme.background).navigationTitle("たまご").navigationBarTitleDisplayMode(.inline)
        }
        .alert("新しい卵を準備できませんでした", isPresented: $failed) {
            Button("とじる", role: .cancel) { }
        } message: { Text("空き容量などを確認して、もう一度試してください。図鑑と体験記録は残っています。") }
    }

    private func startNextEgg() {
        guard !saving, growth.stage.showsCat, let eggID else { return }
        saving = true
        defer { saving = false }
        do { _ = try EggHatchingStore.startNextEgg(in: context.container, after: eggID) }
        catch { failed = true }
    }
}
