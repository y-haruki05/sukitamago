import SwiftUI
import SwiftData

/// One durable confirmation per mascot. Experience deletion never touches this model.
@Model
final class EggHatchingState {
    @Attribute(.unique) var id: String
    var hatchedAt: Date

    init(hatchedAt: Date = .now) {
        self.id = "mascot"
        self.hatchedAt = hatchedAt
    }
}

@MainActor
enum EggHatchingStore {
    /// Returns true only for the first successful confirmation, never for a retry/redraw.
    static func hatch(in container: ModelContainer,
                      commit: (ModelContext) throws -> Void = { try $0.save() }) throws -> Bool {
        let context = container.mainContext
        guard !context.hasChanges else { throw Failure.pendingChanges }
        guard try context.fetchCount(FetchDescriptor<EggHatchingState>()) == 0 else { return false }
        context.insert(EggHatchingState())
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
