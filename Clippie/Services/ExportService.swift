import AppKit
import Foundation

@MainActor
struct ExportService {
    static func exportDay(entries: [ClipboardEntry], dateString: String) {
        let panel = NSSavePanel()
        panel.title = "Export Clipboard History"
        panel.nameFieldStringValue = "Clippie-\(dateString.replacingOccurrences(of: " ", with: "-")).md"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var markdown = "# Clipboard History — \(dateString)\n\n"

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none

        let imagesDir = url.deletingLastPathComponent().appendingPathComponent(
            url.deletingPathExtension().lastPathComponent + "-images",
            isDirectory: true
        )
        var hasImages = false

        for entry in entries {
            let time = timeFormatter.string(from: entry.timestamp)
            let source = entry.sourceAppName.map { " — \($0)" } ?? ""

            switch entry.contentType {
            case .text:
                let text = entry.textContent ?? entry.preview ?? ""
                if text.contains("\n") {
                    markdown += "### \(time)\(source)\n\n```\n\(text)\n```\n\n"
                } else {
                    markdown += "- **\(time)**\(source): \(text)\n"
                }

            case .image:
                if let fileName = entry.imageFileName {
                    if !hasImages {
                        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                        hasImages = true
                    }
                    let destURL = imagesDir.appendingPathComponent(fileName)
                    try? ImageStorageManager.shared.copyImage(fileName: fileName, to: destURL)
                    let relativePath = "\(imagesDir.lastPathComponent)/\(fileName)"
                    markdown += "- **\(time)**\(source): ![image](\(relativePath))\n"
                }

            case .file:
                let name = entry.fileName ?? entry.filePath ?? "Unknown file"
                markdown += "- **\(time)**\(source): 📄 \(name)\n"
                if let path = entry.filePath {
                    markdown += "  - Path: `\(path)`\n"
                }
            }
        }

        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("ExportService: Failed to write export: \(error)")
        }
    }
}
