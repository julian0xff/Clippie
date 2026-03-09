import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        Form {
            Section("Popover") {
                Stepper("Recent clips in popover: \(settingsStore.popoverItemCount)", value: $settingsStore.popoverItemCount, in: 3...15)
                Toggle("Show preview text in popover", isOn: $settingsStore.showPreviewInPopover)
            }

            Section("History Window") {
                Toggle("Show source app", isOn: $settingsStore.showSourceApp)
                Toggle("Show file size", isOn: $settingsStore.showByteSize)
                Toggle("Compact rows", isOn: $settingsStore.compactRows)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
