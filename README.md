# Clippie

Clipboard history manager for macOS. Automatically captures everything you copy — text, images, and files — and lets you search, browse, and re-paste from your history.

## Features

- **Captures text, images, and files** — monitors the system clipboard and saves everything automatically
- **Search** — find past clipboard entries by content, file name, or source app
- **Grouped by day** — history view organized by date sections
- **Source app tracking** — see which app each entry was copied from
- **De-duplication** — skips consecutive identical copies
- **Image support** — stores copied images as PNGs with size limits
- **Configurable retention** — auto-purge entries older than N days (default 30)
- **Ignore apps** — exclude specific apps from being captured
- **Export** — export clipboard history as JSON or CSV
- **Menu bar app** — lives in the system tray, no dock icon
- **Global hotkey** — quick access via keyboard shortcut

## Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4)
- Xcode 15+ (for building from source)

## Installation

```bash
git clone https://github.com/julian0xff/Clippie.git
cd Clippie
xcodegen generate
xcodebuild -project Clippie.xcodeproj -scheme Clippie -destination 'platform=macOS,arch=arm64' build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/Clippie-*/Build/Products/Debug/Clippie.app`. Copy it to `/Applications` to install.

## Data Storage

| Data | Location |
|------|----------|
| Preferences | macOS UserDefaults |
| Clipboard history | `~/Library/Application Support/Clippie/clipboard.sqlite` |
| Saved images | `~/Library/Application Support/Clippie/Images/` |

## License

MIT
