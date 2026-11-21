import SwiftUI

struct HomeView: View {
    #if DEBUG
    @AppStorage(OnboardingStorage.completed) private var onboardingCompleted = false
    @AppStorage(OnboardingStorage.mood) private var startingMood = ""
    #endif
    @State private var showsSettings = false
    @State private var showsExperience = false
    private let experience = SmallExperience.first

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    mainCard
                    VStack(alignment: .leading, spacing: 14) {
                        Text("今日のおすすめ").font(.title3.bold()).accessibilityAddTraits(.isHeader)
                        Button { showsExperience = true } label: {
                            ExperienceCard(experience: experience)
                                .font(.caption).foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("recommendedExperience")
                    }
                    Text("好きは、見つけるものじゃなくて、育つもの。")
                        .font(.caption).foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.top, 20).padding(.bottom, 28)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showsExperience) {
                ExperienceDetailView(experience: experience)
            }
            .alert("設定は準備中です", isPresented: $showsSettings) {
                Button("とじる", role: .cancel) { }
                #if DEBUG
                Button("オンボーディングをリセット", role: .destructive) {
                    startingMood = ""
                    onboardingCompleted = false
                }
                #endif
            } message: { Text("これから少しずつ、使いやすく育てていきます。") }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("おかえりなさい！").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.secondaryText)
                Text("すきたまご").font(.largeTitle.weight(.bold)).foregroundStyle(AppTheme.outline)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            Button { showsSettings = true } label: {
                Image(systemName: "gearshape").font(.title3)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.subBackground, in: Circle())
            }
            .accessibilityLabel("設定")
        }
    }

    private var mainCard: some View {
        VStack(spacing: 18) {
            Text("あなたの好きのたまご")
                .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.outline)
            EggCharacterView()
            VStack(spacing: 10) {
                Text("まだ知らない『好き』が\n眠っているよ")
                    .font(.title3.bold()).fixedSize(horizontal: false, vertical: true)
                Text("今日はちょっとだけ、新しいことをしてみよう！")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            PrimaryButton(title: "今日の小さな体験へ") { showsExperience = true }
                .accessibilityIdentifier("startExperience")
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardRadius).stroke(AppTheme.lightBlue, lineWidth: 1))
    }
}

#Preview { ContentView() }
