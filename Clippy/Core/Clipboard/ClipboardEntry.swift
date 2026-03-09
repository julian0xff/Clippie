import Foundation
import GRDB

struct ClipboardEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var timestamp: Date
    var contentType: ClipboardContentType
    var textContent: String?
    var preview: String?
    var imageFileName: String?
    var filePath: String?
    var fileName: String?
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var byteSize: Int64

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        contentType: ClipboardContentType,
        textContent: String? = nil,
        preview: String? = nil,
        imageFileName: String? = nil,
        filePath: String? = nil,
        fileName: String? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        byteSize: Int64 = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.contentType = contentType
        self.textContent = textContent
        self.preview = preview
        self.imageFileName = imageFileName
        self.filePath = filePath
        self.fileName = fileName
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.byteSize = byteSize
    }
}

// MARK: - GRDB Support

extension ClipboardEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "clipboardEntries"

    enum Columns: String, ColumnExpression {
        case id, timestamp, contentType
        case textContent, preview
        case imageFileName, filePath, fileName
        case sourceAppBundleID, sourceAppName
        case byteSize
    }
}

extension ClipboardContentType: DatabaseValueConvertible {
    var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ClipboardContentType? {
        guard let rawValue = String.fromDatabaseValue(dbValue) else { return nil }
        return ClipboardContentType(rawValue: rawValue)
    }
}
