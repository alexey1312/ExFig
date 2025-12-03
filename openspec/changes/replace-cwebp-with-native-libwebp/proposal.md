# Change: Replace external cwebp binary with native Swift libwebp

## Why

Current WebP conversion requires users to install the external `cwebp` binary (via Homebrew, apt, etc.). This creates:

1. **Installation friction** - Users must install cwebp separately before using WebP export
2. **CI/CD complexity** - Build pipelines need additional setup steps
3. **Version inconsistency** - Different cwebp versions across environments
4. **Platform issues** - Binary discovery logic varies by OS

The `the-swift-collective/libwebp` package provides libwebp 1.4.x compiled directly via SPM, including `libpng` as a
transitive dependency. This enables native PNG-to-WebP conversion without external tools.

## What Changes

- **ADDED**: SPM dependency on `the-swift-collective/libwebp` (v1.4.1+)
- **ADDED**: `NativeWebpEncoder` class using libwebp C API directly
- **ADDED**: `PngDecoder` utility for PNG-to-RGBA conversion via libpng
- **MODIFIED**: `WebpConverter` to use native encoding (no external binary)
- **REMOVED**: External `cwebp` binary discovery and Process-based conversion
- **REMOVED**: `CWEBP_PATH` environment variable support (no longer needed)

## Impact

- Affected specs: webp-conversion (new capability spec)
- Affected code:
  - `Package.swift` (new dependency)
  - `Sources/ExFig/Output/WebpConverter.swift` (rewrite)
  - `Sources/ExFig/Output/PngDecoder.swift` (new)
  - `Sources/ExFig/Output/NativeWebpEncoder.swift` (new)
  - `Tests/ExFigTests/WebpConverterTests.swift` (new)
  - `CLAUDE.md` (remove cwebp references)
  - `CONFIG.md` (update webpOptions documentation)
  - `.github/docs/android/images.md`
  - `.github/docs/flutter/images.md`

## Benefits

| Before (cwebp binary)     | After (native libwebp)     |
| ------------------------- | -------------------------- |
| Requires brew/apt install | Zero external dependencies |
| Binary discovery logic    | Direct SPM import          |
| Process spawning overhead | Native function calls      |
| Platform-specific paths   | Cross-platform Swift       |
| Version varies by system  | Pinned via Package.swift   |

## Migration

**Breaking change**: `CWEBP_PATH` environment variable will be ignored.

Users who previously set `CWEBP_PATH` can simply remove it - no action required. The WebP encoding will work
automatically after upgrading ExFig.

## Risk Assessment

- **Low risk**: libwebp is the same underlying library that cwebp uses
- **Tested**: the-swift-collective/libwebp has CI for macOS, Linux, Windows
- **Fallback**: If issues arise, can temporarily restore cwebp support behind feature flag
