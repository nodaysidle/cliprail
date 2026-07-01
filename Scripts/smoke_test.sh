#!/bin/bash
set -euo pipefail
# smoke_test.sh — automated local checks for ClipRail
# By default: swift test + package only.
# Set INSTALL=1 to also install to /Applications and run clipboard tests.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DO_INSTALL="${INSTALL:-0}"
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAILED=1; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

cleanup() {
    # Kill any test-launched ClipRail
    pkill -x ClipRail 2>/dev/null || true
}
trap cleanup EXIT

echo "========================================="
echo " ClipRail Smoke Test"
echo "========================================="
echo ""

# --- 1. Swift Test ---
echo "--- 1. Swift Test ---"
cd "$PROJECT_DIR"
if swift test 2>&1; then
    pass "swift test passed"
else
    fail "swift test failed"
    # Continue with other checks even if tests fail
fi
echo ""

# --- 2. Swift Build Release ---
echo "--- 2. Swift Build (release) ---"
if swift build -c release 2>&1; then
    pass "swift build -c release passed"
else
    fail "swift build -c release failed"
fi
echo ""

# --- 3. Package ---
echo "--- 3. Package ---"
if bash "$SCRIPT_DIR/package_app.sh" release 2>&1; then
    pass "package_app.sh passed"
else
    fail "package_app.sh failed"
fi
echo ""

# --- 4. Verify .app structure ---
APP_BUNDLE="$PROJECT_DIR/build/ClipRail.app"
echo "--- 4. Verify .app structure ---"
if [ -d "$APP_BUNDLE" ]; then
    # PkgInfo
    PKGINFO_CONTENT=$(cat "$APP_BUNDLE/Contents/PkgInfo" 2>/dev/null || echo "")
    if [ "$PKGINFO_CONTENT" = "APPL????" ]; then
        pass "PkgInfo matches APPL????"
    else
        fail "PkgInfo mismatch: got '$PKGINFO_CONTENT'"
    fi

    # Info.plist exists
    if [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
        pass "Info.plist exists"
    else
        fail "Info.plist missing"
    fi

    # CFBundleIdentifier
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "")
    if [ "$BUNDLE_ID" = "com.nodaysidle.cliprail" ]; then
        pass "Bundle ID: $BUNDLE_ID"
    else
        fail "Bundle ID mismatch: got '$BUNDLE_ID'"
    fi

    # LSUIElement
    LSUI=$(/usr/libexec/PlistBuddy -c 'Print LSUIElement' "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "")
    if [ "$LSUI" = "true" ]; then
        pass "LSUIElement=true"
    else
        fail "LSUIElement mismatch: got '$LSUI'"
    fi

    # CFBundleIconFile
    ICONFILE=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIconFile' "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "")
    if [ "$ICONFILE" = "AppIcon" ]; then
        pass "CFBundleIconFile=AppIcon"
    else
        fail "CFBundleIconFile mismatch: got '$ICONFILE'"
    fi

    # Binary exists
    if [ -x "$APP_BUNDLE/Contents/MacOS/ClipRail" ]; then
        pass "Executable exists and is executable"
    else
        fail "Executable missing or not executable"
    fi

    # Codesign verify
    if codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" 2>&1; then
        pass "codesign verify passed"
    else
        fail "codesign verify failed"
    fi

    # AppIcon.icns
    if [ -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
        pass "AppIcon.icns present"
    else
        info "AppIcon.icns not found (non-fatal)"
    fi
else
    fail ".app bundle not found at $APP_BUNDLE"
fi
echo ""

# --- 5. Clipboard roundtrip test (if INSTALL=1) ---
if [ "$DO_INSTALL" = "1" ]; then
    echo "--- 5. Install + Clipboard Test ---"
    bash "$SCRIPT_DIR/install_app.sh" 2>&1 || {
        fail "install_app.sh failed"
    }

    if pgrep -x ClipRail > /dev/null; then
        pass "ClipRail process running"
    else
        fail "ClipRail process not found after install"
    fi

    # Test pbcopy integration: copy 3 strings, wait for polling
    echo "Testing pbcopy integration..."
    pbcopy < <(echo "Smoke test item 1")
    sleep 2
    pbcopy < <(echo "Smoke test item 2")
    sleep 2
    pbcopy < <(echo "Smoke test item 3")
    sleep 2

    # Verify pasteboard has latest
    PB_CONTENT=$(pbpaste)
    if [ "$PB_CONTENT" = "Smoke test item 3" ]; then
        pass "pbcopy/pbpaste roundtrip: latest clip is 'Smoke test item 3'"
    else
        fail "pbcopy/pbpaste roundtrip: expected 'Smoke test item 3', got '$PB_CONTENT'"
    fi

    # Crash check: is ClipRail still running?
    if pgrep -x ClipRail > /dev/null; then
        pass "ClipRail survived clipboard operations"
    else
        fail "ClipRail crashed during clipboard test"
    fi
else
    info "Skipping install+clipboard tests (set INSTALL=1 to run)"
fi
echo ""

# --- Summary ---
echo "========================================="
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All smoke tests passed.${NC}"
else
    echo -e "${RED}Some tests FAILED.${NC}"
fi
echo "========================================="

exit $FAILED
