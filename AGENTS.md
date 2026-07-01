# AGENTS.md — ClipRail

ClipRail is macOS 14+ menu bar clipboard history.

## Hard Boundaries

- **NO network** — no URLSession, no sockets, no Bonjour, no cloud
- **NO hotkeys** — no global keyboard shortcuts
- **NO auto-paste** — clips are re-copied only; user pastes manually
- **NO images/files/rich media** — plain text only
- **NO microphone/camera/accessibility** — no permissions beyond basic pasteboard
- **NO launch-at-login** — no ServiceManagement, no login items
- **NO nested popovers** — single MenuBarExtra popover, no sub-popovers
- **NO cloud/sync** — local UserDefaults only
- **NO notarization** — ad-hoc codesign only

## Shipping Gates

1. `swift test` — all tests pass
2. `./Scripts/package_app.sh release` — produces valid .app with:
   - PkgInfo = `APPL????`
   - Info.plist with correct bundle ID, LSUIElement=true, CFBundleIconFile=AppIcon
   - AppIcon.icns present
   - Ad-hoc signed
   - `codesign --verify` passes
3. `./Scripts/install_app.sh` — installs to /Applications and launches
4. Clipboard roundtrip: `pbcopy` 3 strings → verify UI → tap re-copy → verify pasteboard → clear
5. No fresh crash
6. USERGUIDE.md present
7. .gitignore excludes generated artifacts

## Delegation

- **Deep-builder** implements Slice 1, runs swift test + swift build + package_app.sh
- **Eldio captain** does install, launch, clipboard smoke tests, and shipping gate pass/fail

## Implementation Notes

- SwiftPM executable target, macOS 14 minimum
- `@main` SwiftUI App, NOT named main.swift
- `@preconcurrency import AppKit` for pasteboard access
- HistoryStore accepts injected UserDefaults for test isolation
- Tests avoid real global pasteboard
- No URLSession/network imports or entitlements
