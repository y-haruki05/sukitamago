import SwiftUI
import SwiftData

struct CharacterCollectionView: View {
    @Query(sort: \HatchedCharacter.number) private var characters: [HatchedCharacter]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Text("見つけた『好き』が、ここに増えていくよ。")
                    .foregroundStyle(AppTheme.secondaryText)
                Text("登録した仲間：\(characters.count)匹").font(.headline)
                if characters.isEmpty {
                    Image("Egg").resizable().scaledToFit().frame(height: 160).accessibilityHidden(true)
                    Text("まだ、図鑑はからっぽ。").font(.title3.bold())
                    Text("新しい『好き』を見つけたら、ここに仲間が増えていくよ。")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                ForEach(characters) { character in
                    NavigationLink {
                        CharacterCollectionDetailView(character: character)
                    } label: {
                        VStack(spacing: 12) {
                            Image(character.imageAsset).resizable().scaledToFit().frame(height: 130)
                                .accessibilityHidden(true)
                            Text("\(character.number)匹目の\(character.name)").font(.headline)
                            Text(character.hatchedAt, format: .dateTime.year().month().day())
                                .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity).padding(20)
                        .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("仲間の詳細を表示します")
                }
            }
            .multilineTextAlignment(.center).padding(AppTheme.pagePadding)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(AppTheme.background).foregroundStyle(AppTheme.text)
        .navigationTitle("すきのずかん").navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterCollectionDetailView: View {
    let character: HatchedCharacter

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(character.imageAsset).resizable().scaledToFit().frame(maxHeight: 280)
                    .accessibilityLabel(character.name)
                Text(character.name).font(.largeTitle.bold())
                if !character.genre.isEmpty { Text(character.genre).foregroundStyle(AppTheme.secondaryText) }
                Text("\(character.number)匹目に生まれた仲間").font(.headline)
                Text("孵化した日").foregroundStyle(AppTheme.secondaryText)
                Text(character.hatchedAt, format: .dateTime.year().month().day().hour().minute())
            }
            .multilineTextAlignment(.center).padding(AppTheme.pagePadding)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(AppTheme.background).foregroundStyle(AppTheme.text)
        .navigationTitle("仲間のこと").navigationBarTitleDisplayMode(.inline)
    }
}
