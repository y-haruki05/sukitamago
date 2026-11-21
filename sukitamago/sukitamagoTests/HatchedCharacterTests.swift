import Testing
import SwiftData
import UIKit
@testable import sukitamago

@MainActor
struct HatchedCharacterTests {
    enum Failure: Error { case expected }
    var image: UIImage { UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in } }
    private func state(_ container: ModelContainer) throws -> EggHatchingState {
        try #require(container.mainContext.fetch(FetchDescriptor<EggHatchingState>()).first)
    }
    private func cats(_ container: ModelContainer) throws -> [HatchedCharacter] {
        try container.mainContext.fetch(FetchDescriptor<HatchedCharacter>(sortBy: [SortDescriptor(\.number)]))
    }

    @Test func onlyFunPhotoHatchesAndDuplicateSaveNeverHatchesNextEgg() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let id = UUID()
        let eggID = try #require(state(store.container).currentEggID)
        let hatched = try store.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        #expect(hatched == eggID)
        #expect(try cats(store.container).map(\.kind) == ["photoCat"])
        #expect(try cats(store.container).first?.name == "カメラねこ")
        try store.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        #expect(try cats(store.container).count == 1)
        #expect(try EggHatchingStore.startNextEgg(in: store.container, after: eggID))
        #expect(try state(store.container).currentEggID != eggID)
        #expect(try state(store.container).pendingCharacterID == nil)
        #expect(!(try EggHatchingStore.startNextEgg(in: store.container, after: eggID)))
        try store.save(id: id, experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        #expect(try state(store.container).pendingCharacterID == nil)
        try store.save(id: UUID(), experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
        #expect(try cats(store.container).map(\.number) == [1, 2])
        try store.delete(id: id)
        #expect(try cats(store.container).count == 2)
    }

    @Test(arguments: [ExperienceFeeling.neutral, .notForMe])
    func otherFeelingsNeverHatch(feeling: ExperienceFeeling) throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let original = try state(store.container).currentEggID
        let result = try store.save(id: UUID(), experience: .first, photo: image, reflection: .init(feeling: feeling, note: ""))
        #expect(result == nil)
        #expect(try cats(store.container).isEmpty)
        #expect(try state(store.container).pendingCharacterID == nil)
        #expect(try state(store.container).currentEggID == original)
        #expect(try store.container.mainContext.fetchCount(FetchDescriptor<ExperienceRecord>()) == 1)
    }

    @Test func anotherMissionCannotHatch() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let mission = try #require(MissionCatalog.all.first { $0.id != "photo.nearby-beauty" })
        try store.save(id: UUID(), experience: mission, photo: image, reflection: .init(feeling: .fun, note: ""))
        #expect(try cats(store.container).isEmpty)
    }

    @Test func failedSaveRollsBackRecordCatAndEggAndRetrySucceeds() async throws {
        let good = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: good.photos.directory) }
        let original = try state(good.container).currentEggID
        let failing = ExperienceRecordStore(container: good.container, photos: good.photos) { _ in throw Failure.expected }
        let draft = PhotoMissionState()
        _ = draft.beginLoading(); draft.receive(image); draft.confirm(); draft.selectFeeling(.fun)
        await draft.finishReflection(using: failing)
        #expect(draft.phase == .reflecting && draft.hatchedCharacterID == nil)
        #expect(try cats(good.container).isEmpty)
        #expect(try state(good.container).currentEggID == original)
        #expect(try state(good.container).pendingCharacterID == nil)
        #expect(try good.container.mainContext.fetchCount(FetchDescriptor<ExperienceRecord>()) == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: good.photos.directory.path).isEmpty)
        await draft.finishReflection(using: good)
        await draft.finishReflection(using: good)
        #expect(draft.phase == .completed && draft.hatchedCharacterID == original)
        #expect(try cats(good.container).count == 1)
        #expect(throws: (any Error).self) {
            try EggHatchingStore.startNextEgg(in: good.container, after: original!) { _ in throw Failure.expected }
        }
        #expect(try state(good.container).pendingCharacterID == original)
    }

    @Test func legacyMigrationAndPhotoCatSurviveReopening() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "history.store")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        func writeLegacy() throws {
            let schema = Schema([Item.self, ExperienceRecord.self, EggHatchingState.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let legacy = EggHatchingState(hatchedAt: date)
            legacy.currentEggID = nil
            container.mainContext.insert(legacy)
            try container.mainContext.save()
        }
        try writeLegacy()
        let schema = Schema([Item.self, ExperienceRecord.self, EggHatchingState.self, HatchedCharacter.self])
        func open() throws -> ModelContainer {
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            try EggHatchingStore.prepare(in: container)
            return container
        }
        func migrateAndHatch() throws -> UUID {
            let container = try open()
            try EggHatchingStore.prepare(in: container)
            let old = try #require(cats(container).first)
            #expect(try cats(container).count == 1 && old.hatchedAt == date)
            #expect(try EggHatchingStore.startNextEgg(in: container, after: old.id))
            let store = ExperienceRecordStore(container: container, photos: ExperiencePhotoStore(directory: directory.appending(path: "photos")))
            let result = try store.save(id: UUID(), experience: .first, photo: image, reflection: .init(feeling: .fun, note: ""))
            let id = try #require(result)
            return id
        }
        let hatchedID = try migrateAndHatch()
        func reset() throws -> UUID {
            let container = try open()
            #expect(try cats(container).map(\.kind) == ["cat", "photoCat"])
            #expect(try state(container).pendingCharacterID == hatchedID)
            #expect(try EggHatchingStore.startNextEgg(in: container, after: hatchedID))
            return try #require(state(container).currentEggID)
        }
        let nextID = try reset()
        let reopened = try open()
        #expect(try state(reopened).currentEggID == nextID && nextID != hatchedID)
        #expect(try state(reopened).pendingCharacterID == nil)
        #expect(try cats(reopened).count == 2)
        #expect(try reopened.mainContext.fetchCount(FetchDescriptor<ExperienceRecord>()) == 1)
    }
}
