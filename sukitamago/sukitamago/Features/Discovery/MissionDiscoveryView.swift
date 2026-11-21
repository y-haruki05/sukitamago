import SwiftUI

struct MissionDiscoveryView: View {
    let onReturnHome: () -> Void
    @State private var selectedCategory: MissionCategory?
    @State private var path: [ExperienceMission] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("小さな『好き』を探そう").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text("気になることから、ひとつ試してみよう。")
                        .foregroundStyle(AppTheme.secondaryText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryChip(nil)
                            ForEach(MissionCategory.allCases) { category in categoryChip(category) }
                        }.padding(.vertical, 3)
                    }
                    .accessibilityLabel("体験のジャンル")
                    LazyVStack(spacing: 16) {
                        ForEach(MissionCatalog.missions(in: selectedCategory)) { mission in
                            NavigationLink(value: mission) {
                                ExperienceCard(experience: mission, showsDiscoveryDetails: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("discovery.mission.\(mission.id)")
                        }
                    }
                }
                .padding(AppTheme.pagePadding).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(AppTheme.background)
            .navigationTitle("さがす").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ExperienceMission.self) { mission in
                ExperienceDetailView(experience: mission) {
                    path.removeAll()
                    onReturnHome()
                }
            }
        }
    }

    private func categoryChip(_ category: MissionCategory?) -> some View {
        let selected = category == selectedCategory
        let title = category?.title ?? "すべて"
        return Button { selectedCategory = category } label: {
            Text(title).font(.subheadline.weight(.semibold)).fixedSize()
                .padding(.horizontal, 18).frame(minHeight: 44)
                .foregroundStyle(selected ? AppTheme.outline : AppTheme.text)
                .background(selected ? AppTheme.lightBlue : AppTheme.subBackground, in: Capsule())
                .overlay(Capsule().stroke(selected ? AppTheme.outline : AppTheme.lightBlue, lineWidth: selected ? 2 : 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .accessibilityValue(selected ? "選択中" : "未選択")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("discovery.category.\(category?.rawValue ?? "all")")
    }
}
