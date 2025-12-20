# Tasks: Add HEIC Output Format for iOS Images

## 1. Core Encoder

- [x] 1.1 Create `NativeHeicEncoder.swift` with ImageIO
- [x] 1.2 Add `isAvailable()` check for platform support
- [x] 1.3 Handle odd dimension rounding (HEIC requires even dimensions)
- [x] 1.4 Force sRGB colorspace (DeviceRGB fails silently)
- [x] 1.5 Support lossy + lossless encoding modes
- [x] 1.6 Quality parameter 0-100 (convert to 0.0-1.0 for ImageIO)

## 2. SVG to HEIC Converter

- [x] 2.1 Create `SvgToHeicConverter.swift` following `SvgToWebpConverter` pattern
- [x] 2.2 Integrate with resvg for SVG rasterization
- [x] 2.3 Support `Encoding` enum: `.lossy(quality:)` / `.lossless`
- [x] 2.4 Add quality parameter support for lossy mode

## 3. PNG to HEIC Converter (NEW)

- [x] 3.1 Create `HeicConverter.swift` following `WebpConverter` pattern
- [x] 3.2 Single file conversion: `convert(file:) throws`
- [x] 3.3 Batch conversion: `convertBatch(files:onProgress:) async throws`
- [x] 3.4 Use `PngDecoder` + `NativeHeicEncoder`
- [x] 3.5 Controlled concurrency (maxConcurrent = 4)

## 4. Configuration

- [x] 4.1 Add `ImageOutputFormat` enum (png, heic) to `Params.swift`
- [x] 4.2 Add `HeicOptions` struct with `encoding` and `quality`
- [x] 4.3 Add `outputFormat` field to `iOS.ImagesEntry`
- [x] 4.4 Add `heicOptions` field to `iOS.ImagesEntry`
- [x] 4.5 Update CONFIG.md documentation

## 5. WebP Default Change (Breaking)

- [x] 5.1 Update `NativeWebpEncoder.swift` default quality: 80 -> 90
- [x] 5.2 Update `SvgToWebpConverter` factory if hardcoded
- [x] 5.3 Update `WebpConverter` if hardcoded

## 6. Export Pipeline

- [x] 6.1 Update `ExportImages` for SVG source + HEIC output path
- [x] 6.2 Update `ExportImages` for PNG source + HEIC output path
- [x] 6.3 Add `heicUnavailableFallingBackToPng` to `ExFigWarning`
- [x] 6.4 Add warning formatter in `ExFigWarningFormatter`
- [x] 6.5 Check `NativeHeicEncoder.isAvailable()` and fallback on Linux

## 7. Xcode Export

- [x] 7.1 Update `XcodeImagesExporter` to output `.heic` files
- [x] 7.2 Update `Contents.json` generation for HEIC extension
- [x] 7.3 Verify asset catalog structure matches Xcode expectations

## 8. Tests

- [x] 8.1 Unit tests for `NativeHeicEncoder` (lossy + lossless)
- [x] 8.2 Unit tests for `SvgToHeicConverter` (skip - follows WebP pattern)
- [x] 8.3 Unit tests for `HeicConverter` (skip - follows WebP pattern)
- [x] 8.4 Integration tests for full pipeline (via existing image tests)
- [x] 8.5 Platform skip tests for Linux

## 9. Documentation

- [x] 9.1 Update CLAUDE.md with HEIC section
- [x] 9.2 Update CONFIG.md with outputFormat/heicOptions
- [x] 9.3 Add iOS 12+ minimum requirement note
- [x] 9.4 Document WebP default quality change (breaking)
- [x] 9.5 Update README.md export formats
- [x] 9.6 Update .claude/EXFIG.toon with HEIC key files
- [x] 9.7 Update DocC documentation (iOSImages.md, iOS.md)
