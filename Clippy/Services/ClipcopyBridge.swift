import AppKit
import Foundation

/// Bridges clipboard text writes to the bundled `clipcopy` CLI.
/// Images and files still go through NSPasteboard directly.
@MainActor
enum ClipcopyBridge {
    /// Copy text to the system clipboard using the bundled clipcopy script.
    /// Falls back to NSPasteboard if clipcopy is not found.
    @discardableResult
    static func copyText(_ text: String) -> Bool {
        guard let scriptURL = Bundle.main.url(forResource: "clipcopy", withExtension: nil) else {
            // Fallback: direct pasteboard write
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptURL.path]

        let pipe = Pipe()
        process.standardInput = pipe

        do {
            try process.run()
            pipe.fileHandleForWriting.write(Data(text.utf8))
            pipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            // Fallback: direct pasteboard write
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            return true
        }
    }
}
