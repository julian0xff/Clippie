import SwiftUI

struct StorageSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var clipboardStore: ClipboardStore
    @State private var showingPurgeConfirmation = false
    @State private var imageStorageSize: Int64 = 0

    var body: some View {
        Form {
            Section("Retention") {
                Stepper("Keep clips for \(settingsStore.retentionDays) days", value: $settingsStore.retentionDays, in: 1...365)
                Text("Older entries are automatically deleted on launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Images") {
                Stepper("Max image size: \(settingsStore.maxImageSizeMB) MB", value: $settingsStore.maxImageSizeMB, in: 1...50)
                Text("Images larger than this will be skipped.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Storage Usage") {
                LabeledContent("Clipboard entries") {
                    Text("\(clipboardStore.totalCount)")
                }
                LabeledContent("Database + images") {
                    Text(formatBytes(clipboardStore.totalSize + imageStorageSize))
                }
                LabeledContent("Image storage") {
                    Text(formatBytes(imageStorageSize))
                }
            }

            Section {
                Button("Delete All Clipboard History", role: .destructive) {
                    showingPurgeConfirmation = true
                }
                .confirmationDialog(
                    "Delete all clipboard history?",
                    isPresented: $showingPurgeConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete All", role: .destructive) {
                        clipboardStore.deleteAll()
                    }
                } message: {
                    Text("This will permanently delete all clipboard entries and saved images. This action cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            imageStorageSize = ImageStorageManager.shared.totalImageStorageSize()
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
