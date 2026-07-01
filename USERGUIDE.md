# ClipRail User Guide

**Version:** 1.2.0 (Slice 3)
**Platform:** macOS 14+

## Overview

ClipRail is a lightweight menu bar clipboard history app for macOS.
It keeps your recent plain-text clips accessible from the menu bar.
Tap any clip to re-copy it to your pasteboard.

ClipRail is local-only and text-only: no network, no images/files/rich media, no hotkeys, and no auto-paste.

## Getting Started

### Launch

ClipRail runs as a menu bar app. You'll see a clipboard icon in your menu bar.
Click the icon to open the history popover.

### Capturing clips

ClipRail watches your system clipboard every second. Any plain text you copy (⌘C) appears in the ClipRail popover, newest first. Images, files, and rich text are ignored.

### Re-copying a clip

Click a clip row in the history list to copy that clip back to your pasteboard.
Then paste manually (⌘V) in the target app.

### Searching clips

Use the **Search clips…** field in the popover header to filter the visible history live as you type.

- Search is case-insensitive.
- It matches text contained anywhere in the clip.
- Clearing the search field shows all clips again.
- Pinned clips still stay above unpinned clips when the list is filtered.

### Pinning clips

Click the **star** on any row to pin it. You can pin up to 3 clips.
Pinned clips stay at the top and survive **Clear**.

### Deleting one clip

Click the **trash** button on a row to delete that single clip.
This works for pinned and unpinned clips and saves immediately.

### Clearing history

Click **Clear** to remove unpinned clips only. Pinned clips are kept until you unpin or delete them.

### Pausing capture

Click **Pause** in the popover header to stop ClipRail from adding new clipboard entries.
The popover shows a paused state while capture is paused.

Click **Resume** to continue watching the clipboard.
Clipboard changes made while paused are not backfilled into history.

### Duplicate copies

If you copy the same text again within 60 seconds, ClipRail bumps the existing row to the top instead of adding a duplicate.

### Relative timestamps

Timestamps refresh when the popover opens, so clip ages are shown relative to the latest view.

### Settings

Access Settings via the system menu bar icon's context menu or the app menu (ClipRail → Settings). The About tab shows version info.

## Limits

- **10 unpinned clips maximum**, plus up to **3 pinned** clips.
- **60-second dedupe window** for identical text.
- **Text only.** No images, files, or rich media.
- **No auto-paste.** Clips are only re-copied; you must paste manually.
- **Local only.** No network access, no cloud sync.
- **Pause is session-only.** Relaunching ClipRail resumes normal capture.

## Troubleshooting

**ClipRail doesn't appear in the menu bar:**
- Check if you have too many menu bar items. macOS may hide some.
- Try launching from `/Applications/ClipRail.app`.

**Clips aren't being captured:**
- Only text is captured. Check that you're copying text, not images or formatted content.
- Make sure ClipRail is not paused. If the header says **Resume**, click it to resume capture.
- Copy something, wait at least 1 second, then open ClipRail.

**Search shows no results:**
- Clear the search field to show all clips.
- Search matches the saved plain-text clip contents, not the app you copied from.

**A pinned clip did not clear:**
- Expected. **Clear** removes unpinned clips only. Use the row trash button to delete one pinned clip.

**ClipRail is using high CPU:**
- This should not happen. If it does, quit and relaunch. Report if persistent.

## Privacy

ClipRail stores clipboard history locally in UserDefaults.
No data leaves your machine. No analytics, no tracking, no network calls.
