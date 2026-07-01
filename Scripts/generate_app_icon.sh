#!/bin/bash
set -euo pipefail
# generate_app_icon.sh — convert AppIcon.svg to AppIcon.icns
# Uses qlmanage for SVG -> PNG, sips for resizing, iconutil for .icns

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SVG="${SCRIPT_DIR}/../Sources/ClipRail/Resources/AppIcon.svg"
OUTPUT_ICNS="${SCRIPT_DIR}/../Sources/ClipRail/Resources/AppIcon.icns"
WORK_DIR="$(mktemp -d)"
ICONSET_DIR="${WORK_DIR}/AppIcon.iconset"

echo "==> Generating AppIcon.icns from AppIcon.svg"

if [ ! -f "$SOURCE_SVG" ]; then
    echo "ERROR: AppIcon.svg not found at $SOURCE_SVG"
    rm -rf "$WORK_DIR"
    exit 1
fi

mkdir -p "$ICONSET_DIR"

# Generate thumbnail from SVG at 1024x1024
qlmanage -t -s 1024 -o "$WORK_DIR" "$SOURCE_SVG" &>/dev/null
SVG_PNG=$(ls "$WORK_DIR"/*.png | head -1)

if [ ! -f "$SVG_PNG" ]; then
    echo "ERROR: qlmanage failed to generate thumbnail"
    rm -rf "$WORK_DIR"
    exit 1
fi

# macOS standard icon sizes
sips -z 16 16 "$SVG_PNG" --out "${ICONSET_DIR}/icon_16x16.png" &>/dev/null
sips -z 32 32 "$SVG_PNG" --out "${ICONSET_DIR}/icon_16x16@2x.png" &>/dev/null
sips -z 32 32 "$SVG_PNG" --out "${ICONSET_DIR}/icon_32x32.png" &>/dev/null
sips -z 64 64 "$SVG_PNG" --out "${ICONSET_DIR}/icon_32x32@2x.png" &>/dev/null
sips -z 128 128 "$SVG_PNG" --out "${ICONSET_DIR}/icon_128x128.png" &>/dev/null
sips -z 256 256 "$SVG_PNG" --out "${ICONSET_DIR}/icon_128x128@2x.png" &>/dev/null
sips -z 256 256 "$SVG_PNG" --out "${ICONSET_DIR}/icon_256x256.png" &>/dev/null
sips -z 512 512 "$SVG_PNG" --out "${ICONSET_DIR}/icon_256x256@2x.png" &>/dev/null
sips -z 512 512 "$SVG_PNG" --out "${ICONSET_DIR}/icon_512x512.png" &>/dev/null
sips -z 1024 1024 "$SVG_PNG" --out "${ICONSET_DIR}/icon_512x512@2x.png" &>/dev/null

# Generate .icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

rm -rf "$WORK_DIR"

if [ -f "$OUTPUT_ICNS" ]; then
    echo "==> AppIcon.icns generated successfully at $OUTPUT_ICNS"
else
    echo "ERROR: Failed to generate AppIcon.icns"
    exit 1
fi
