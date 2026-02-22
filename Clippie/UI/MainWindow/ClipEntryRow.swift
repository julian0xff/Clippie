import AppKit
import SwiftUI

struct ClipEntryRow: View {
    let entry: ClipboardEntry
    let clipboardStore: ClipboardStore
    let clipboardMonitor: ClipboardMonitor
    let settingsStore: SettingsStore
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                // Content type icon
                Image(systemName: entry.contentType.systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                // Preview content
                VStack(alignment: .leading, spacing: 2) {
                    previewContent

                    HStack(spacing: 6) {
                        Text(timeString(entry.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        if settingsStore.showSourceApp, let app = entry.sourceAppName {
                            Text(app)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if settingsStore.showByteSize {
                            Text(formatBytes(entry.byteSize))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                // Thumbnail for images
                if entry.contentType == .image {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 48, height: 48)
                    }
                }

                // Action buttons (visible on hover)
                if isHovered {
                    HStack(spacing: 4) {
                        Button {
                            copyToClipboard(entry)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy")

                        if entry.contentType == .file, let path = entry.filePath {
                            Button {
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                            } label: {
                                Image(systemName: "folder")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .help("Open in Finder")
                        }

                        if entry.contentType == .text, let text = entry.textContent, text.count > 100 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .help(isExpanded ? "Collapse" : "Expand")
                        }

                        Button {
                            if let fileName = entry.imageFileName {
                                ImageStorageManager.shared.deleteImage(fileName: fileName)
                            }
                            clipboardStore.delete(entry)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete")
                    }
                }
            }

            // Expanded text content
            if isExpanded, entry.contentType == .text, let text = entry.textContent {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            copyToClipboard(entry)
        }
        .task(id: entry.imageFileName) {
            guard entry.contentType == .image, let fileName = entry.imageFileName else { return }
            thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: fileName, maxSize: 48)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch entry.contentType {
        case .text:
            Text(entry.preview ?? "Empty text")
                .font(.system(.caption, design: .monospaced))
                .lineLimit(isExpanded ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .image:
            Text(entry.preview ?? "Image")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .file:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.fileName ?? "Unknown file")
                    .font(.caption)
                if let path = entry.filePath {
                    Text(path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private func copyToClipboard(_ entry: ClipboardEntry) {
        clipboardMonitor.skipNext()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch entry.contentType {
        case .text:
            if let text = entry.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let fileName = entry.imageFileName,
               let image = ImageStorageManager.shared.loadImage(fileName: fileName) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let path = entry.filePath {
                let url = URL(fileURLWithPath: path)
                pasteboard.writeObjects([url as NSURL])
            }
        }

        NSSound(named: "Tink")?.play()
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
