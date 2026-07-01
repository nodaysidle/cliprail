#!/bin/bash
set -euo pipefail
# package_app.sh — build ClipRail .app bundle (release)
# Usage: ./Scripts/package_app.sh [release|debug]
# Default: release

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="${1:-release}"
APP_VERSION="1.2.0"
APP_BUILD="3"

ICONSET_DIR="$PROJECT_DIR/Sources/ClipRail/Resources"
ICON_SVG="$ICONSET_DIR/AppIcon.svg"
ICON_ICNS="$ICONSET_DIR/AppIcon.icns"

echo "========================================="
echo " ClipRail Package Script"
echo " Configuration: $CONFIG"
echo "========================================="

# --- Generate AppIcon.icns if missing ---
if [ ! -f "$ICON_ICNS" ]; then
    echo "==> AppIcon.icns not found, generating..."
    if [ -f "$SCRIPT_DIR/generate_app_icon.sh" ]; then
        bash "$SCRIPT_DIR/generate_app_icon.sh"
    else
        echo "WARNING: generate_app_icon.sh not found, building without icon"
    fi
fi

# --- Build ---
BUILD_FLAGS="-c $CONFIG"
if [ "$CONFIG" = "release" ]; then
    BUILD_FLAGS="$BUILD_FLAGS --disable-sandbox"
fi

echo "==> Building ClipRail..."
cd "$PROJECT_DIR"
swift build $BUILD_FLAGS 2>&1

# Locate the built binary
if [ "$CONFIG" = "release" ]; then
    BINARY_PATH="$PROJECT_DIR/.build/arm64-apple-macosx/release/ClipRail"
    # Fallback for different architectures
    if [ ! -f "$BINARY_PATH" ]; then
        BINARY_PATH="$PROJECT_DIR/.build/release/ClipRail"
    fi
else
    BINARY_PATH="$PROJECT_DIR/.build/arm64-apple-macosx/debug/ClipRail"
    if [ ! -f "$BINARY_PATH" ]; then
        BINARY_PATH="$PROJECT_DIR/.build/debug/ClipRail"
    fi
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Built binary not found. Searching..."
    find "$PROJECT_DIR/.build" -name "ClipRail" -type f 2>/dev/null
    exit 1
fi

echo "==> Binary: $BINARY_PATH"

# --- Create .app bundle ---
APP_BUNDLE="$PROJECT_DIR/build/ClipRail.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/ClipRail"
chmod +x "$APP_BUNDLE/Contents/MacOS/ClipRail"

# Write PkgInfo — exactly "APPL????"
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ClipRail</string>
    <key>CFBundleIdentifier</key>
    <string>com.nodaysidle.cliprail</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ClipRail</string>
    <key>CFBundleDisplayName</key>
    <string>ClipRail</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Copy AppIcon.icns if it exists
if [ -f "$ICON_ICNS" ]; then
    cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "==> AppIcon.icns copied"
else
    echo "WARNING: No AppIcon.icns found; app will use default icon"
fi

# Strip extended attributes before signing so local bundles verify cleanly.
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

# --- Ad-hoc codesign ---
echo "==> Ad-hoc codesigning..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>&1

# --- Verify ---
echo "==> Verifying..."
echo "PkgInfo: $(xxd "$APP_BUNDLE/Contents/PkgInfo" | head -1)"
echo "Bundle ID: $(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_BUNDLE/Contents/Info.plist")"
echo "LSUIElement: $(/usr/libexec/PlistBuddy -c 'Print LSUIElement' "$APP_BUNDLE/Contents/Info.plist")"

echo ""
echo "==> Codesign verify:"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" 2>&1
echo ""

echo "========================================="
echo " ClipRail.app packaged at:"
echo " $APP_BUNDLE"
echo "========================================="
