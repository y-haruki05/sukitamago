import Foundation
import SwiftData

@Model
final class ExperienceRecord {
    @Attribute(.unique) var id: UUID
    var missionID: String
    var missionTitle: String
    var completedAt: Date
    /// Stable raw identifier; presentation text remains in ExperienceFeeling.
    var feeling: String
    var note: String?
    var photoFilename: String
    var sortID: String

    init(id: UUID, missionID: String, missionTitle: String, completedAt: Date,
         reflection: ExperienceReflection, photoFilename: String) {
        self.id = id
        self.missionID = missionID
        self.missionTitle = missionTitle
        self.completedAt = completedAt
        self.feeling = reflection.feeling.rawValue
        self.note = reflection.note.isEmpty ? nil : reflection.note
        self.photoFilename = photoFilename
        self.sortID = id.uuidString
    }

    var experienceFeeling: ExperienceFeeling? { ExperienceFeeling(rawValue: feeling) }
    static var newestFirst: [SortDescriptor<ExperienceRecord>] {
        [SortDescriptor(\.completedAt, order: .reverse), SortDescriptor(\.sortID)]
    }
}
