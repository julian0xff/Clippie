import SwiftUI

struct DaySection: View {
    let dateString: String
    let entries: [ClipboardEntry]
    let clipboardStore: ClipboardStore
    let clipboardMonitor: ClipboardMonitor
    let settingsStore: SettingsStore

    var body: some View {
        Section {
            ForEach(entries) { entry in
                ClipEntryRow(
                    entry: entry,
                    clipboardStore: clipboardStore,
                    clipboardMonitor: clipboardMonitor,
                    settingsStore: settingsStore
                )
            }
        } header: {
            HStack {
                Text(dateString)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(entries.count) clip\(entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    ExportService.exportDay(entries: entries, dateString: dateString)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}
