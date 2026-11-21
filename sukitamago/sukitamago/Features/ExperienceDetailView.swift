import SwiftUI

struct ExperienceDetailView: View {
    let experience: SmallExperience

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("はじめての小さな体験").font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.outline)
                CameraIllustration().scaleEffect(1.3).padding(22)
                Text(experience.title).font(.title.bold()).accessibilityAddTraits(.isHeader)
                Text(experience.introduction).font(.body).lineSpacing(6)
                Label("写真ミッションは準備中です", systemImage: "leaf")
                    .font(.subheadline.weight(.medium)).padding(20)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 22))
                Text("撮影や保存は、これからできるようになります。\n小さな一歩を、楽しみに待っていてね。")
                    .font(.footnote).foregroundStyle(AppTheme.secondaryText)
            }
            .multilineTextAlignment(.center)
            .padding(AppTheme.pagePadding).padding(.top, 24)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(AppTheme.background)
        .navigationTitle("今日の小さな体験")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
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
