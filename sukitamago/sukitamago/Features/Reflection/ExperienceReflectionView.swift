import SwiftUI

struct ExperienceReflectionView: View {
    @Bindable var state: PhotoMissionState
    @State private var isComposing = false

    var body: some View {
        VStack(spacing: 24) {
            EggCharacterView()
            Text("やってみて、どうだった？").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text("どんな気持ちでも大丈夫。今の気持ちを教えてね。")
                .foregroundStyle(AppTheme.secondaryText)
            Text(state.experience.title).font(.headline)
            if let photo = state.photo {
                Image(uiImage: photo).resizable().scaledToFit().frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("今回の体験で見つけた『きれい』の写真")
            }
            VStack(spacing: 12) {
                ForEach(ExperienceFeeling.allCases) { feeling in
                    feelingCard(feeling)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("ひとこと残してみる？").font(.headline).accessibilityAddTraits(.isHeader)
                Text("何を感じたか、自由に書いてね。（書かなくてもOK）")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                ZStack(alignment: .topLeading) {
                    ReflectionNoteEditor(text: Binding(get: { state.note }, set: { state.updateNote($0) }),
                                         isComposing: $isComposing)
                        .frame(height: 150)
                    if state.note.isEmpty && !isComposing {
                        Text("空の色がきれいだった、など").font(.body)
                            .foregroundStyle(AppTheme.secondaryText).padding(.horizontal, 13).padding(.top, 12)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                }
                .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.lightBlue, lineWidth: 1))
                Text("\(state.note.count) / \(ExperienceReflection.noteLimit)文字")
                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("入力済み\(state.note.count)文字、最大200文字")
                if isComposing {
                    Text("変換を確定してから、振り返りを終えてね。")
                        .font(.caption).foregroundStyle(AppTheme.secondaryText)
                }
            }
            PrimaryButton(title: "振り返りを終える") { state.finishReflection() }
                .disabled(!state.canFinishReflection || isComposing)
                .opacity(state.canFinishReflection && !isComposing ? 1 : 0.5)
                .accessibilityIdentifier("reflection.finish")
            Text("写真と回答は、この体験中だけ表示されます。保存はされません。")
                .font(.footnote).foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func feelingCard(_ feeling: ExperienceFeeling) -> some View {
        let selected = state.selectedFeeling == feeling
        return Button { state.selectFeeling(feeling) } label: {
            HStack(spacing: 14) {
                Text(feeling.symbol).font(.title2).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(feeling.title).font(.headline)
                    Text(feeling.subtitle).font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(AppTheme.outline)
            }
            .padding(18).frame(minHeight: 72)
            .background(selected ? AppTheme.lightBlue : AppTheme.subBackground,
                        in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(selected ? AppTheme.outline : AppTheme.lightBlue, lineWidth: selected ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(feeling.title)。\(feeling.subtitle)")
        .accessibilityValue(selected ? "選択中" : "未選択")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("reflection.feeling.\(feeling.rawValue)")
    }
}
