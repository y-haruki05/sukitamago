import Testing
import SwiftData
import UIKit
@testable import sukitamago

@MainActor
func testRecordStore() throws -> ExperienceRecordStore {
    let persistence = try ExperiencePersistence.make(inMemory: true)
    return ExperienceRecordStore(container: persistence.container,
        photos: ExperiencePhotoStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
}

@MainActor
struct ExperienceRecordStoreTests {
    enum Injected: Error { case failure }
    var image: UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 80, height: 40)).image { context in
            UIColor.systemPink.setFill(); context.fill(CGRect(x: 0, y: 0, width: 80, height: 40))
        }
    }
    func fetch(_ store: ExperienceRecordStore) throws -> [ExperienceRecord] {
        try ModelContext(store.container).fetch(FetchDescriptor<ExperienceRecord>(sortBy: ExperienceRecord.newestFirst))
    }

    @Test func roundTripPhotoAndRecordAndIdempotence() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let id = UUID(), date = Date(timeIntervalSince1970: 123456)
        let reflection = ExperienceReflection(feeling: .notForMe, note: "  また挑戦したい \n")
        try store.save(id: id, experience: .first, photo: image, reflection: reflection, completedAt: date)
        try store.save(id: id, experience: .first, photo: image, reflection: reflection)
        let records = try fetch(store)
        #expect(records.count == 1)
        let record = try #require(records.first)
        #expect(record.completedAt == date)
        #expect(record.experienceFeeling == .notForMe)
        #expect(record.note == "また挑戦したい")
        #expect(record.missionID == SmallExperience.first.id)
        let loaded = try #require(store.photos.read(record.photoFilename, maxPixelSize: 40))
        #expect(loaded.size.width == 40 && loaded.size.height == 20)
        try store.delete(id: id)
        #expect(try fetch(store).isEmpty)
        #expect(store.photos.read(record.photoFilename, maxPixelSize: 40) == nil)
    }

    @Test func photoEncodingNormalizesOrientationAndBoundsPixels() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let cgImage = try #require(image.cgImage)
        let rotated = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        let filename = try store.photos.save(rotated, id: UUID())
        let decoded = try #require(store.photos.read(filename, maxPixelSize: 2048))
        #expect(decoded.imageOrientation == .up)
        #expect(decoded.size.width == CGFloat(cgImage.height) && decoded.size.height == CGFloat(cgImage.width))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let large = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 1500), format: format).image { _ in }
        let largeFilename = try store.photos.save(large, id: UUID())
        let bounded = try #require(store.photos.read(largeFilename, maxPixelSize: 4096))
        #expect(bounded.size.width == 2048 && bounded.size.height == 1024)
    }

    @Test func photoFailureCreatesNoRecordAndPathsAreSafe() throws {
        let store = try testRecordStore()
        // A regular file cannot be used as the photo directory.
        try Data([1]).write(to: store.photos.directory)
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        #expect(throws: (any Error).self) {
            try store.save(id: UUID(), experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        }
        #expect(try fetch(store).isEmpty)
        #expect(throws: (any Error).self) { try store.photos.url(for: "../escape.jpg") }
        #expect(throws: (any Error).self) { try store.photos.url(for: "/tmp/escape.jpg") }
    }

    @Test func databaseFailureCleansPhotoAndRetryWorks() throws {
        let good = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: good.photos.directory) }
        let failing = ExperienceRecordStore(container: good.container, photos: good.photos) { _ in throw Injected.failure }
        let id = UUID()
        #expect(throws: (any Error).self) {
            try failing.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        }
        #expect(try fetch(good).isEmpty)
        #expect(!good.container.mainContext.hasChanges)
        #expect(try FileManager.default.contentsOfDirectory(atPath: good.photos.directory.path).isEmpty)
        try good.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .neutral, note: ""))
        #expect(try fetch(good).count == 1)
        #expect(try fetch(good).first?.note == nil)
    }

    @Test func failedDeletionRestoresPhotoAndDoesNotTouchOtherRecords() throws {
        let good = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: good.photos.directory) }
        let id = UUID(), other = UUID()
        for value in [id, other] {
            try good.save(id: value, experience: .first, photo: image, reflection: .init(feeling: .fun, note: "test"))
        }
        let failing = ExperienceRecordStore(container: good.container, photos: good.photos) { _ in throw Injected.failure }
        #expect(throws: (any Error).self) { try failing.delete(id: id) }
        #expect(try fetch(good).count == 2)
        #expect(good.photos.read(id.uuidString + ".jpg", maxPixelSize: 40) != nil)
        try good.delete(id: id)
        #expect(try fetch(good).map(\.id) == [other])
    }

    @Test func photoDeletionFailureLeavesRecordAndPhotoIntact() throws {
        let good = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: good.photos.directory) }
        let id = UUID()
        try good.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        let failingPhotos = ExperiencePhotoStore(directory: good.photos.directory) { _ in throw Injected.failure }
        let failing = ExperienceRecordStore(container: good.container, photos: failingPhotos)
        #expect(throws: (any Error).self) { try failing.delete(id: id) }
        #expect(try fetch(good).count == 1)
        #expect(good.photos.read(id.uuidString + ".jpg", maxPixelSize: 40) != nil)
        try good.delete(id: id)
        #expect(try fetch(good).isEmpty)
    }

    @Test func missingPhotoAndStableNewestOrder() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        // Use fixed, reverse-inserted tie IDs. SortDescriptor uses natural string ordering,
        // whereas Swift.sorted() is lexical; random numeric UUID prefixes can disagree.
        let ids = [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        ]
        for (index, id) in ids.enumerated() {
            try store.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""),
                           completedAt: Date(timeIntervalSince1970: index == 0 ? 1 : 2))
        }
        let sorted = try fetch(store)
        #expect(sorted.last?.id == ids[0])
        #expect(Array(sorted.prefix(2)).map(\.id) == [ids[2], ids[1]])
        try store.photos.delete(ids[0].uuidString + ".jpg")
        #expect(store.photos.read(ids[0].uuidString + ".jpg", maxPixelSize: 100) == nil)
        try store.delete(id: ids[0])
        #expect(try fetch(store).count == 2)
    }

    @Test func unrelatedPendingChangesArePreserved() throws {
        let store = try testRecordStore()
        let item = Item(timestamp: .now)
        store.container.mainContext.autosaveEnabled = false
        store.container.mainContext.insert(item)
        #expect(throws: (any Error).self) {
            try store.save(id: UUID(), experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        }
        #expect(store.container.mainContext.hasChanges)
        #expect(!FileManager.default.fileExists(atPath: store.photos.directory.path))
        store.container.mainContext.rollback()
    }

    @Test func uiTestPreferencesAreIsolatedAndPersistAcrossRelaunch() throws {
        let id = UUID().uuidString
        let otherID = UUID().uuidString
        defer {
            UserDefaults.standard.removePersistentDomain(forName: "sukitamago.UITests.\(id)")
            UserDefaults.standard.removePersistentDomain(forName: "sukitamago.UITests.\(otherID)")
        }
        let original = UserDefaults.standard.string(forKey: OnboardingStorage.mood)
        let defaults = try ExperiencePersistence.preferences(testID: id)
        defaults.set("test-mood", forKey: OnboardingStorage.mood)
        #expect(try ExperiencePersistence.preferences(testID: id).string(forKey: OnboardingStorage.mood) == "test-mood")
        #expect(try ExperiencePersistence.preferences(testID: otherID).string(forKey: OnboardingStorage.mood) == nil)
        #expect(UserDefaults.standard.string(forKey: OnboardingStorage.mood) == original)
    }

    @Test func saveFailureKeepsDraftAndCanRetry() async throws {
        let good = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: good.photos.directory) }
        let state = PhotoMissionState()
        _ = state.beginLoading(); state.receive(image); state.confirm()
        state.selectFeeling(.fun); state.updateNote("お花")
        let failing = ExperienceRecordStore(container: good.container, photos: good.photos) { _ in throw Injected.failure }
        await state.finishReflection(using: failing)
        #expect(state.phase == .reflecting && state.note == "お花" && state.selectedFeeling == .fun)
        #expect(state.photo != nil && state.notice != nil && !state.isSaving)
        await state.finishReflection(using: good)
        await state.finishReflection(using: good)
        #expect(state.phase == .completed)
        #expect(try fetch(good).count == 1)
    }
}
