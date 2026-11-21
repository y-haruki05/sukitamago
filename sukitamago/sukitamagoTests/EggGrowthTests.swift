import Testing
import SwiftData
import UIKit
@testable import sukitamago

@MainActor
struct EggGrowthTests {
    @Test func countsNeverHatchWithoutConfirmation() {
        for count in [0, 1, 2, 3, 5, 100, Int.max, -1, Int.min] {
            let growth = EggGrowthCalculator.calculate(experienceCount: count)
            #expect(!growth.stage.showsCat)
            #expect(growth.stage == (count >= 3 ? .sprouting : .beginning))
            #expect(growth.experienceCount == max(0, count))
        }
        let id = UUID()
        #expect(EggGrowthCalculator.calculate(recordIDs: [id, id]).experienceCount == 1)
        #expect(EggGrowthCalculator.calculate(experienceCount: 0, hasFoundLike: true).stage.showsCat)
    }

    @Test func funDoesNotHatchButConfirmationDoesAndDeletionDoesNotUndoIt() throws {
        let store = try testRecordStore()
        defer { try? FileManager.default.removeItem(at: store.photos.directory) }
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
        let ids = (0..<5).map { _ in UUID() }
        for id in ids {
            try store.save(id: id, experience: .first, photo: photo, reflection: .init(feeling: .fun, note: ""))
        }
        let context = store.container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<EggHatchingState>()) == 0)
        #expect(!EggGrowthCalculator.calculate(recordIDs: ids).stage.showsCat)
        let first = try EggHatchingStore.hatch(in: store.container)
        let second = try EggHatchingStore.hatch(in: store.container)
        #expect(first && !second)
        #expect(try context.fetchCount(FetchDescriptor<EggHatchingState>()) == 1)
        for id in ids { try store.delete(id: id) }
        let restored = try ModelContext(store.container).fetch(FetchDescriptor<EggHatchingState>())
        #expect(restored.count == 1)
        #expect(EggGrowthCalculator.calculate(experienceCount: 0, hasFoundLike: !restored.isEmpty).stage == .hatched)
    }

    @Test func saveFailureDoesNotHatchAndRetryIsPossible() throws {
        let persistence = try ExperiencePersistence.make(inMemory: true)
        enum Failure: Error { case expected }
        #expect(throws: (any Error).self) {
            try EggHatchingStore.hatch(in: persistence.container) { _ in throw Failure.expected }
        }
        #expect(!persistence.container.mainContext.hasChanges)
        #expect(try persistence.container.mainContext.fetchCount(FetchDescriptor<EggHatchingState>()) == 0)
        let retry = try EggHatchingStore.hatch(in: persistence.container)
        #expect(retry)
    }

    @Test func hatchingPersistsWhenDiskStoreIsReopenedWithoutLosingRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "history.store")
        // Start with the existing schema, then add the hatching model (additive migration).
        func writeOldStore() throws {
            let schema = Schema([Item.self, ExperienceRecord.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let id = UUID()
            container.mainContext.insert(ExperienceRecord(id: id, missionID: SmallExperience.first.id,
                missionTitle: SmallExperience.first.title, completedAt: .now,
                reflection: .init(feeling: .fun, note: "before migration"), photoFilename: id.uuidString + ".jpg"))
            try container.mainContext.save()
        }
        try writeOldStore()
        let schema = Schema([Item.self, ExperienceRecord.self, EggHatchingState.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        func hatch() throws {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let saved = try EggHatchingStore.hatch(in: container)
            #expect(saved)
        }
        try hatch()
        let reopened = try ModelContainer(for: schema, configurations: configuration)
        let records = try reopened.mainContext.fetch(FetchDescriptor<ExperienceRecord>())
        let hatching = try reopened.mainContext.fetch(FetchDescriptor<EggHatchingState>())
        #expect(records.count == 1 && records.first?.note == "before migration")
        #expect(hatching.count == 1 && hatching.first?.hatchedAt != nil)
        #expect(EggGrowthCalculator.calculate(recordIDs: records.map(\.id), hasFoundLike: !hatching.isEmpty).stage.showsCat)
    }
}
