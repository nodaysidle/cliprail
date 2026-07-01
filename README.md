# ClipRail

**macOS menu bar clipboard history — local only, text only.**

Version 1.0.0 (Slice 1) · macOS 14+

## Features (Slice 1)

- 📋 Menu bar clipboard history (last 10 text clips)
- 🖱️ Click to re-copy any clip
- 🧹 Clear history
- 💾 Persists across relaunch
- 🌙 Dark UI with Volt accent (#C8FF00)
- 📜 Scrollable popover
- 🔒 Local only — no network, no sync

## Quick Start

```bash
# Build and test
swift test
swift build -c release

# Package as .app
./Scripts/package_app.sh release

# Install to /Applications (optional)
./Scripts/install_app.sh
```

## Architecture

```
Sources/ClipRail/
├── ClipRailApp.swift        # @main App entry + AppDelegate
├── ContentView.swift        # Menu bar popover UI
├── ClipboardWatcher.swift   # Timer-based pasteboard polling
├── ClipboardItem.swift      # Data model
├── HistoryStore.swift       # History management + persistence
├── SettingsScene.swift      # Settings/About window
├── Utilities.swift          # Constants + helpers
└── Resources/
    └── AppIcon.svg          # Source icon
```

## Tests

```bash
swift test
```

Tests cover:
- ClipboardItem sanitization, preview, Codable roundtrip
- HistoryStore max count, dedup, clear, persistence roundtrip, order

## License

Proprietary. All rights reserved.
