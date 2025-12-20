# Tasks: Add HEIC Output Format for iOS Images

## 1. Core Encoder

- [ ] 1.1 Create `NativeHeicEncoder.swift` with ImageIO
- [ ] 1.2 Add `isAvailable()` check for platform/version support
- [ ] 1.3 Handle odd dimension rounding (HEIC requires even dimensions)
- [ ] 1.4 Force sRGB colorspace (DeviceRGB fails silently)

## 2. SVG to HEIC Converter

- [ ] 2.1 Create `SvgToHeicConverter.swift` following `SvgToPngConverter` pattern
- [ ] 2.2 Integrate with resvg for SVG rasterization
- [ ] 2.3 Add quality parameter support

## 3. Configuration

- [ ] 3.1 Add `outputFormat` field to `iOS.ImagesEntry` in `Params.swift`
- [ ] 3.2 Add `heicQuality` field with default 0.9
- [ ] 3.3 Validate outputFormat values (png, heic)
- [ ] 3.4 Update CONFIG.md documentation

## 4. Export Pipeline

- [ ] 4.1 Update `ImagesLoader` to pass output format config
- [ ] 4.2 Update `ExportImages` to use HEIC converter when configured
- [ ] 4.3 Add Linux fallback with warning message

## 5. Xcode Export

- [ ] 5.1 Update `XcodeImagesExporter` to output `.heic` files
- [ ] 5.2 Update `Contents.json` generation for HEIC extension
- [ ] 5.3 Verify asset catalog structure matches Xcode expectations

## 6. Tests

- [ ] 6.1 Unit tests for `NativeHeicEncoder`
- [ ] 6.2 Unit tests for `SvgToHeicConverter`
- [ ] 6.3 Integration tests for full pipeline
- [ ] 6.4 Platform skip tests for Linux

## 7. Documentation

- [ ] 7.1 Update CLAUDE.md with HEIC section
- [ ] 7.2 Update CONFIG.md with outputFormat/heicQuality
- [ ] 7.3 Add iOS 12+ minimum requirement note
