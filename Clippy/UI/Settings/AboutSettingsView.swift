import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var showingResetConfirmation = false
    @State private var cliInstalled = CLIInstaller.isInstalled
    @State private var cliError: String?

    var body: some View {
        Form {
            Section("About Clippy") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                }
                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                }
            }

            Section {
                Text("Clippy is a lightweight clipboard manager for macOS. It captures text, images, and file references, organizing them by day for easy access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("CLI Tools") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("clipcopy")
                            .font(.caption.bold())
                        Text("The CLI that powers Clippy's clipboard operations.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if cliInstalled {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if cliInstalled {
                    Button("Uninstall CLI") {
                        do {
                            try CLIInstaller.uninstall()
                            cliInstalled = false
                            cliError = nil
                        } catch {
                            cliError = error.localizedDescription
                        }
                    }
                } else {
                    Button("Install to ~/.local/bin") {
                        do {
                            try CLIInstaller.install()
                            cliInstalled = true
                            cliError = nil
                        } catch {
                            cliError = error.localizedDescription
                        }
                    }
                }

                if let cliError {
                    Text(cliError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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
