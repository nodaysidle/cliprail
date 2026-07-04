# ClipRail

**A local, text-only clipboard history for the macOS menu bar.**

ClipRail keeps the plain-text snippets you actually reuse one click away. It is intentionally small: recent clips, pinned favorites, search, delete, pause, and re-copy — with no network access, no account, no hotkeys, and no auto-paste surprises.

**Version 1.2.0** · macOS 14+ · Swift 6 · SwiftUI

---

## What You Get

| Area | Capability |
|------|------------|
| **History** | Last 10 unpinned plain-text clips, newest first |
| **Pinned clips** | Up to 3 pinned clips that survive **Clear** |
| **Search** | Live case-insensitive filter in the popover header |
| **Delete** | Remove a single pinned or unpinned row immediately |
| **Pause** | Stop capture temporarily; no backfill on resume |
| **Dedupe** | Re-copying the same text within 60 seconds bumps the row |
| **Timestamps** | Relative ages refresh when the popover opens |
| **Re-copy** | Tap a row to put it back on the pasteboard; you paste manually |
| **Privacy** | Local UserDefaults only; no network, sync, telemetry, or account |

---

## Privacy Boundary

ClipRail is deliberately boring about data.

- Plain text only.
- Local storage only.
- No URLSession, sockets, telemetry, analytics, or sync.
- No microphone, camera, Accessibility, or global hotkey permissions.
- No auto-paste. ClipRail only re-copies; you decide where to paste.

If you need image history, cloud sync, universal clipboard features, or automation hooks, this product is intentionally not doing that.

---

## Quick Start

### Install from release

1. Download `ClipRail.app.zip` from [Releases](https://github.com/nodaysidle/cliprail/releases).
2. Unzip and move `ClipRail.app` to `/Applications`.
3. First launch: right-click → **Open** if macOS warns about the ad-hoc signed build.

### Build from source

```bash
git clone https://github.com/nodaysidle/cliprail.git
cd cliprail

swift test
./Scripts/package_app.sh release
./Scripts/install_app.sh
```

Full operator guide: [USERGUIDE.md](USERGUIDE.md)

---

## Daily Use

1. Launch ClipRail and use the menu-bar clipboard icon.
2. Copy plain text with `⌘C` in any app.
3. Open ClipRail to search, pin, delete, pause, clear, or re-copy clips.
4. Click a row to re-copy it, then paste manually with `⌘V`.

---

## Build and Verify

```bash
swift test
swift build
./Scripts/package_app.sh release
./Scripts/smoke_test.sh
```

Release builds are ad-hoc signed for local use. They are not notarized.

---

## Repository Map

| Path | Purpose |
|------|---------|
| `Sources/ClipRail/` | Swift menu-bar app source |
| `Tests/ClipRailTests/` | Store and model tests |
| `Scripts/` | Package, install, smoke, and icon scripts |
| `USERGUIDE.md` | End-user operation guide |
| `CHANGELOG.md` | Release-facing changes |
| `docs/internal/` | Agent boundaries and shipping gates retained for maintainers |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Proprietary — NODAYSIDLE.
