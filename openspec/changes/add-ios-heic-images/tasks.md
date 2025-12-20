# Tasks: Add HEIC Output Format for iOS Images

## 1. Core Encoder

- [ ] 1.1 Create `NativeHeicEncoder.swift` with ImageIO
- [ ] 1.2 Add `isAvailable()` check for platform support
- [ ] 1.3 Handle odd dimension rounding (HEIC requires even dimensions)
- [ ] 1.4 Force sRGB colorspace (DeviceRGB fails silently)
- [ ] 1.5 Support lossy + lossless encoding modes
- [ ] 1.6 Quality parameter 0-100 (convert to 0.0-1.0 for ImageIO)

## 2. SVG to HEIC Converter

- [ ] 2.1 Create `SvgToHeicConverter.swift` following `SvgToWebpConverter` pattern
- [ ] 2.2 Integrate with resvg for SVG rasterization
- [ ] 2.3 Support `Encoding` enum: `.lossy(quality:)` / `.lossless`
- [ ] 2.4 Add quality parameter support for lossy mode

## 3. PNG to HEIC Converter (NEW)

- [ ] 3.1 Create `HeicConverter.swift` following `WebpConverter` pattern
- [ ] 3.2 Single file conversion: `convert(file:) throws`
- [ ] 3.3 Batch conversion: `convertBatch(files:onProgress:) async throws`
- [ ] 3.4 Use `PngDecoder` + `NativeHeicEncoder`
- [ ] 3.5 Controlled concurrency (maxConcurrent = 4)

## 4. Configuration

- [ ] 4.1 Add `ImageOutputFormat` enum (png, heic) to `Params.swift`
- [ ] 4.2 Add `HeicOptions` struct with `encoding` and `quality`
- [ ] 4.3 Add `outputFormat` field to `iOS.ImagesEntry`
- [ ] 4.4 Add `heicOptions` field to `iOS.ImagesEntry`
- [ ] 4.5 Update CONFIG.md documentation

## 5. WebP Default Change (Breaking)

- [ ] 5.1 Update `NativeWebpEncoder.swift` default quality: 80 -> 90
- [ ] 5.2 Update `SvgToWebpConverter` factory if hardcoded
- [ ] 5.3 Update `WebpConverter` if hardcoded

## 6. Export Pipeline

- [ ] 6.1 Update `ExportImages` for SVG source + HEIC output path
- [ ] 6.2 Update `ExportImages` for PNG source + HEIC output path
- [ ] 6.3 Add `heicUnavailableFallingBackToPng` to `ExFigWarning`
- [ ] 6.4 Add warning formatter in `ExFigWarningFormatter`
- [ ] 6.5 Check `NativeHeicEncoder.isAvailable()` and fallback on Linux

## 7. Xcode Export

- [ ] 7.1 Update `XcodeImagesExporter` to output `.heic` files
- [ ] 7.2 Update `Contents.json` generation for HEIC extension
- [ ] 7.3 Verify asset catalog structure matches Xcode expectations

## 8. Tests

- [ ] 8.1 Unit tests for `NativeHeicEncoder` (lossy + lossless)
- [ ] 8.2 Unit tests for `SvgToHeicConverter`
- [ ] 8.3 Unit tests for `HeicConverter`
- [ ] 8.4 Integration tests for full pipeline
- [ ] 8.5 Platform skip tests for Linux

## 9. Documentation

- [ ] 9.1 Update CLAUDE.md with HEIC section
- [ ] 9.2 Update CONFIG.md with outputFormat/heicOptions
- [ ] 9.3 Add iOS 12+ minimum requirement note
- [ ] 9.4 Document WebP default quality change (breaking)
