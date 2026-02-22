import SwiftUI

@main
struct ClippieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsStore)
                .environmentObject(appDelegate.clipboardStore)
        }
        .defaultSize(width: 480, height: 360)

        Window("Clipboard History", id: "history") {
            HistoryView()
                .environmentObject(appDelegate.clipboardStore)
                .environmentObject(appDelegate.clipboardMonitor)
                .environmentObject(appDelegate.settingsStore)
                .onReceive(NotificationCenter.default.publisher(for: .openHistoryWindow)) { _ in
                    openWindow(id: "history")
                }
        }
        .defaultSize(width: 700, height: 600)
    }
}
