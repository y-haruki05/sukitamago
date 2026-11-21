import SwiftUI
import SwiftData

struct ExperienceHistoryView: View {
    let onExplore: () -> Void
    @Query(sort: ExperienceRecord.newestFirst) private var records: [ExperienceRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("これまでの小さな一歩").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text("ひとつひとつが、あなたの『好き』の種だよ。")
                        .foregroundStyle(AppTheme.secondaryText)
                    if records.isEmpty {
                        VStack(spacing: 24) {
                            EggCharacterView()
                            Text("まだ、最初の一歩の前だね。").font(.headline)
                            Text("小さな体験をひとつ重ねると、ここに思い出が増えていくよ。")
                                .foregroundStyle(AppTheme.secondaryText)
                            PrimaryButton(title: "体験を探してみる", action: onExplore)
                                .accessibilityIdentifier("history.explore")
                        }.multilineTextAlignment(.center).padding(.vertical, 24)
                    }
                    ForEach(records) { record in
                        NavigationLink {
                            ExperienceRecordDetailView(record: record)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                StoredExperiencePhoto(filename: record.photoFilename, maxPixelSize: 600)
                                    .frame(maxHeight: 180)
                                Text(record.missionTitle).font(.headline).lineLimit(2)
                                Text(record.completedAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
                                Text(record.experienceFeeling?.title ?? "あの日の気持ち").font(.subheadline.bold())
                                if let note = record.note, !note.isEmpty {
                                    Text(note).font(.subheadline).lineLimit(2).foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                            .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.lightBlue))
                            .contentShape(RoundedRectangle(cornerRadius: 24))
                        }
                        .buttonStyle(.plain).accessibilityIdentifier("history.record")
                    }
                }
                .padding(AppTheme.pagePadding).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(AppTheme.background).navigationTitle("きろく").navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Lazy rows request bounded decodes off the main thread; no whole-album image cache.
struct StoredExperiencePhoto: View {
    let filename: String
    let maxPixelSize: Int
    @Environment(\.experiencePhotos) private var photos
    @State private var image: UIImage?
    @State private var loading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
                    .accessibilityLabel("体験で見つけた『きれい』の写真")
                    .accessibilityIdentifier("history.photo")
            } else if loading {
                ProgressView("写真を読み込んでいます…").frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Label("写真を表示できません", systemImage: "photo")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(AppTheme.lightBlue)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task(id: filename) {
            loading = true
            let store = photos
            let name = filename
            let limit = maxPixelSize
            let result = await Task.detached(priority: .utility) { store.read(name, maxPixelSize: limit) }.value
            guard !Task.isCancelled else { return }
            image = result
            loading = false
        }
        .onDisappear { image = nil }
    }
}
