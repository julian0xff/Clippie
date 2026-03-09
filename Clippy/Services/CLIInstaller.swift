import Foundation

/// Installs/uninstalls the bundled clipcopy CLI to ~/.local/bin/.
enum CLIInstaller {
    private static let installDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".local/bin")
    private static let installPath = installDir.appendingPathComponent("clipcopy")

    static var isInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: installPath.path)
    }

    static func install() throws {
        guard let bundledScript = Bundle.main.url(forResource: "clipcopy", withExtension: nil) else {
            throw CLIInstallerError.scriptNotFound
        }

        let fm = FileManager.default
        try fm.createDirectory(at: installDir, withIntermediateDirectories: true)

        // Remove existing file if present
        if fm.fileExists(atPath: installPath.path) {
            try fm.removeItem(at: installPath)
        }

        // Copy the script
        try fm.copyItem(at: bundledScript, to: installPath)

        // Ensure it's executable
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installPath.path)
    }

    static func uninstall() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: installPath.path) {
            try fm.removeItem(at: installPath)
        }
    }
}

enum CLIInstallerError: LocalizedError {
    case scriptNotFound

    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "Bundled clipcopy script not found in app resources."
        }
    }
}
