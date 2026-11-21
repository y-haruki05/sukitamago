import UIKit
import ImageIO

/// Decode only a display-sized bitmap, including EXIF orientation, off the main thread.
enum MissionPhotoLoader {
    static func image(from data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled,
                  let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2048,
                    kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary) else { return nil as UIImage? }
            return UIImage(cgImage: thumbnail)
        }.value
    }
}
