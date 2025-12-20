# iOS HEIC Image Conversion - Research & Implementation Plan

## Executive Summary

This document analyzes the feasibility of adding HEIC output format for iOS images export in ExFig.
The goal is to convert images from Figma (PDF/SVG/PNG/JPG) to HEIC format for iOS asset catalogs.

## Research Findings

### 1. Figma API Source Formats

Figma API supports these export formats (see `ImageEndpoint.swift:9`):
- **PNG** - raster, supports scale parameter (0.01-4.0)
- **JPG** - raster, supports scale parameter
- **SVG** - vector, single scale
- **PDF** - vector, single scale

Currently ExFig uses:
- PNG (default) - fetched at multiple scales (1x, 2x, 3x)
- SVG (via `sourceFormat: svg`) - fetched once, rasterized locally with resvg

### 2. Xcode Asset Catalog HEIC Support

**Verdict: SUPPORTED**

Xcode asset catalogs (`.xcassets`) support HEIC files:
- Supported since Xcode 10.1 (iOS 12+)
- Works with `UIImage(named:)` like PNG/JPG
- File extension must be lowercase `.heic` (not `.HEIC`)
- May have display issues on very old devices (pre-A9 chip)

Source: [Apple Asset Catalog Format Reference](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/ImageSetType.html)

### 3. HEIC Encoding Options

#### Option A: Apple ImageIO (macOS only)

**Pros:**
- Native, no external dependencies
- High quality, hardware-accelerated on Apple Silicon
- Uses same pattern as existing `NativePngEncoder.swift`

**Cons:**
- **macOS only** - won't work on Linux CI
- Requires macOS 10.13.4+
- Known issues in macOS 15.5 / iOS 18.4 (CMPhotoCompressionSession error)
- Odd dimensions get truncated to even

**Implementation:**
```swift
import ImageIO
import UniformTypeIdentifiers

// UTType.heic available since macOS 11.0
CGImageDestinationCreateWithData(mutableData, UTType.heic.identifier as CFString, 1, nil)
CGImageDestinationAddImage(destination, cgImage, options)
CGImageDestinationFinalize(destination)
```

**Important:** Image must have ICC-based color profile (sRGB works, DeviceRGB doesn't).

Sources:
- [Apple CIContext.writeHEIFRepresentation](https://developer.apple.com/documentation/coreimage/cicontext/2902266-writeheifrepresentation)
- [Apple Developer Forums - HEIC encoding issues](https://developer.apple.com/forums/thread/87111)

#### Option B: libheif (Cross-platform)

**Pros:**
- Works on macOS and Linux
- Mature, widely used (ImageMagick, GIMP, etc.)
- C API suitable for Swift integration

**Cons:**
- Requires building/bundling static library (like current resvg approach)
- Licensing complexity:
  - libheif: LGPL
  - x265 encoder: **GPL** (viral license)
  - kvazaar encoder: BSD (better, but less common)
- Additional ~5-10MB binary size
- More complex build pipeline

**Dependencies:**
- libde265 (decoder, BSD)
- x265 OR kvazaar (encoder)
- libheif (wrapper)

Source: [strukturag/libheif](https://github.com/strukturag/libheif)

#### Option C: Hybrid Approach

Use ImageIO on macOS, disable HEIC on Linux (or skip conversion).

**Pros:**
- Simple implementation
- No licensing issues
- Works for most users (ExFig is macOS-focused CLI)

**Cons:**
- Linux CI would need to use PNG fallback or skip HEIC tests
- Feature parity gap between platforms

### 4. Current Conversion Architecture

ExFig already has converters following this pattern:

| Converter | Input | Output | Library | Platform |
|-----------|-------|--------|---------|----------|
| `SvgToPngConverter` | SVG (Data) | PNG (Data) | resvg + libpng | macOS + Linux |
| `SvgToWebpConverter` | SVG (Data) | WebP (Data) | resvg + libwebp | macOS + Linux |
| `WebpConverter` | PNG (file) | WebP (file) | libwebp | macOS + Linux |
| `NativePngEncoder` | RGBA | PNG (Data) | ImageIO / libpng | macOS + Linux |
| `NativeWebpEncoder` | RGBA | WebP (Data) | libwebp | macOS + Linux |

**Key insight:** The pattern is:
1. Rasterize to RGBA (via resvg for SVG, or PngDecoder for PNG)
2. Encode to target format

### 5. HEIC Benefits

- **~40-50% smaller** file size vs PNG at similar quality
- Native iOS support since iOS 11
- Hardware decoding on A9+ chips
- Supports transparency (unlike JPEG)

### 6. Known Limitations

| Issue | Impact | Mitigation |
|-------|--------|------------|
| macOS 15.5 encoding bug | Fails on latest OS | Wait for Apple fix or use libheif |
| Odd dimensions truncated | Visual artifacts | Round up to even |
| DeviceRGB colorspace fails | Black images | Force sRGB colorspace |
| Slower than PNG encoding | Build time | Acceptable tradeoff |
| Pre-A9 devices | Display issues | Document minimum iOS version |

## Recommended Implementation Plan

### Phase 1: macOS-only ImageIO approach

**Rationale:** Simplest path, covers 95%+ of users, no licensing issues.

#### 1.1 Create NativeHeicEncoder

```swift
// Sources/ExFig/Output/NativeHeicEncoder.swift
struct NativeHeicEncoder: Sendable {
    let quality: Float // 0.0-1.0, default 0.9

    func encode(rgba: [UInt8], width: Int, height: Int) throws -> Data
    static func isAvailable() -> Bool // Check for ImageIO HEIC support
}
```

**Files to create:**
- `Sources/ExFig/Output/NativeHeicEncoder.swift`

**Pattern to follow:**
- `NativePngEncoder.swift` for ImageIO usage
- Platform-specific `#if canImport(ImageIO)` guards

#### 1.2 Create SvgToHeicConverter

```swift
// Sources/ExFig/Output/SvgToHeicConverter.swift
struct SvgToHeicConverter: Sendable {
    let quality: Float

    func convert(svgData: Data, scale: Double, fileName: String) throws -> Data
}
```

**Pattern to follow:**
- `SvgToPngConverter.swift`

#### 1.3 Add HEIC format to iOS config

```yaml
# exfig.yaml
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"
      sourceFormat: svg
      outputFormat: heic  # NEW
      heicQuality: 0.9    # NEW, optional
      scales: [1, 2, 3]
```

**Files to modify:**
- `Sources/ExFig/Input/Params.swift` - add `outputFormat`, `heicQuality` to iOS.ImagesEntry
- `Sources/ExFig/Loaders/ImagesLoader.swift` - add output format handling
- `Sources/ExFig/Subcommands/ExportImages.swift` - use HEIC converter when configured

#### 1.4 Update XcodeImagesExporter

Modify Contents.json generation to use `.heic` extension.

**Files to modify:**
- `Sources/XcodeExport/XcodeImagesExporter.swift`
- `Sources/XcodeExport/XcodeImagesExporterBase.swift`
- Related models for file naming

#### 1.5 Add Linux fallback

On Linux, either:
- Fall back to PNG with warning
- Skip HEIC encoding (return PNG data with warning)
- Error with recovery suggestion

### Phase 2 (Future): Cross-platform libheif

Only if Linux support becomes critical:

1. Build libheif + kvazaar (BSD) as static libraries
2. Create C header wrapper (`Sources/CHeif/`)
3. Create Swift wrapper (`Sources/Heif/`)
4. Update `NativeHeicEncoder` to use libheif on Linux

**Estimated effort:** 2-3x more complex than Phase 1.

## Configuration Schema

```yaml
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"

      # Source from Figma API (existing)
      sourceFormat: svg  # svg | png (default: png)

      # Output format for asset catalog (NEW)
      outputFormat: png  # png | heic (default: png)

      # HEIC-specific options (NEW)
      heicQuality: 0.9   # 0.0-1.0, default 0.9

      scales: [1, 2, 3]
```

## Testing Strategy

1. **Unit tests** for NativeHeicEncoder
   - Valid RGBA encoding
   - Invalid dimensions handling
   - Quality parameter validation

2. **Integration tests**
   - SVG → HEIC conversion pipeline
   - Asset catalog structure with .heic files
   - Contents.json format verification

3. **Platform tests**
   - macOS: Full HEIC support
   - Linux: Graceful fallback/error

4. **Xcode validation**
   - Generated .xcassets loads in Xcode
   - UIImage(named:) works at runtime
   - All scales display correctly

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| macOS 15.5 ImageIO bug | High | Build fails on latest macOS | Version check, fallback to PNG |
| Odd dimension truncation | Medium | Visual artifacts | Auto-round to even dimensions |
| HEIC not supported on old iOS | Low | Runtime crash | Document iOS 11+ requirement |
| Linux users need HEIC | Low | Feature unavailable | Phase 2 libheif implementation |

## Decision Matrix

| Approach | Complexity | Cross-platform | Licensing | Recommended |
|----------|------------|----------------|-----------|-------------|
| ImageIO only (macOS) | Low | No | Clean | **Yes (Phase 1)** |
| libheif + x265 | High | Yes | GPL (viral) | No |
| libheif + kvazaar | High | Yes | BSD | Maybe (Phase 2) |

## Conclusion

**Recommendation:** Implement Phase 1 (macOS-only ImageIO) first.

- Covers primary use case (macOS developers)
- Simple implementation following existing patterns
- No licensing complications
- Can extend to libheif later if needed

**Estimated effort:**
- Phase 1: ~2-3 days implementation + testing
- Phase 2: ~5-7 days (if ever needed)

## References

- [Apple Asset Catalog Format - Image Set Type](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/ImageSetType.html)
- [Apple ImageIO CGImageDestinationCreateWithURL](https://developer.apple.com/documentation/imageio/1465361-cgimagedestinationcreatewithurl)
- [HEIC Performance Analysis (Nutrient/PSPDFKit)](https://pspdfkit.com/blog/2018/ios-heic-performance/)
- [libheif GitHub](https://github.com/strukturag/libheif)
- [SDWebImage libheif-Xcode wrapper](https://github.com/SDWebImage/libheif-Xcode)
- [dreampiggy/TestAppleHEICEncoding](https://github.com/dreampiggy/TestAppleHEICEncoding)
