# ClipRail User Guide

**Version:** 1.0.0 (Slice 1)
**Platform:** macOS 14+

## Overview

ClipRail is a lightweight menu bar clipboard history app for macOS. 
It keeps your last 10 text clips accessible from the menu bar. 
Tap any clip to re-copy it to your pasteboard.

**Slice 1 is local-only, text-only.** No network, no images, no hotkeys, no auto-paste.

## Getting Started

### Launch
ClipRail runs as a menu bar app. You'll see a clipboard icon (📋) in your menu bar.
Click the icon to open the history popover.

### Capturing clips
ClipRail watches your system clipboard every second. Any text you copy (⌘C) will 
appear in the ClipRail popover, newest first. Only plain text is captured — 
images, files, and rich text are ignored.

### Re-copying a clip
Click any clip in the history list to copy its text back to your pasteboard.
Paste (⌘V) in any app to use it.

### Clearing history
Click the **Clear** button in the popover header to remove all clips.

### Settings
Access Settings via the system menu bar icon's context menu or the app menu 
(ClipRail → Settings). The About tab shows version info.

## Limits

- **10 clips maximum.** Older clips are removed when new ones arrive.
- **Text only.** No images, files, or rich media in this version.
- **No auto-paste.** Clips are only re-copied; you must paste manually.
- **Local only.** No network access, no cloud sync.

## Troubleshooting

**ClipRail doesn't appear in the menu bar:**
- Check if you have too many menu bar items. macOS may hide some.
- Try launching from `/Applications/ClipRail.app`.

**Clips aren't being captured:**
- Only text is captured. Check that you're copying text, not images or formatted content.
- Copy something, wait 1 second, then open ClipRail.

**ClipRail is using high CPU:**
- This should not happen. If it does, quit and relaunch. Report if persistent.

## Privacy

ClipRail stores clipboard history locally in UserDefaults. 
No data leaves your machine. No analytics, no tracking, no network calls.
