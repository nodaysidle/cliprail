# ClipRail

**macOS menu bar clipboard history — local, text-only, no account.**

ClipRail keeps your last plain-text copies one click away in the menu bar. Pin important clips, search history, delete single rows, or pause capture when you need a break. Everything stays on your Mac.

**Version 1.2.0** · macOS 14+ · Swift 6 · SwiftUI

---

## Features

| Area | What you get |
|------|----------------|
| **History** | Last 10 unpinned text clips, newest first |
| **Pin** | Up to 3 pinned clips that survive **Clear** |
| **Search** | Live filter in the popover header (case-insensitive) |
| **Delete** | Per-row trash for pinned or unpinned clips |
| **Pause** | Stop capture temporarily; no backfill on resume |
| **Dedupe** | Same text within 60s bumps the row instead of duplicating |
| **Timestamps** | Relative ages refresh when you open the popover |
| **Re-copy** | Tap a row to copy back to the pasteboard — you paste manually |
| **Privacy** | UserDefaults only; no network, sync, or analytics |

### Intentionally not included

- No images, files, or rich text
- No global hotkeys or auto-paste
- No cloud sync or iCloud
- No launch-at-login (yet)

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- Xcode 16+ or Swift 6 toolchain (to build from source)

---

## Install

### Option A — GitHub Release (recommended)

1. Download **ClipRail.app.zip** from [Releases](https://github.com/nodaysidle/cliprail/releases).
2. Unzip and drag **ClipRail.app** to `/Applications`.
3. First launch: right-click → **Open** if Gatekeeper blocks the ad-hoc signed build (see [Signing](#signing) below).

### Option B — Build from source

```bash
git clone https://github.com/nodaysidle/cliprail.git
cd cliprail

swift test
./Scripts/package_app.sh release
./Scripts/install_app.sh   # optional: copies to /Applications and launches
```

---

## Usage

1. **Launch** — ClipRail lives in the menu bar (clipboard icon).
2. **Copy** — Any plain-text ⌘C appears in the list within ~1 second.
3. **Re-use** — Click a row to re-copy; paste with ⌘V in your target app.
4. **Search** — Type in **Search clips…** to filter live.
5. **Pin** — Star up to 3 clips to keep them above the list and after **Clear**.
6. **Delete** — Trash icon removes one clip immediately.
7. **Pause** — Header toggle stops new captures until you **Resume**.
8. **Clear** — Removes unpinned clips only.

Full operator guide: [USERGUIDE.md](USERGUIDE.md)

---

## Development

```bash
# Run tests (46 cases)
swift test

# Debug build
swift build

# Release .app bundle
./Scripts/package_app.sh release

# Smoke test (unit + package; set INSTALL=1 for clipboard UI checks)
./Scripts/smoke_test.sh
```

### Project layout

```
Sources/ClipRail/
├── ClipRailApp.swift        # @main entry, menu bar extra
├── ContentView.swift        # Popover UI (search, pause, list)
├── ClipboardWatcher.swift   # Pasteboard polling
├── ClipboardItem.swift      # Clip model
├── HistoryStore.swift       # History, pin, dedupe, persistence
├── SettingsScene.swift      # About / settings window
├── Utilities.swift          # Constants (version, limits, colors)
└── Resources/AppIcon.svg

Tests/ClipRailTests/         # Store + model tests
Scripts/                     # package, install, smoke, icon
```

Agent boundaries and shipping gates: [AGENTS.md](AGENTS.md)

---

## Signing

Release builds are **ad-hoc signed** (`codesign --sign -`). They are fine for local development and personal installs. They are **not notarized** — other Macs may show Gatekeeper warnings until you allow the app in System Settings → Privacy & Security.

---

## Privacy

- Clipboard history is stored in **local UserDefaults** (`com.nodaysidle.cliprail`).
- No URLSession, no sockets, no telemetry.
- No microphone, camera, or accessibility entitlements.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

Proprietary. All rights reserved. © NODAYSIDLE.