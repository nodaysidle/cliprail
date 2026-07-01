# Changelog

All notable changes to ClipRail are documented here.

## [1.2.0] — 2026-07-01

### Added

- Search field filters pinned and unpinned clips live (case-insensitive contains)
- Per-row delete button for any clip
- Pause / Resume capture toggle in popover header
- ClipboardWatcher guard so programmatic pasteboard writes during smoke tests are not captured as user clips

### Changed

- About screen and bundle version aligned to 1.2.0 (build 3)
- USERGUIDE updated for Slice 3 workflows

### Tests

- 46 unit tests (up from 28); Slice 1/2 regression coverage retained

## [1.1.0] — 2026-07-01

### Added

- Pin up to 3 clips; pinned rows survive **Clear**
- 60-second dedupe window (identical text bumps existing row)
- Relative timestamps refresh when popover opens

## [1.0.0] — 2026-07-01

### Added

- Menu bar clipboard history (10 text clips)
- Click-to-re-copy, **Clear** history
- Local UserDefaults persistence across relaunch
- Dark UI with Volt accent (#C8FF00)
- SwiftPM macOS 14+ executable, ad-hoc signed packaging scripts