#if DEBUG
import SwiftData
import UIKit

/// Only used with a UUID-isolated UI-test store. No release code or user-store writes.
@MainActor
enum GrowthUITestFixtures {
    static func seed(arguments: [String], testID: String?, persistence: ExperiencePersistence,
                     defaults: UserDefaults) throws {
        guard let testID, UUID(uuidString: testID) != nil,
              persistence.photos.directory == URL.applicationSupportDirectory.appending(path: "UITests/\(testID)/ExperiencePhotos"),
              !defaults.bool(forKey: "growthFixtures.seeded"),
              let index = arguments.firstIndex(of: "-growthTestRecordCount"),
              arguments.indices.contains(index + 1), let count = Int(arguments[index + 1]), (0...5).contains(count) else { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80), format: format).image { context in
            UIColor.systemTeal.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        }
        let store = ExperienceRecordStore(container: persistence.container, photos: persistence.photos)
        for number in 0..<count {
            let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number + 1))!
            try store.save(id: id, experience: .first, photo: photo,
                           reflection: ExperienceReflection(feeling: ExperienceFeeling.allCases[number % 3], note: "テスト専用の一歩"),
                           completedAt: Date(timeIntervalSince1970: Double(number)))
        }
        defaults.set(true, forKey: "growthFixtures.seeded")
    }
}
#endif
