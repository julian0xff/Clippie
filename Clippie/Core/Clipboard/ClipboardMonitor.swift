import AppKit
import Combine

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published var isMonitoring = false

    private let clipboardStore: ClipboardStore
    private let settingsStore: SettingsStore
    private var timer: Timer?
    private var lastChangeCount: Int
    private var skipNextChange = false

    /// Call before programmatically writing to the pasteboard to prevent the monitor from capturing it.
    func skipNext() {
        skipNextChange = true
    }

    init(clipboardStore: ClipboardStore, settingsStore: SettingsStore) {
        self.clipboardStore = clipboardStore
        self.settingsStore = settingsStore
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    func stop() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip if this change was triggered by our own app (re-copy action)
        if skipNextChange {
            skipNextChange = false
            return
        }

        // Get source app info
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceBundleID = sourceApp?.bundleIdentifier
        let sourceAppName = sourceApp?.localizedName

        // Skip if app is ignored
        if let bundleID = sourceBundleID, settingsStore.isAppIgnored(bundleID) {
            return
        }

        // Detect content type with priority: files > images > text
        if settingsStore.captureFiles, let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], let fileURL = fileURLs.first {
            captureFile(fileURL, sourceBundleID: sourceBundleID, sourceAppName: sourceAppName)
        } else if settingsStore.captureImages, let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage], let image = images.first {
            // Only capture as image if there's no text (avoid capturing rich text as image)
            if pasteboard.string(forType: .string) == nil || !settingsStore.captureText {
                captureImage(image, sourceBundleID: sourceBundleID, sourceAppName: sourceAppName)
            } else if settingsStore.captureText, let text = pasteboard.string(forType: .string) {
                captureText(text, sourceBundleID: sourceBundleID, sourceAppName: sourceAppName)
            }
        } else if settingsStore.captureText, let text = pasteboard.string(forType: .string) {
            captureText(text, sourceBundleID: sourceBundleID, sourceAppName: sourceAppName)
        }
    }

    private func captureText(_ text: String, sourceBundleID: String?, sourceAppName: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // De-duplicate: skip if identical to the last entry
        if let last = clipboardStore.lastEntry(),
           last.contentType == .text,
           last.textContent == text {
            return
        }

        let preview = String(trimmed.prefix(100))
        let entry = ClipboardEntry(
            contentType: .text,
            textContent: text,
            preview: preview,
            sourceAppBundleID: sourceBundleID,
            sourceAppName: sourceAppName,
            byteSize: Int64(text.utf8.count)
        )
        clipboardStore.insert(entry)
    }

    private func captureImage(_ image: NSImage, sourceBundleID: String?, sourceAppName: String?) {
        // Check image size estimate
        guard let tiffData = image.tiffRepresentation else { return }
        let estimatedSize = Int64(tiffData.count)
        if estimatedSize > settingsStore.maxImageSizeBytes {
            return
        }

        guard let result = ImageStorageManager.shared.saveImage(image) else { return }

        // Skip if over size limit after PNG conversion
        if result.byteSize > settingsStore.maxImageSizeBytes {
            ImageStorageManager.shared.deleteImage(fileName: result.fileName)
            return
        }

        let entry = ClipboardEntry(
            contentType: .image,
            preview: "Image (\(Int(image.size.width))×\(Int(image.size.height)))",
            imageFileName: result.fileName,
            sourceAppBundleID: sourceBundleID,
            sourceAppName: sourceAppName,
            byteSize: result.byteSize
        )
        clipboardStore.insert(entry)
    }

    private func captureFile(_ fileURL: URL, sourceBundleID: String?, sourceAppName: String?) {
        let path = fileURL.path
        let fileName = fileURL.lastPathComponent

        // De-duplicate: skip if identical to the last entry
        if let last = clipboardStore.lastEntry(),
           last.contentType == .file,
           last.filePath == path {
            return
        }

        let fileSize: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        } else {
            fileSize = 0
        }

        let entry = ClipboardEntry(
            contentType: .file,
            preview: fileName,
            filePath: path,
            fileName: fileName,
            sourceAppBundleID: sourceBundleID,
            sourceAppName: sourceAppName,
            byteSize: fileSize
        )
        clipboardStore.insert(entry)
    }
}
