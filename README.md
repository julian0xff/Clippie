# Clippy

Clipboard history manager for macOS. Automatically captures everything you copy — text, images, and files — and lets you search, browse, and re-paste from your history.

Built on top of [clipcopy](https://github.com/julian0xff/clipcopy) — the tiny cross-platform clipboard CLI that powers Clippy's text clipboard operations. You can install the CLI from **Settings > About > CLI Tools** to use it in your own scripts and workflows.

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
git clone https://github.com/julian0xff/Clippy.git
cd Clippy
xcodegen generate
xcodebuild -project Clippy.xcodeproj -scheme Clippy -destination 'platform=macOS,arch=arm64' build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/Clippy-*/Build/Products/Debug/Clippy.app`. Copy it to `/Applications` to install.

## Data Storage

| Data | Location |
|------|----------|
| Preferences | macOS UserDefaults |
| Clipboard history | `~/Library/Application Support/Clippy/clipboard.sqlite` |
| Saved images | `~/Library/Application Support/Clippy/Images/` |

## License

MIT
