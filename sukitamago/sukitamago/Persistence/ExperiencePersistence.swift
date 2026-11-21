import SwiftUI
import SwiftData

struct ExperiencePersistence {
    let container: ModelContainer
    let photos: ExperiencePhotoStore

    static func preferences(testID: String? = nil) throws -> UserDefaults {
        #if DEBUG
        if let testID {
            guard UUID(uuidString: testID) != nil,
                  let defaults = UserDefaults(suiteName: "sukitamago.UITests.\(testID)") else {
                throw CocoaError(.fileReadInvalidFileName)
            }
            return defaults
        }
        #endif
        return .standard
    }

    static func make(inMemory: Bool = false, testID: String? = nil) throws -> Self {
        let schema = Schema([Item.self, ExperienceRecord.self])
        let support = URL.applicationSupportDirectory
        var root = inMemory ? URL.temporaryDirectory.appending(path: "SukitamagoPreview/\(UUID().uuidString)") : support
        #if DEBUG
        if let testID {
            guard UUID(uuidString: testID) != nil else { throw CocoaError(.fileReadInvalidFileName) }
            root = support.appending(path: "UITests/\(testID)")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }
        #endif
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if root != support {
            configuration = ModelConfiguration(schema: schema, url: root.appending(path: "history.store"))
        } else {
            // Keep the original default store location, including legacy Item data.
            configuration = ModelConfiguration(schema: schema)
        }
        return Self(container: try ModelContainer(for: schema, configurations: configuration),
                    photos: ExperiencePhotoStore(directory: root.appending(path: "ExperiencePhotos")))
    }
}

private struct PhotoStoreKey: EnvironmentKey {
    static let defaultValue = ExperiencePhotoStore(directory: URL.applicationSupportDirectory.appending(path: "ExperiencePhotos"))
}
extension EnvironmentValues {
    var experiencePhotos: ExperiencePhotoStore {
        get { self[PhotoStoreKey.self] }
        set { self[PhotoStoreKey.self] = newValue }
    }
}
