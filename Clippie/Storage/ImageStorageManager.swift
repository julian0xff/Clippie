import AppKit
import CoreGraphics
import Foundation
import ImageIO

@MainActor
final class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let thumbnailCache = NSCache<NSString, NSImage>()

    private let imagesDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Clippie/images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Save

    func saveImage(_ image: NSImage) -> (fileName: String, byteSize: Int64)? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let fileName = "\(UUID().uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL, options: .atomic)
            return (fileName: fileName, byteSize: Int64(pngData.count))
        } catch {
            print("ImageStorageManager: Failed to save image: \(error)")
            return nil
        }
    }

    // MARK: - Load

    func loadImage(fileName: String) -> NSImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: fileURL)
    }

    func loadThumbnail(fileName: String, maxSize: CGFloat = 80) -> NSImage? {
        let cacheKey = "\(fileName)_\(Int(maxSize))" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let thumbnail = NSImage(cgImage: cgThumb, size: NSSize(width: cgThumb.width, height: cgThumb.height))
        thumbnailCache.setObject(thumbnail, forKey: cacheKey)
        return thumbnail
    }

    // MARK: - Delete

    func deleteImage(fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Copy to export

    func copyImage(fileName: String, to destination: URL) throws {
        let source = imagesDirectory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: source, to: destination)
    }

    // MARK: - Storage info

    func totalImageStorageSize() -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    func imageFileURL(fileName: String) -> URL {
        imagesDirectory.appendingPathComponent(fileName)
    }
}
