import SwiftUI

final class SettingsStore: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("captureText") var captureText = true
    @AppStorage("captureImages") var captureImages = true
    @AppStorage("captureFiles") var captureFiles = true
    @AppStorage("showDockIcon") var showDockIcon = false
    @AppStorage("popoverItemCount") var popoverItemCount = 5
    @AppStorage("showPreviewInPopover") var showPreviewInPopover = true
    @AppStorage("retentionDays") var retentionDays = 30
    @AppStorage("maxImageSizeMB") var maxImageSizeMB = 5
    @AppStorage("ignoredAppBundleIDs") var ignoredAppBundleIDs = ""
    @AppStorage("showSourceApp") var showSourceApp = true
    @AppStorage("showByteSize") var showByteSize = false
    @AppStorage("compactRows") var compactRows = false

    var maxImageSizeBytes: Int64 {
        Int64(maxImageSizeMB) * 1024 * 1024
    }

    func isAppIgnored(_ bundleID: String) -> Bool {
        ignoredAppBundleIDs.split(separator: ",").contains(Substring(bundleID))
    }

    func setAppIgnored(_ bundleID: String, ignored: Bool) {
        var set = Set(ignoredAppBundleIDs.split(separator: ",").map(String.init))
        if ignored {
            set.insert(bundleID)
        } else {
            set.remove(bundleID)
        }
        ignoredAppBundleIDs = set.joined(separator: ",")
    }
}
