import UIKit
import ImageIO

/// App-private JPEGs are included in device/iCloud backup, together with the database.
/// Never writes to Photos. Tests supply their own temporary directory.
struct ExperiencePhotoStore {
    let directory: URL
    private let removeFile: @Sendable (URL) throws -> Void

    init(directory: URL, removeFile: @escaping @Sendable (URL) throws -> Void = {
        try FileManager.default.removeItem(at: $0)
    }) {
        self.directory = directory
        self.removeFile = removeFile
    }
    enum Failure: Error { case invalidFilename, encoding }

    func url(for filename: String) throws -> URL {
        guard filename == URL(fileURLWithPath: filename).lastPathComponent,
              filename.hasSuffix(".jpg"), UUID(uuidString: String(filename.dropLast(4))) != nil else {
            throw Failure.invalidFilename
        }
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    func save(_ image: UIImage, id: UUID) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = id.uuidString + ".jpg"
        let target = try url(for: filename)
        // Normalize orientation and bound even camera originals to the existing 2048px budget.
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let ratio = min(1, 2048 / max(pixels.width, pixels.height))
        let size = CGSize(width: pixels.width * ratio, height: pixels.height * ratio)
        guard size.width > 0, size.height > 0 else { throw Failure.encoding }
        let normalized: UIImage
        if image.imageOrientation == .up, ratio == 1 {
            // PhotosPicker already downsampled and oriented this image. Reuse its pixels.
            normalized = image
        } else {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            normalized = UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        guard let data = normalized.jpegData(compressionQuality: 0.82) else { throw Failure.encoding }
        try data.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return filename
    }

    func read(_ filename: String, maxPixelSize: Int) -> UIImage? {
        guard let target = try? url(for: filename),
              let source = CGImageSourceCreateWithURL(target as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func delete(_ filename: String) throws {
        let target = try url(for: filename)
        if FileManager.default.fileExists(atPath: target.path) { try removeFile(target) }
    }
}
