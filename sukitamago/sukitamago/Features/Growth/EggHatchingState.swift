import SwiftUI
import SwiftData

/// The original fields remain intact; nil cycle IDs identify legacy hatched data.
@Model
final class EggHatchingState {
    @Attribute(.unique) var id: String
    var hatchedAt: Date
    var currentEggID: UUID?
    var pendingCharacterID: UUID?

    init(hatchedAt: Date = .now) {
        id = "mascot"
        self.hatchedAt = hatchedAt
        currentEggID = UUID()
    }
}

@Model
final class HatchedCharacter {
    @Attribute(.unique) var id: UUID
    var number: Int
    var hatchedAt: Date
    var kind: String
    var sourceRecordID: UUID?

    var name: String { kind == "photoCat" ? "カメラねこ" : "すきねこ" }
    var imageAsset: String { kind == "photoCat" ? "PhotoCat" : "CatWelcome" }
    var genre: String { kind == "photoCat" ? "写真" : "" }

    init(id: UUID, number: Int, hatchedAt: Date, kind: String = "cat") {
        self.id = id
        self.number = number
        self.hatchedAt = hatchedAt
        self.kind = kind
    }
}

@MainActor
enum EggHatchingStore {
    /// Additive migration: preserve the legacy date and register its cat atomically.
    static func prepare(in container: ModelContainer) throws {
        let context = container.mainContext
        guard !context.hasChanges else { throw Failure.pendingChanges }
        let state = try context.fetch(FetchDescriptor<EggHatchingState>()).first
        if let state, state.currentEggID != nil { return }
        do {
            if let state {
                let id = UUID()
                let characters = try context.fetch(FetchDescriptor<HatchedCharacter>())
                context.insert(HatchedCharacter(id: id, number: (characters.map(\.number).max() ?? 0) + 1,
                                                hatchedAt: state.hatchedAt))
                state.currentEggID = id
                state.pendingCharacterID = id
            } else {
                context.insert(EggHatchingState())
            }
            try context.save()
        } catch { context.rollback(); throw error }
    }

    /// Stages changes in the record's transaction; only a saved fun photo can hatch.
    static func registerPhotoHatch(in context: ModelContext, missionID: String,
                                   feeling: ExperienceFeeling, recordID: UUID, date: Date) throws -> UUID? {
        guard missionID == "photo.nearby-beauty", feeling == .fun else { return nil }
        guard let state = try context.fetch(FetchDescriptor<EggHatchingState>()).first,
              let eggID = state.currentEggID, state.pendingCharacterID == nil else { return nil }
        let characters = try context.fetch(FetchDescriptor<HatchedCharacter>())
        guard !characters.contains(where: { $0.id == eggID || $0.sourceRecordID == recordID }) else { return nil }
        let character = HatchedCharacter(id: eggID, number: (characters.map(\.number).max() ?? 0) + 1,
                                         hatchedAt: date, kind: "photoCat")
        character.sourceRecordID = recordID
        context.insert(character)
        state.hatchedAt = date
        state.pendingCharacterID = eggID
        return eggID
    }

    static func startNextEgg(in container: ModelContainer, after characterID: UUID,
                             commit: (ModelContext) throws -> Void = { try $0.save() }) throws -> Bool {
        let context = container.mainContext
        guard !context.hasChanges else { throw Failure.pendingChanges }
        guard let state = try context.fetch(FetchDescriptor<EggHatchingState>()).first,
              state.pendingCharacterID == characterID else { return false }
        state.currentEggID = UUID()
        state.pendingCharacterID = nil
        do { try commit(context); return true }
        catch { context.rollback(); throw error }
    }
    enum Failure: Error { case pendingChanges }
}

private struct EggHasHatchedKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var eggHasHatched: Bool {
        get { self[EggHasHatchedKey.self] }
        set { self[EggHasHatchedKey.self] = newValue }
    }
}
