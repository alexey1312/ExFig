# Design: Native libwebp Integration

## Context

ExFig converts PNG images to WebP format for Android and Flutter exports. Currently this requires the external `cwebp`
command-line tool, which users must install separately.

**Stakeholders**: ExFig users, CI/CD pipelines, contributors

**Constraints**:

- Must work on macOS (arm64, x86_64) and Linux (x86_64, arm64)
- Must support both lossy and lossless WebP encoding
- Must maintain current API (`WebpConverter` class interface)
- Should not significantly increase build time

## Goals / Non-Goals

**Goals**:

- Zero external dependencies for WebP conversion
- Cross-platform support via pure Swift/SPM
- Maintain current encoding quality and options
- TDD implementation with comprehensive tests

**Non-Goals**:

- WebP decoding (not needed for export use case)
- Animated WebP support
- Advanced encoding options beyond quality/lossless

## Decisions

### Decision 1: Use `the-swift-collective/libwebp` package

**What**: Add SPM dependency on `https://github.com/the-swift-collective/libwebp.git`

**Why**:

- Provides libwebp 1.4.x compiled from source via SPM
- Includes libpng as transitive dependency (needed for PNG decoding)
- Cross-platform CI (macOS, Linux, Windows)
- BSD-3-Clause license (compatible with ExFig)
- Actively maintained (v1.4.1 released recently)

**Alternatives considered**:

| Option                  | Pros               | Cons                                               |
| ----------------------- | ------------------ | -------------------------------------------------- |
| Keep cwebp binary       | No code changes    | Installation friction, CI complexity               |
| Swift-WebP (ainame)     | Swift-friendly API | Older libwebp 1.2.0, requires separate PNG decoder |
| SDWebImageWebPCoder     | Well maintained    | Heavy SDWebImage dependency, iOS-focused           |
| Build libwebp ourselves | Full control       | Maintenance burden, complex build                  |

### Decision 2: Two-stage conversion (PNG -> RGBA -> WebP)

**What**: Create separate `PngDecoder` and `NativeWebpEncoder` classes

**Why**:

- Clear separation of concerns
- Each component independently testable
- Reusable if other formats needed later
- Matches libwebp/libpng API structure

**Data flow**:

```
PNG File (disk)
    |
    v
[PngDecoder] -- libpng C API
    |
    v
RGBA bytes (memory) -- [UInt8] array
    |
    v
[NativeWebpEncoder] -- libwebp C API
    |
    v
WebP bytes (memory)
    |
    v
WebP File (disk)
```

### Decision 3: Maintain WebpConverter public API

**What**: Keep existing `WebpConverter` class interface unchanged

**Why**:

- No breaking changes for internal callers (`ExportImages.swift`)
- Easy rollback if issues discovered
- Encapsulates implementation detail

**Interface preserved**:

```swift
final class WebpConverter: Sendable {
    enum Encoding: Sendable {
        case lossy(quality: Int)
        case lossless
    }

    init(encoding: Encoding, maxConcurrent: Int = 4) throws
    func convert(file url: URL) throws
    func convertBatch(files: [URL], onProgress: ConversionProgressCallback?) async throws
}
```

**Changes**:

- `init` no longer throws `cwebpNotFound` (always succeeds)
- Remove `static func findCwebp()` and `static func isAvailable()`
- Simplify error types

### Decision 4: Memory management for C interop

**What**: Use Swift's `withUnsafeBufferPointer` for safe C interop

**Why**:

- Automatic memory management
- No manual malloc/free
- Compiler-verified safety

**Pattern**:

```swift
func encode(rgba: [UInt8], width: Int, height: Int, quality: Float) throws -> [UInt8] {
    var output: UnsafeMutablePointer<UInt8>?
    let size = rgba.withUnsafeBufferPointer { buffer in
        WebPEncodeRGBA(buffer.baseAddress, Int32(width), Int32(height),
                       Int32(width * 4), quality, &output)
    }
    guard size > 0, let outputPtr = output else {
        throw NativeWebpEncoderError.encodingFailed
    }
    defer { WebPFree(outputPtr) }
    return Array(UnsafeBufferPointer(start: outputPtr, count: Int(size)))
}
```

## Risks / Trade-offs

| Risk                                               | Impact                               | Mitigation                              |
| -------------------------------------------------- | ------------------------------------ | --------------------------------------- |
| libwebp version older than latest (1.4.x vs 1.6.0) | Minor - missing latest optimizations | Acceptable; can update dependency later |
| Build time increase                                | Medium - compiles C code             | One-time cost; cached by SPM            |
| Memory usage for large images                      | Low - RGBA in memory                 | Same as cwebp approach                  |
| Library abandonment                                | Low - simple C wrapper               | Fork if needed; libwebp is stable       |

## Migration Plan

1. Add dependency, implement new classes (non-breaking)
2. Refactor `WebpConverter` internals (non-breaking - same API)
3. Remove `cwebp` discovery code
4. Update documentation
5. Release with deprecation note for `CWEBP_PATH`

**Rollback**: Revert PR; no database/state changes involved

## Open Questions

- [ ] Should we keep `isAvailable()` method for backward compatibility? (Returns `true` always)
- [ ] Should we emit deprecation warning if `CWEBP_PATH` is set?

## File Structure

```
Sources/ExFig/Output/
├── WebpConverter.swift      # Refactored (uses native encoder)
├── PngDecoder.swift         # NEW: PNG -> RGBA using libpng
└── NativeWebpEncoder.swift  # NEW: RGBA -> WebP using libwebp

Tests/ExFigTests/
├── WebpConverterTests.swift      # NEW: Integration tests
├── PngDecoderTests.swift         # NEW: Unit tests
└── NativeWebpEncoderTests.swift  # NEW: Unit tests
```

## libwebp C API Reference

**Encoding functions** (from `webp/encode.h`):

```c
// Simple lossy encoding
size_t WebPEncodeRGBA(const uint8_t* rgba, int width, int height, int stride,
                      float quality_factor, uint8_t** output);

// Simple lossless encoding
size_t WebPEncodeLosslessRGBA(const uint8_t* rgba, int width, int height,
                               int stride, uint8_t** output);

// Free output buffer
void WebPFree(void* ptr);
```

**libpng functions** (for PNG decoding):

```c
png_structp png_create_read_struct(...);
png_infop png_create_info_struct(png_structp);
void png_read_info(png_structp, png_infop);
png_uint_32 png_get_image_width(png_structp, png_infop);
png_uint_32 png_get_image_height(png_structp, png_infop);
void png_read_image(png_structp, png_bytepp);
```
