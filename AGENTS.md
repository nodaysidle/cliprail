# ClipRail — AGENTS.md

## Cursor Cloud specific instructions

ClipRail is a native macOS menu-bar app (`Package.swift` declares `.macOS(.v14)` only; source imports AppKit/SwiftUI). The Cursor Cloud VM is Linux with no Swift toolchain, so `swift build`, `swift test`, and running the app cannot execute here. Build, test, package, and run on macOS.

Verified macOS commands (from `README.md` and `Scripts/`):
- Build: `swift build` / `swift build -c release`
- Unit tests: `swift test`
- Smoke test: `Scripts/smoke_test.sh`
- Package app bundle: `Scripts/package_app.sh`

Do not attempt Swift builds on the Linux cloud VM.
