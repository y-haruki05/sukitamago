import SwiftUI

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

struct MissionIllustration: View {
    let category: MissionCategory
    var body: some View {
        Group {
            if category == .photo {
                CameraIllustration()
            } else {
                Image(systemName: category.icon).font(.system(size: 34, weight: .light))
                    .foregroundStyle(AppTheme.outline).frame(width: 88, height: 94)
                    .background(AppTheme.lightBlue, in: RoundedRectangle(cornerRadius: 22))
            }
        }.accessibilityHidden(true)
    }
}

struct ExperienceCard: View {
    let experience: SmallExperience
    var showsDiscoveryDetails = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if !typeSize.isAccessibilitySize { MissionIllustration(category: experience.category) }
            VStack(alignment: .leading, spacing: 9) {
                Text(experience.title).font(.headline).foregroundStyle(AppTheme.text)
                if showsDiscoveryDetails {
                    Text(experience.introduction).font(.subheadline).foregroundStyle(AppTheme.secondaryText).lineLimit(3)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { metadata }
                    VStack(alignment: .leading, spacing: 6) { metadata }
                }
                if showsDiscoveryDetails {
                    Label(experience.canStart ? "体験できる" : "準備中",
                          systemImage: experience.canStart ? "checkmark.circle" : "clock")
                        .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.outline)
                }
                Text("必要なもの：\(experience.equipment)")
                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.outline).accessibilityHidden(true)
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.lightBlue, lineWidth: 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var metadata: some View {
        Label(experience.genre, systemImage: experience.icon)
        Label(experience.duration, systemImage: "clock")
    }
}
