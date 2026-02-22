import KeyboardShortcuts
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Toggle History Window:", name: .toggleHistoryWindow)
            }

            Section("Capture") {
                Toggle("Capture text", isOn: $settingsStore.captureText)
                Toggle("Capture images", isOn: $settingsStore.captureImages)
                Toggle("Capture file references", isOn: $settingsStore.captureFiles)
            }

            Section("App Behavior") {
                Toggle("Show dock icon", isOn: $settingsStore.showDockIcon)
                    .onChange(of: settingsStore.showDockIcon) { _ in
                        if let delegate = NSApp.delegate as? AppDelegate {
                            delegate.updateDockIconPolicy()
                        }
                    }
            }

            Section("Ignored Apps") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bundle IDs (comma-separated)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. com.1password.app", text: $settingsStore.ignoredAppBundleIDs)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
