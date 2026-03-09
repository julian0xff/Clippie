import Foundation

enum ClipboardContentType: String, Codable, CaseIterable {
    case text
    case image
    case file

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .file: return "File"
        }
    }

    var systemImage: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}
