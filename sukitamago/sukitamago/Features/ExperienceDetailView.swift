import SwiftUI

struct ExperienceDetailView: View {
    let experience: SmallExperience
    var onReturnHome: () -> Void = { }
    @State private var showsMission = false
    @State private var returningHome = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(experience.genre).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.outline)
                CameraIllustration().padding(16)
                Text(experience.title).font(.title.bold()).accessibilityAddTraits(.isHeader)
                Text("いつもの景色の中から、ちょっといいなと思うものを探してみよう。")
                    .font(.body).lineSpacing(6)
                Text("空でも、花でも、好きな色でも。正解はないよ。")
                    .foregroundStyle(AppTheme.secondaryText)
                VStack(spacing: 12) {
                    Label(experience.duration, systemImage: "clock")
                    Label(experience.equipment, systemImage: "iphone")
                }
                .font(.subheadline).padding(20).frame(maxWidth: .infinity)
                .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 22))
                PrimaryButton(title: "体験をはじめる") { showsMission = true }
                    .disabled(showsMission).accessibilityIdentifier("mission.start")
            }
            .multilineTextAlignment(.center)
            .padding(AppTheme.pagePadding).padding(.top, 24)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(AppTheme.background)
        .navigationTitle("今日の小さな体験")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: $showsMission, onDismiss: {
            if returningHome { returningHome = false; onReturnHome() }
        }) {
            PhotoMissionView(experience: experience) {
                guard !returningHome else { return }
                returningHome = true
                showsMission = false
            }
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: symbol).font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppTheme.outline)
                        .frame(width: 88, height: 88)
                        .background(AppTheme.lightBlue, in: Circle())
                    Text("\(title)は準備中です").font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(message).foregroundStyle(AppTheme.secondaryText)
                    EggCharacterView(expression: .happy)
                }
                .multilineTextAlignment(.center)
                .padding(AppTheme.pagePadding).padding(.top, 40)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(AppTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
