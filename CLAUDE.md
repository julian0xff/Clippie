# Clippy

A lightweight clipboard history manager for macOS. Automatically captures text, images, and file references into a searchable, organized SQLite database. Accessed via menu bar popover and a dedicated history window.

## Architecture

**App type:** Menu bar only (`LSUIElement = true`) — no dock icon by default. NSStatusItem with paperclip icon opens a popover for recent clips; a separate history window shows the full searchable database.

**Entry point:** `ClippyApp.swift` uses `@NSApplicationDelegateAdaptor` → `AppDelegate.swift` owns all state objects, wires up the status bar controller, and manages window lifecycle.

### Core Objects (all created in AppDelegate)

| Object | Role |
|--------|------|
| `ClipboardStore` | SQLite CRUD wrapper via GRDB (@MainActor). In-memory array + persistent database |
| `ClipboardMonitor` | Polls `NSPasteboard` every 0.5s, detects changes via `changeCount`, inserts new entries |
| `SettingsStore` | `@AppStorage`-backed preferences (capture toggles, retention, appearance) |
| `ImageStorageManager` | Singleton. Saves/loads PNG images, generates cached thumbnails |
| `ExportService` | Static utility for per-day Markdown export with embedded images |

### Data Flow

```
NSPasteboard (system clipboard)
    |
ClipboardMonitor (polls every 0.5s via Timer)
    |
ClipboardStore (in-memory array + SQLite persistence)
    |
SwiftUI Views (observe @Published entries)
```

**Capture priority:** files > images > text
**De-duplication:** Skips consecutive identical entries
**App filtering:** Checks `settingsStore.isAppIgnored(bundleID)` before capturing

### UI Layer

- **`StatusBarController`** — NSStatusItem with NSPopover (320x400), shows recent clips with quick copy
- **`HistoryView`** — Main window (700x600) with day-grouped list, search, type filter, stats bar
- **`ClipEntryRow`** — List item with hover actions: copy, open in Finder (files), expand (long text), delete. Double-tap to copy
- **`SettingsView`** — Tab-based (General, Appearance, Storage, About) at 480x360
- **`OnboardingView`** — 3-step welcome flow (intro, hotkey setup, ready)

## Project Structure

```
Clippy/
├── AppDelegate.swift                  # App lifecycle, state creation, window management
├── ClippyApp.swift                   # SwiftUI @main, Settings + History scenes
├── Core/Clipboard/
│   ├── ClipboardContentType.swift     # Enum: text, image, file
│   ├── ClipboardEntry.swift           # Data model (GRDB FetchableRecord + PersistableRecord)
│   └── ClipboardMonitor.swift         # Clipboard change detection via NSPasteboard polling
├── Storage/
│   ├── ClipboardStore.swift           # GRDB DatabaseQueue wrapper, CRUD, search, stats
│   ├── SettingsStore.swift            # @AppStorage preferences
│   └── ImageStorageManager.swift      # PNG persistence, thumbnail cache (NSCache)
├── Services/
│   ├── HotkeyManager.swift            # KeyboardShortcuts extension (Cmd+Shift+V)
│   └── ExportService.swift            # Markdown export with NSSavePanel
├── UI/
│   ├── MainWindow/
│   │   ├── HistoryView.swift          # Main history list with search + stats
│   │   ├── DaySection.swift           # Date-grouped header with export button
│   │   └── ClipEntryRow.swift         # Individual entry row with hover actions
│   ├── MenuBar/
│   │   └── StatusBarController.swift  # NSStatusItem + popover
│   ├── Settings/
│   │   ├── SettingsView.swift         # Tab container
│   │   ├── GeneralSettingsView.swift
│   │   ├── AppearanceSettingsView.swift
│   │   ├── StorageSettingsView.swift
│   │   └── AboutSettingsView.swift
│   └── Onboarding/
│       └── OnboardingView.swift       # 3-step welcome flow
└── Resources/
    ├── Info.plist
    ├── Clippy.entitlements           # Empty (no special permissions needed)
    └── Assets.xcassets/
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | >= 2.0.0 | Global hotkey recording & handling |
| [GRDB.swift](https://github.com/groue/GRDB.swift) | >= 7.0.0 | Type-safe SQLite wrapper, migrations, queries |

## Build

```bash
xcodegen generate
xcodebuild -project Clippy.xcodeproj -scheme Clippy -destination 'platform=macOS,arch=arm64' build
```

**Requirements:** macOS 13.0+, Apple Silicon (arm64 only), Xcode 15+

### Build Targets

| Target | Bundle ID | Purpose |
|--------|-----------|---------|
| `Clippy` | `dev.julian0xff.clippy` | Production build |
| `ClippyDev` | `dev.julian0xff.clippy.dev` | Dev build — runs alongside production with separate data |

## Data Storage

| Data | Location | Format |
|------|----------|--------|
| Preferences | `~/Library/Preferences/dev.julian0xff.clippy.plist` | UserDefaults |
| Clipboard database | `~/Library/Application Support/Clippy/clipboard.sqlite` | SQLite (GRDB) |
| Saved images | `~/Library/Application Support/Clippy/images/` | PNG (UUID.png) |

### Database Schema (table: `clipboardEntries`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT | UUID, primary key |
| `timestamp` | DATETIME | Indexed |
| `contentType` | TEXT | text, image, file |
| `textContent` | TEXT | Nullable |
| `preview` | TEXT | First 100 chars, nullable |
| `imageFileName` | TEXT | UUID.png reference, nullable |
| `filePath` | TEXT | Nullable |
| `fileName` | TEXT | Nullable |
| `sourceAppBundleID` | TEXT | Nullable |
| `sourceAppName` | TEXT | Nullable |
| `byteSize` | INTEGER | |

### Settings (SettingsStore @AppStorage keys)

```
captureText = true              captureImages = true
captureFiles = true             showDockIcon = false
popoverItemCount = 5            showPreviewInPopover = true
retentionDays = 30              maxImageSizeMB = 5
ignoredAppBundleIDs = ""        showSourceApp = true
showByteSize = false            compactRows = false (unused in UI)
hasCompletedOnboarding = false
```

## Features

- **Text capture** — Auto-trim, 100-char preview, de-duplication
- **Image capture** — NSImage → PNG, configurable size limit (default 5MB), thumbnail caching via CGImageSource
- **File capture** — Path + filename tracking, "Open in Finder" button
- **Source tracking** — Detects frontmost app bundle ID + name
- **Search** — Full-text LIKE across text, preview, filename, source app
- **Type filter** — Segmented picker: All / Text / Image / File
- **Day grouping** — Entries grouped by date with export button per day
- **Auto-purge** — Deletes entries older than retention period on launch
- **Export** — Per-day Markdown with embedded images copied to `-images/` subdirectory
- **Global hotkey** — Cmd+Shift+V (configurable via KeyboardShortcuts)
- **Copy feedback** — "Tink" system sound on copy
- **Ignored apps** — Comma-separated bundle IDs to skip capturing

## Key Implementation Details

- **Polling:** ClipboardMonitor uses `Timer` at 0.5s interval, detects changes via `NSPasteboard.changeCount`
- **Thread safety:** All stores marked `@MainActor`, GRDB provides thread-safe `DatabaseQueue`
- **Thumbnail caching:** `NSCache<NSString, NSImage>` with size-based keys, lazy generation via `CGImageSource`
- **Image storage:** PNG format with UUID filenames in Application Support
- **Dock icon policy:** Dynamic `NSApplication.setActivationPolicy()` toggling based on settings + visible windows
- **Database migrations:** GRDB migrator with versioned migrations (current: "v1")
- **Error handling:** Graceful degradation with `print()` logging, no throw/catch

## Development

### Reset Data

```bash
# Delete clipboard history
rm ~/Library/Application\ Support/Clippy/clipboard.sqlite
rm -rf ~/Library/Application\ Support/Clippy/images/

# Clear preferences
defaults delete dev.julian0xff.clippy
```

Current version: **0.1.0**
