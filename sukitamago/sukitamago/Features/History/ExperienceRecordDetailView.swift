import SwiftUI
import SwiftData

struct ExperienceRecordDetailView: View {
    let record: ExperienceRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.experiencePhotos) private var photos
    @State private var confirming = false
    @State private var deleting = false
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(record.missionTitle).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                StoredExperiencePhoto(filename: record.photoFilename, maxPixelSize: 1600)
                    .frame(maxHeight: 420)
                Text(record.completedAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryText)
                if let feeling = record.experienceFeeling {
                    Text(feeling.title).font(.headline)
                    Text(feeling.completionMessage).foregroundStyle(AppTheme.secondaryText)
                } else {
                    Text("あの日の気持ち").font(.headline)
                }
                if let note = record.note, !note.isEmpty {
                    Text(note).padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.subBackground, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityIdentifier("history.note")
                }
                if deleting { ProgressView("記録を削除しています…") }
                Button("この記録を削除する", role: .destructive) { confirming = true }
                    .frame(maxWidth: .infinity, minHeight: 44).disabled(deleting)
                    .accessibilityIdentifier("history.delete")
            }
            .padding(AppTheme.pagePadding).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(AppTheme.background).navigationTitle("あなたの小さな一歩")
        .navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden(deleting)
        .confirmationDialog("この体験の記録を削除しますか？", isPresented: $confirming, titleVisibility: .visible) {
            Button("削除する", role: .destructive) { delete() }
            Button("キャンセル", role: .cancel) { }
        } message: { Text("写真と振り返りも削除されます。この操作は取り消せません。") }
        .alert("記録を削除できませんでした", isPresented: $failed) {
            Button("もう一度試す") { delete() }
            Button("とじる", role: .cancel) { }
        } message: { Text("空き容量などを確認して、もう一度試してください。") }
    }

    private func delete() {
        guard !deleting else { return }
        deleting = true
        Task { @MainActor in
            await Task.yield()
            do {
                try ExperienceRecordStore(container: context.container, photos: photos).delete(id: record.id)
                // The shared mainContext updates the history query after saving.
                dismiss()
            } catch { failed = true }
            deleting = false
        }
    }
}
