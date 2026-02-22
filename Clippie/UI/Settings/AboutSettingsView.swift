import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("About Clippie") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                }
                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                }
            }

            Section {
                Text("Clippie is a lightweight clipboard manager for macOS. It captures text, images, and file references, organizing them by day for easy access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reset All Settings", role: .destructive) {
                    showingResetConfirmation = true
                }
                .confirmationDialog(
                    "Reset all settings?",
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        resetSettings()
                    }
                } message: {
                    Text("This will reset all settings to their default values. Your clipboard history will not be affected.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func resetSettings() {
        settingsStore.captureText = true
        settingsStore.captureImages = true
        settingsStore.captureFiles = true
        settingsStore.showDockIcon = false
        settingsStore.popoverItemCount = 5
        settingsStore.showPreviewInPopover = true
        settingsStore.retentionDays = 30
        settingsStore.maxImageSizeMB = 5
        settingsStore.ignoredAppBundleIDs = ""
        settingsStore.showSourceApp = true
        settingsStore.showByteSize = false
        settingsStore.compactRows = false
    }
}
