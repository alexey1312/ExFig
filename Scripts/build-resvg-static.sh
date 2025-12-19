#!/bin/bash
# Build resvg as a static library for macOS (universal binary)
#
# Usage:
#   ./Scripts/build-resvg-static.sh           # Build current version (0.45.1)
#   ./Scripts/build-resvg-static.sh 0.46.0    # Build specific version
#
# Requirements: Rust toolchain (rustup target add aarch64-apple-darwin x86_64-apple-darwin)
#
# After building, commit the new library:
#   git add Libraries/macos/libresvg.a
#   git commit -m "chore(deps): update resvg to X.Y.Z"

set -euo pipefail

RESVG_VERSION="${1:-0.45.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.resvg-build"
OUTPUT_DIR="$PROJECT_ROOT/Libraries/macos"

echo "=== Building resvg $RESVG_VERSION static library ==="

# Ensure Rust targets are installed
rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true

# Clean and clone resvg
rm -rf "$BUILD_DIR"
echo "Cloning resvg v$RESVG_VERSION..."
mkdir -p "$BUILD_DIR"
git clone --depth 1 --branch "v$RESVG_VERSION" https://github.com/RazrFalcon/resvg.git "$BUILD_DIR/resvg"

cd "$BUILD_DIR/resvg/crates/c-api"

# Build for arm64
echo "Building for arm64..."
cargo build --release --target aarch64-apple-darwin

# Build for x86_64
echo "Building for x86_64..."
cargo build --release --target x86_64-apple-darwin

# Create universal binary
echo "Creating universal static library..."
mkdir -p "$OUTPUT_DIR"

lipo -create \
    "$BUILD_DIR/resvg/target/aarch64-apple-darwin/release/libresvg.a" \
    "$BUILD_DIR/resvg/target/x86_64-apple-darwin/release/libresvg.a" \
    -output "$OUTPUT_DIR/libresvg.a"

# Copy header file
cp "$BUILD_DIR/resvg/crates/c-api/resvg.h" "$PROJECT_ROOT/Sources/CResvg/include/resvg.h"

# Clean up build directory
rm -rf "$BUILD_DIR"

echo "=== Done ==="
echo "Library: $OUTPUT_DIR/libresvg.a"
file "$OUTPUT_DIR/libresvg.a"
echo ""
echo "Header updated: Sources/CResvg/include/resvg.h"
grep "RESVG_VERSION" "$PROJECT_ROOT/Sources/CResvg/include/resvg.h" | head -1
