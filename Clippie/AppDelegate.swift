import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    let clipboardStore = ClipboardStore()
    lazy var clipboardMonitor = ClipboardMonitor(clipboardStore: clipboardStore, settingsStore: settingsStore)

    private var statusBarController: StatusBarController?
    private var hasShownOnboarding = false
    private var windowObservers: [NSObjectProtocol] = []
    private var currentPolicy: NSApplication.ActivationPolicy = .accessory

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let policy: NSApplication.ActivationPolicy = settingsStore.showDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
        currentPolicy = policy
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(
            clipboardStore: clipboardStore,
            clipboardMonitor: clipboardMonitor,
            settingsStore: settingsStore
        )

        setupHotkey()
        setupWindowObservers()
        purgeOldEntries()
        clipboardStore.loadAll()
        clipboardMonitor.start()
        checkFirstLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
    }

    private func setupWindowObservers() {
        let becomeKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDockIconPolicy()
        }
        let willClose = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let closingWindow = notification.object as? NSWindow
            DispatchQueue.main.async {
                self?.updateDockIconPolicy(excluding: closingWindow)
            }
        }
        windowObservers = [becomeKey, willClose]
    }

    func updateDockIconPolicy(excluding closingWindow: NSWindow? = nil) {
        let desiredPolicy: NSApplication.ActivationPolicy

        if settingsStore.showDockIcon {
            desiredPolicy = .regular
        } else {
            let hasVisibleWindow = NSApp.windows.contains { window in
                window !== closingWindow
                    && window.isVisible
                    && !(window is NSPanel)
                    && window.level == .normal
            }
            desiredPolicy = hasVisibleWindow ? .regular : .accessory
        }

        guard desiredPolicy != currentPolicy else { return }
        NSApp.setActivationPolicy(desiredPolicy)
        currentPolicy = desiredPolicy

        if desiredPolicy == .regular {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .toggleHistoryWindow) {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "history" }),
               window.isVisible {
                window.close()
            } else {
                if let openWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "history" }) {
                    openWindow.makeKeyAndOrderFront(nil)
                } else {
                    // Use notification to trigger openWindow from SwiftUI
                    NotificationCenter.default.post(name: .openHistoryWindow, object: nil)
                }
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func purgeOldEntries() {
        let purged = clipboardStore.purgeOldEntries(olderThanDays: settingsStore.retentionDays)
        for entry in purged {
            if let fileName = entry.imageFileName {
                ImageStorageManager.shared.deleteImage(fileName: fileName)
            }
        }
        if !purged.isEmpty {
            print("Clippie: Purged \(purged.count) old entries")
        }
    }

    private func checkFirstLaunch() {
        if !settingsStore.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    func showOnboarding() {
        guard !hasShownOnboarding else { return }
        hasShownOnboarding = true

        let onboardingView = OnboardingView(settingsStore: settingsStore)
        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to Clippie"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 460, height: 520))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let openHistoryWindow = Notification.Name("openHistoryWindow")
}
