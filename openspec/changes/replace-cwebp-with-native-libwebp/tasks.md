# Tasks: Replace cwebp with Native libwebp

TDD approach - write tests first, then implement.

## 1. Project Setup

- [ ] 1.1 Add `the-swift-collective/libwebp` dependency to Package.swift (v1.4.1+)
- [ ] 1.2 Add WebP product to ExFig target dependencies
- [ ] 1.3 Verify `swift build` succeeds with new dependency
- [ ] 1.4 Verify libpng is available as transitive dependency

## 2. PNG Decoder (PngDecoder.swift)

- [ ] 2.1 Write tests for `PngDecoder` initialization with valid PNG data
- [ ] 2.2 Write tests for `PngDecoder` with invalid/corrupted data (throws error)
- [ ] 2.3 Write tests for extracting width, height from PNG
- [ ] 2.4 Write tests for decoding PNG to RGBA byte array
- [ ] 2.5 Write tests for handling PNG with alpha channel
- [ ] 2.6 Write tests for handling PNG without alpha (RGB only)
- [ ] 2.7 Implement `PngDecoderError` enum with localized descriptions
- [ ] 2.8 Implement `PngDecoder` class using libpng C API
- [ ] 2.9 Run tests - verify pass

## 3. Native WebP Encoder (NativeWebpEncoder.swift)

- [ ] 3.1 Write tests for `NativeWebpEncoder` initialization
- [ ] 3.2 Write tests for lossless encoding (RGBA -> WebP bytes)
- [ ] 3.3 Write tests for lossy encoding with quality parameter (0-100)
- [ ] 3.4 Write tests for encoding empty/invalid RGBA data (throws error)
- [ ] 3.5 Write tests for encoding various image dimensions
- [ ] 3.6 Write tests for output WebP data validity (magic bytes check)
- [ ] 3.7 Implement `NativeWebpEncoderError` enum
- [ ] 3.8 Implement `NativeWebpEncoder` using WebP C API
- [ ] 3.9 Run tests - verify pass

## 4. WebpConverter Refactoring (WebpConverter.swift)

- [ ] 4.1 Write tests for `WebpConverter.convert(file:)` with PNG input
- [ ] 4.2 Write tests for `WebpConverter.convert(file:)` with non-existent file
- [ ] 4.3 Write tests for `WebpConverter.convert(file:)` with invalid PNG
- [ ] 4.4 Write tests for lossless encoding mode
- [ ] 4.5 Write tests for lossy encoding mode with quality
- [ ] 4.6 Write tests for output file creation (.webp extension)
- [ ] 4.7 Write tests for `convertBatch(files:onProgress:)` with empty array
- [ ] 4.8 Write tests for `convertBatch(files:onProgress:)` with multiple files
- [ ] 4.9 Write tests for progress callback invocation
- [ ] 4.10 Write tests for parallel execution (maxConcurrent limit)
- [ ] 4.11 Refactor `WebpConverter` to use `PngDecoder` + `NativeWebpEncoder`
- [ ] 4.12 Remove `cwebp` binary discovery code
- [ ] 4.13 Remove `Process` spawning code
- [ ] 4.14 Remove `findCwebp()`, `findInPath()`, `standardSearchPaths`
- [ ] 4.15 Update `WebpConverterError` (remove `cwebpNotFound`)
- [ ] 4.16 Run tests - verify pass

## 5. Integration Testing

- [ ] 5.1 Write integration test: PNG file -> WebP file (lossless)
- [ ] 5.2 Write integration test: PNG file -> WebP file (lossy q=80)
- [ ] 5.3 Write integration test: batch conversion of multiple PNGs
- [ ] 5.4 Write integration test: verify WebP output is valid image
- [ ] 5.5 Test with real Figma export workflow (manual)
- [ ] 5.6 Run full test suite (`mise run test`)

## 6. Documentation Updates

- [ ] 6.1 Update CLAUDE.md - remove cwebp from "Optional External Tools"
- [ ] 6.2 Update CLAUDE.md - remove CWEBP_PATH references
- [ ] 6.3 Update CONFIG.md - simplify webpOptions documentation
- [ ] 6.4 Update `.github/docs/android/images.md` - remove cwebp install instructions
- [ ] 6.5 Update `.github/docs/flutter/images.md` - remove cwebp install instructions
- [ ] 6.6 Add migration note to CHANGELOG.md (CWEBP_PATH deprecated)

## 7. Cleanup & Validation

- [ ] 7.1 Remove unused imports (Foundation Process-related if any)
- [ ] 7.2 Run linter (`mise run lint`)
- [ ] 7.3 Run formatter (`mise run format`)
- [ ] 7.4 Run full test suite with coverage (`mise run coverage`)
- [ ] 7.5 Verify CI passes on all platforms (macOS, Linux)
