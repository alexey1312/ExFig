# Change: Add HEIC Output Format for iOS Images

## Why

iOS asset catalogs support HEIC format which provides ~40-50% smaller file sizes than PNG while maintaining transparency.
Currently ExFig only outputs PNG for iOS images; adding HEIC would reduce app bundle size significantly.

## What Changes

- Add `outputFormat: heic` option for iOS images configuration
- Add `heicOptions` with `encoding` (lossy/lossless) and `quality` (0-100, default 90)
- Create `NativeHeicEncoder` using Apple ImageIO (macOS only, lossy + lossless)
- Create `SvgToHeicConverter` following existing converter pattern (SVG source)
- Create `HeicConverter` for PNG source → HEIC conversion (like WebpConverter)
- Update XcodeImagesExporter to output `.heic` files with correct Contents.json
- **Breaking change**: Update WebP default quality from 80 to 90
- **macOS only** - Linux falls back to PNG with warning

## Impact

- Affected specs: `ios-export`
- Affected code:
  - `Sources/ExFig/Input/Params.swift` - add outputFormat, heicOptions
  - `Sources/ExFig/Output/NativeHeicEncoder.swift` - new file
  - `Sources/ExFig/Output/SvgToHeicConverter.swift` - new file (SVG source)
  - `Sources/ExFig/Output/HeicConverter.swift` - new file (PNG source)
  - `Sources/ExFig/Output/NativeWebpEncoder.swift` - change default quality 80 → 90
  - `Sources/ExFig/Subcommands/ExportImages.swift` - HEIC export paths
  - `Sources/ExFig/TerminalUI/ExFigWarning.swift` - add heicUnavailable warning
  - `Sources/XcodeExport/XcodeImagesExporter.swift` - HEIC support
  - `Sources/XcodeExport/XcodeImagesExporterBase.swift` - file extension

## Research Summary

See full research at bottom of this file.

### Key Findings

1. **Xcode supports HEIC** in asset catalogs since Xcode 10.1 (iOS 12+)
2. **ImageIO encoding** works on macOS 10.13.4+ but has known issues on macOS 15.5
3. **libheif** is cross-platform but has GPL licensing issues (x265 encoder)
4. **Hybrid approach** recommended: ImageIO on macOS, PNG fallback on Linux

### Recommended Approach

**Phase 1: macOS-only ImageIO** - covers 95%+ users, simple, no licensing issues.

---

## Full Research

### 1. Figma API Source Formats

Figma API supports these export formats:

- **PNG** - raster, supports scale parameter (0.01-4.0)
- **JPG** - raster, supports scale parameter
- **SVG** - vector, single scale
- **PDF** - vector, single scale

Currently ExFig uses:

- PNG (default) - fetched at multiple scales (1x, 2x, 3x)
- SVG (via `sourceFormat: svg`) - fetched once, rasterized locally with resvg

### 2. Xcode Asset Catalog HEIC Support

**Verdict: SUPPORTED**

- Supported since Xcode 10.1 (iOS 12+)
- Works with `UIImage(named:)` like PNG/JPG
- File extension must be lowercase `.heic`
- May have display issues on very old devices (pre-A9 chip)

### 3. HEIC Encoding Options

#### Option A: Apple ImageIO (macOS only)

**Pros:** Native, hardware-accelerated, no dependencies
**Cons:** macOS only, known issues in macOS 15.5

#### Option B: libheif (Cross-platform)

**Pros:** Works on macOS and Linux
**Cons:** GPL licensing (x265), ~5-10MB binary size, complex build

#### Option C: Hybrid Approach (RECOMMENDED)

Use ImageIO on macOS, disable HEIC on Linux.

### 4. Known Limitations

| Issue                      | Mitigation                         |
| -------------------------- | ---------------------------------- |
| macOS 15.5 encoding bug    | Defer - fix if users report issues |
| Odd dimensions truncated   | Auto-round to even dimensions      |
| DeviceRGB colorspace fails | Force sRGB colorspace              |
| Linux unsupported          | Fallback to PNG with warning       |
| x265 GPL licensing         | Use ImageIO only (no libheif)      |

### 5. Configuration Schema

```yaml
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"
      sourceFormat: svg       # svg | png (default)
      outputFormat: heic      # NEW: png | heic
      heicOptions:            # NEW: like webpOptions
        encoding: lossy       # lossy (default) | lossless
        quality: 90           # 0-100, default: 90
      scales: [1, 2, 3]
```

**Note:** WebP default quality also changes from 80 to 90 (breaking change for consistency).

### References

- [Apple Asset Catalog Format - Image Set Type](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/ImageSetType.html)
- [Apple ImageIO CGImageDestinationCreateWithURL](https://developer.apple.com/documentation/imageio/1465361-cgimagedestinationcreatewithurl)
- [libheif GitHub](https://github.com/strukturag/libheif)
