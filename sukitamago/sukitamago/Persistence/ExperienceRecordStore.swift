import SwiftData
import UIKit

/// Use the query context so history updates immediately. Refuse a transaction when unrelated
/// edits are pending, so rollback never discards another feature's changes.
@MainActor
final class ExperienceRecordStore {
    let container: ModelContainer
    let photos: ExperiencePhotoStore
    private let commit: (ModelContext) throws -> Void

    init(container: ModelContainer, photos: ExperiencePhotoStore,
         commit: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.container = container
        self.photos = photos
        self.commit = commit
    }

    func save(id: UUID, experience: SmallExperience, photo: UIImage,
              reflection: ExperienceReflection, completedAt: Date = .now) throws {
        let context = try writingContext()
        // A session keeps the same UUID across retries and repeated completion actions.
        if try context.fetch(FetchDescriptor<ExperienceRecord>(predicate: #Predicate { $0.id == id })).first != nil { return }
        let filename = try photos.save(photo, id: id)
        context.insert(ExperienceRecord(id: id, missionID: experience.id, missionTitle: experience.title,
                                        completedAt: completedAt, reflection: reflection, photoFilename: filename))
        do { try commit(context) }
        catch {
            context.rollback()
            do { try photos.delete(filename) }
            catch { throw PersistenceFailure.cleanup(error) }
            throw error
        }
    }

    func delete(id: UUID) throws {
        let context = try writingContext()
        guard let record = try context.fetch(FetchDescriptor<ExperienceRecord>(predicate: #Predicate { $0.id == id })).first else { return }
        let original = try photos.url(for: record.photoFilename)
        let manager = FileManager.default
        // Keep only compressed bytes until the database transaction succeeds. A file deletion
        // failure leaves the record untouched; a database failure restores the original JPEG.
        let backup = manager.fileExists(atPath: original.path) ? try Data(contentsOf: original) : nil
        try photos.delete(record.photoFilename)
        context.delete(record)
        do { try commit(context) }
        catch {
            context.rollback()
            if let backup {
                do { try backup.write(to: original, options: .atomic) }
                catch { throw PersistenceFailure.cleanup(error) }
            }
            throw error
        }
    }

    private func writingContext() throws -> ModelContext {
        let context = container.mainContext
        guard !context.hasChanges else { throw PersistenceFailure.pendingChanges }
        return context
    }

    enum PersistenceFailure: Error { case pendingChanges, cleanup(Error) }
}
