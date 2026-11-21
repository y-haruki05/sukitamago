import SwiftUI

struct SmallExperience: Hashable {
    let id: String
    let title: String
    let genre: String
    let duration: String
    let equipment: String
    let introduction: String

    static let first = SmallExperience(
        id: "photo.nearby-beauty",
        title: "身近な『きれい』を撮ろう", genre: "写真", duration: "約3分",
        equipment: "スマートフォン",
        introduction: "あなたの周りにある、ちょっといいなと思ったものを探してみよう。")
}

struct CameraIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(AppTheme.lightBlue)
            Circle().fill(AppTheme.background.opacity(0.7)).padding(12)
            Image(systemName: "camera").font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.outline)
            Image(systemName: "sparkle").font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.outline).offset(x: 26, y: -25)
        }
        .frame(width: 88, height: 94)
        .accessibilityHidden(true)
    }
}

struct ExperienceCard: View {
    let experience: SmallExperience
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if !typeSize.isAccessibilitySize { CameraIllustration() }
            VStack(alignment: .leading, spacing: 9) {
                Text(experience.title).font(.headline).foregroundStyle(AppTheme.text)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { metadata }
                    VStack(alignment: .leading, spacing: 6) { metadata }
                }
                Text("必要なもの：\(experience.equipment)")
                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.outline)
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.lightBlue, lineWidth: 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var metadata: some View {
        Label(experience.genre, systemImage: "camera")
        Label(experience.duration, systemImage: "clock")
    }
}
