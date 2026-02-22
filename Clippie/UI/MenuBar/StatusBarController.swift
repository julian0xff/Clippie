import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    init(clipboardStore: ClipboardStore, clipboardMonitor: ClipboardMonitor, settingsStore: SettingsStore) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        super.init()

        let contentView = StatusBarPopoverView(
            clipboardStore: clipboardStore,
            clipboardMonitor: clipboardMonitor,
            settingsStore: settingsStore
        )
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Clippie")
            icon?.isTemplate = true
            button.image = icon
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopoverAndStopMonitor()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startEventMonitor()
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopoverAndStopMonitor()
        }
    }

    private func closePopoverAndStopMonitor() {
        popover.performClose(nil)
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
}

// MARK: - Popover View

struct StatusBarPopoverView: View {
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("Clippie")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(clipboardMonitor.isMonitoring ? .green : .red)
                        .frame(width: 6, height: 6)
                    Text(clipboardMonitor.isMonitoring ? "Monitoring" : "Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Recent clips
            let recent = clipboardStore.recentEntries(limit: settingsStore.popoverItemCount)
            if recent.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No clips yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Copy something to get started")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(recent) { entry in
                            PopoverClipRow(entry: entry, clipboardStore: clipboardStore, clipboardMonitor: clipboardMonitor)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Button {
                    openWindow(id: "history")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(clipboardStore.todayCount) today")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}

struct PopoverClipRow: View {
    let entry: ClipboardEntry
    let clipboardStore: ClipboardStore
    let clipboardMonitor: ClipboardMonitor
    @State private var thumbnail: NSImage?

    var body: some View {
        Button {
            copyToClipboard(entry)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.contentType.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.preview ?? "No preview")
                        .font(.caption)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Text(relativeTime(entry.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        if let app = entry.sourceAppName {
                            Text("· \(app)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                if entry.contentType == .image {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .cornerRadius(4)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.00001)) // Hit target
        .cornerRadius(6)
        .task(id: entry.imageFileName) {
            guard entry.contentType == .image, let fileName = entry.imageFileName else { return }
            thumbnail = ImageStorageManager.shared.loadThumbnail(fileName: fileName, maxSize: 32)
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

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
