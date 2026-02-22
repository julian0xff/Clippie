import Foundation
import GRDB

@MainActor
final class ClipboardStore: ObservableObject {
    private var dbQueue: DatabaseQueue?

    @Published var entries: [ClipboardEntry] = []

    private static var databaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Clippie", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("clipboard.sqlite")
    }

    init() {
        do {
            dbQueue = try DatabaseQueue(path: Self.databaseURL.path)
            try migrate()
        } catch {
            print("ClipboardStore: Failed to open database: \(error)")
        }
    }

    private func migrate() throws {
        guard let dbQueue else { return }
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "clipboardEntries") { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .datetime).notNull().indexed()
                t.column("contentType", .text).notNull()
                t.column("textContent", .text)
                t.column("preview", .text)
                t.column("imageFileName", .text)
                t.column("filePath", .text)
                t.column("fileName", .text)
                t.column("sourceAppBundleID", .text)
                t.column("sourceAppName", .text)
                t.column("byteSize", .integer).notNull().defaults(to: 0)
            }
        }
        try migrator.migrate(dbQueue)
    }

    // MARK: - CRUD

    func insert(_ entry: ClipboardEntry) {
        do {
            try dbQueue?.write { db in
                try entry.insert(db)
            }
            entries.insert(entry, at: 0)
        } catch {
            print("ClipboardStore: Failed to insert entry: \(error)")
        }
    }

    func delete(_ entry: ClipboardEntry) {
        do {
            try dbQueue?.write { db in
                try entry.delete(db)
            }
            entries.removeAll { $0.id == entry.id }
        } catch {
            print("ClipboardStore: Failed to delete entry: \(error)")
        }
    }

    func deleteAll() {
        do {
            try dbQueue?.write { db in
                try ClipboardEntry.deleteAll(db)
            }
            entries.removeAll()
        } catch {
            print("ClipboardStore: Failed to delete all entries: \(error)")
        }
    }

    // MARK: - Queries

    func loadAll() {
        do {
            entries = try dbQueue?.read { db in
                try ClipboardEntry
                    .order(ClipboardEntry.Columns.timestamp.desc)
                    .fetchAll(db)
            } ?? []
        } catch {
            print("ClipboardStore: Failed to load entries: \(error)")
        }
    }

    func search(_ query: String) -> [ClipboardEntry] {
        guard !query.isEmpty else { return entries }
        let pattern = "%\(query)%"
        do {
            return try dbQueue?.read { db in
                try ClipboardEntry
                    .filter(
                        ClipboardEntry.Columns.textContent.like(pattern) ||
                        ClipboardEntry.Columns.preview.like(pattern) ||
                        ClipboardEntry.Columns.fileName.like(pattern) ||
                        ClipboardEntry.Columns.sourceAppName.like(pattern)
                    )
                    .order(ClipboardEntry.Columns.timestamp.desc)
                    .fetchAll(db)
            } ?? []
        } catch {
            print("ClipboardStore: Failed to search entries: \(error)")
            return []
        }
    }

    func recentEntries(limit: Int) -> [ClipboardEntry] {
        do {
            return try dbQueue?.read { db in
                try ClipboardEntry
                    .order(ClipboardEntry.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            } ?? []
        } catch {
            print("ClipboardStore: Failed to fetch recent entries: \(error)")
            return []
        }
    }

    func entriesGroupedByDay() -> [(date: String, entries: [ClipboardEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        var grouped: [(date: String, entries: [ClipboardEntry])] = []
        var currentDay = ""
        var currentEntries: [ClipboardEntry] = []

        for entry in entries {
            let day = formatter.string(from: entry.timestamp)
            if day != currentDay {
                if !currentEntries.isEmpty {
                    grouped.append((date: currentDay, entries: currentEntries))
                }
                currentDay = day
                currentEntries = [entry]
            } else {
                currentEntries.append(entry)
            }
        }
        if !currentEntries.isEmpty {
            grouped.append((date: currentDay, entries: currentEntries))
        }

        return grouped
    }

    func entriesForDate(_ date: Date) -> [ClipboardEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            return try dbQueue?.read { db in
                try ClipboardEntry
                    .filter(ClipboardEntry.Columns.timestamp >= startOfDay && ClipboardEntry.Columns.timestamp < endOfDay)
                    .order(ClipboardEntry.Columns.timestamp.desc)
                    .fetchAll(db)
            } ?? []
        } catch {
            print("ClipboardStore: Failed to fetch entries for date: \(error)")
            return []
        }
    }

    // MARK: - Purge

    func purgeOldEntries(olderThanDays days: Int) -> [ClipboardEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        do {
            let purged = try dbQueue?.read { db in
                try ClipboardEntry
                    .filter(ClipboardEntry.Columns.timestamp < cutoff)
                    .fetchAll(db)
            } ?? []

            try dbQueue?.write { db in
                try ClipboardEntry
                    .filter(ClipboardEntry.Columns.timestamp < cutoff)
                    .deleteAll(db)
            }

            entries.removeAll { $0.timestamp < cutoff }
            return purged
        } catch {
            print("ClipboardStore: Failed to purge old entries: \(error)")
            return []
        }
    }

    // MARK: - Stats

    var totalCount: Int {
        entries.count
    }

    var totalSize: Int64 {
        entries.reduce(0) { $0 + $1.byteSize }
    }

    var todayCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return entries.filter { $0.timestamp >= startOfDay }.count
    }

    func lastEntry() -> ClipboardEntry? {
        entries.first
    }
}
