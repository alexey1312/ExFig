#!/bin/bash
# =============================================================================
# build-app-release.sh - Build ExFig Studio for Release
# =============================================================================
# This script builds ExFig Studio as a signed and notarized macOS app.
#
# Prerequisites:
#   - Xcode 16+ installed
#   - Apple Developer account with Developer ID certificate
#   - mise installed (./bin/mise)
#
# Environment variables:
#   APPLE_TEAM_ID          - Apple Developer Team ID (required for signing)
#   APPLE_IDENTITY         - Code signing identity (default: "Developer ID Application")
#   NOTARIZATION_KEYCHAIN_PROFILE - Keychain profile for notarization (optional)
#   VERSION                - App version (default: extracted from Project.swift)
#   BUILD_NUMBER           - Build number (default: timestamp)
#   OUTPUT_DIR             - Output directory (default: ./dist)
#   SKIP_NOTARIZATION      - Set to 1 to skip notarization
#
# Usage:
#   ./Scripts/build-app-release.sh                    # Build with defaults
#   VERSION=1.2.0 ./Scripts/build-app-release.sh     # Build specific version
#   SKIP_NOTARIZATION=1 ./Scripts/build-app-release.sh  # Skip notarization
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/dist}"
APP_NAME="ExFig Studio"
BUNDLE_ID="io.exfig.studio"

# Version handling
VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"

# Signing
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_IDENTITY="${APPLE_IDENTITY:-Developer ID Application}"
NOTARIZATION_KEYCHAIN_PROFILE="${NOTARIZATION_KEYCHAIN_PROFILE:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"

# Derived paths
WORKSPACE="$PROJECT_ROOT/ExFig.xcworkspace"
ARCHIVE_PATH="$OUTPUT_DIR/ExFigStudio.xcarchive"
APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
DMG_PATH="$OUTPUT_DIR/ExFigStudio-${VERSION:-dev}.dmg"

# =============================================================================
# Functions
# =============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Install Xcode from the App Store."
        exit 1
    fi

    # Check mise and tuist
    if [[ ! -x "$PROJECT_ROOT/bin/mise" ]]; then
        log_error "./bin/mise not found. Run from project root."
        exit 1
    fi

    # Check tuist
    if ! "$PROJECT_ROOT/bin/mise" exec -- tuist version &> /dev/null; then
        log_error "tuist not available. Run: ./bin/mise install"
        exit 1
    fi

    # Check create-dmg (optional, for DMG creation)
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg not found. DMG will be created with hdiutil instead."
        log_warning "For better DMGs, install: brew install create-dmg"
    fi

    log_success "Prerequisites check passed"
}

extract_version() {
    if [[ -n "$VERSION" ]]; then
        log_info "Using provided version: $VERSION"
        return
    fi

    # Extract version from Project.swift
    VERSION=$(grep -o '"CFBundleShortVersionString": "[^"]*"' "$PROJECT_ROOT/Projects/ExFigStudio/Project.swift" | head -1 | sed 's/.*: "\([^"]*\)"/\1/')

    if [[ -z "$VERSION" ]]; then
        VERSION="1.0.0"
        log_warning "Could not extract version, using default: $VERSION"
    else
        log_info "Extracted version from Project.swift: $VERSION"
    fi
}

generate_project() {
    log_info "Generating Xcode project with Tuist..."
    cd "$PROJECT_ROOT"
    "$PROJECT_ROOT/bin/mise" exec -- tuist generate --no-open
    log_success "Project generated"
}

update_version() {
    log_info "Setting version to $VERSION (build $BUILD_NUMBER)..."

    # Update Info.plist via build settings
    # This is handled by xcodebuild with MARKETING_VERSION and CURRENT_PROJECT_VERSION
    log_success "Version will be set during build"
}

build_archive() {
    log_info "Building release archive..."

    mkdir -p "$OUTPUT_DIR"

    local signing_args=""
    if [[ -n "$APPLE_TEAM_ID" ]]; then
        signing_args="CODE_SIGN_IDENTITY=\"$APPLE_IDENTITY\" DEVELOPMENT_TEAM=$APPLE_TEAM_ID CODE_SIGN_STYLE=Manual"
    else
        log_warning "No APPLE_TEAM_ID set, building without code signing"
        signing_args="CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO"
    fi

    xcodebuild archive \
        -workspace "$WORKSPACE" \
        -scheme "ExFigStudio" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
        $signing_args \
        -quiet

    log_success "Archive created at: $ARCHIVE_PATH"
}

export_app() {
    log_info "Exporting app from archive..."

    # Create export options plist
    local export_options="$OUTPUT_DIR/ExportOptions.plist"

    if [[ -n "$APPLE_TEAM_ID" ]]; then
        cat > "$export_options" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>${APPLE_IDENTITY}</string>
</dict>
</plist>
EOF
    else
        cat > "$export_options" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
</dict>
</plist>
EOF
    fi

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$OUTPUT_DIR" \
        -exportOptionsPlist "$export_options" \
        -quiet

    # Rename app if needed
    if [[ -d "$OUTPUT_DIR/ExFigStudio.app" ]]; then
        mv "$OUTPUT_DIR/ExFigStudio.app" "$APP_PATH"
    fi

    rm -f "$export_options"
    log_success "App exported to: $APP_PATH"
}

notarize_app() {
    if [[ "$SKIP_NOTARIZATION" == "1" ]]; then
        log_warning "Skipping notarization (SKIP_NOTARIZATION=1)"
        return
    fi

    if [[ -z "$NOTARIZATION_KEYCHAIN_PROFILE" ]]; then
        log_warning "Skipping notarization (no NOTARIZATION_KEYCHAIN_PROFILE set)"
        log_info "To set up notarization:"
        log_info "  xcrun notarytool store-credentials \"ExFigStudio\" \\"
        log_info "    --apple-id YOUR_APPLE_ID \\"
        log_info "    --team-id YOUR_TEAM_ID \\"
        log_info "    --password YOUR_APP_SPECIFIC_PASSWORD"
        return
    fi

    log_info "Notarizing app..."

    # Create zip for notarization
    local zip_path="$OUTPUT_DIR/ExFigStudio-notarization.zip"
    ditto -c -k --keepParent "$APP_PATH" "$zip_path"

    # Submit for notarization
    xcrun notarytool submit "$zip_path" \
        --keychain-profile "$NOTARIZATION_KEYCHAIN_PROFILE" \
        --wait

    # Staple the notarization ticket
    xcrun stapler staple "$APP_PATH"

    rm -f "$zip_path"
    log_success "App notarized and stapled"
}

create_dmg() {
    log_info "Creating DMG..."

    DMG_PATH="$OUTPUT_DIR/ExFigStudio-${VERSION}.dmg"

    # Remove existing DMG
    rm -f "$DMG_PATH"

    if command -v create-dmg &> /dev/null; then
        # Use create-dmg for a nice DMG with custom layout
        create-dmg \
            --volname "ExFig Studio" \
            --volicon "$PROJECT_ROOT/Projects/ExFigStudio/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "ExFig Studio.app" 150 185 \
            --hide-extension "ExFig Studio.app" \
            --app-drop-link 450 185 \
            --no-internet-enable \
            "$DMG_PATH" \
            "$APP_PATH" \
            2>/dev/null || {
                log_warning "create-dmg failed, falling back to hdiutil"
                create_dmg_simple
            }
    else
        create_dmg_simple
    fi

    log_success "DMG created at: $DMG_PATH"
}

create_dmg_simple() {
    # Simple DMG creation with hdiutil
    local staging_dir="$OUTPUT_DIR/dmg-staging"
    rm -rf "$staging_dir"
    mkdir -p "$staging_dir"

    cp -R "$APP_PATH" "$staging_dir/"
    ln -s /Applications "$staging_dir/Applications"

    hdiutil create \
        -volname "ExFig Studio" \
        -srcfolder "$staging_dir" \
        -ov \
        -format UDZO \
        "$DMG_PATH"

    rm -rf "$staging_dir"
}

calculate_checksums() {
    log_info "Calculating checksums..."

    if [[ -f "$DMG_PATH" ]]; then
        local sha256=$(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)
        echo "$sha256  $(basename "$DMG_PATH")" > "$OUTPUT_DIR/checksums.txt"
        log_success "SHA256: $sha256"
    fi
}

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Build complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Version:    $VERSION (build $BUILD_NUMBER)"
    echo "Output:     $OUTPUT_DIR"
    echo ""
    echo "Artifacts:"
    [[ -d "$APP_PATH" ]] && echo "  • $APP_PATH"
    [[ -f "$DMG_PATH" ]] && echo "  • $DMG_PATH"
    [[ -f "$OUTPUT_DIR/checksums.txt" ]] && echo "  • $OUTPUT_DIR/checksums.txt"
    echo ""

    if [[ -z "$APPLE_TEAM_ID" ]]; then
        log_warning "App is NOT signed. Set APPLE_TEAM_ID for distribution."
    fi
    if [[ "$SKIP_NOTARIZATION" == "1" || -z "$NOTARIZATION_KEYCHAIN_PROFILE" ]]; then
        log_warning "App is NOT notarized. Users may see Gatekeeper warnings."
    fi
}

cleanup() {
    log_info "Cleaning up..."
    rm -rf "$ARCHIVE_PATH"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ExFig Studio Release Build"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_prerequisites
    extract_version
    generate_project
    update_version
    build_archive
    export_app
    notarize_app
    create_dmg
    calculate_checksums
    cleanup
    print_summary
}

main "$@"
