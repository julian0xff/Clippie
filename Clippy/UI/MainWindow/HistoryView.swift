import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var clipboardStore: ClipboardStore
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var searchText = ""
    @State private var filterType: ClipboardContentType?

    private var filteredEntries: [ClipboardEntry] {
        var results: [ClipboardEntry]

        if searchText.isEmpty {
            results = clipboardStore.entries
        } else {
            results = clipboardStore.search(searchText)
        }

        if let filterType {
            results = results.filter { $0.contentType == filterType }
        }

        return results
    }

    private var groupedEntries: [(date: String, entries: [ClipboardEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        var grouped: [(date: String, entries: [ClipboardEntry])] = []
        var currentDay = ""
        var currentEntries: [ClipboardEntry] = []

        for entry in filteredEntries {
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

    var body: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack(spacing: 16) {
                Label("\(clipboardStore.totalCount) clips", systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(formatBytes(clipboardStore.totalSize), systemImage: "externaldrive")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(clipboardStore.todayCount) today", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Type filter
                Picker("Filter", selection: $filterType) {
                    Text("All").tag(ClipboardContentType?.none)
                    ForEach(ClipboardContentType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(ClipboardContentType?.some(type))
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Clip list
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history yet" : "No results for \"\(searchText)\"")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "Copy something to get started" : "Try a different search term")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedEntries, id: \.date) { group in
                        DaySection(
                            dateString: group.date,
                            entries: group.entries,
                            clipboardStore: clipboardStore,
                            clipboardMonitor: clipboardMonitor,
                            settingsStore: settingsStore
                        )
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .searchable(text: $searchText, prompt: "Search clips...")
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            clipboardStore.loadAll()
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
