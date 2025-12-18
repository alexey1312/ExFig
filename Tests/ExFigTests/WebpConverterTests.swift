// swiftlint:disable file_length type_body_length
@testable import ExFig
import Foundation
import XCTest

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

#if canImport(ImageIO)
    import ImageIO
#endif

#if canImport(LibPNG)
    import LibPNG
#endif

/// Thread-safe progress tracker for async tests
private actor ProgressTracker {
    var calls: [(Int, Int)] = []

    func append(_ call: (Int, Int)) {
        calls.append(call)
    }
}

final class WebpConverterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WebpConverterTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Availability Tests

    func testIsAvailableAlwaysReturnsTrue() {
        XCTAssertTrue(WebpConverter.isAvailable())
    }

    // MARK: - Single File Conversion Tests

    func testConvertLossless() throws {
        // Skip on Linux: libpng has memory corruption issues that cause crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
        #endif

        let pngURL = try createTestPNG(width: 10, height: 10, color: (255, 0, 0, 255))
        let converter = WebpConverter(encoding: .lossless)

        try converter.convert(file: pngURL)

        let webpURL = pngURL.deletingPathExtension().appendingPathExtension("webp")
        XCTAssertTrue(FileManager.default.fileExists(atPath: webpURL.path))

        // Verify WebP magic bytes
        let webpData = try Data(contentsOf: webpURL)
        verifyWebPMagic([UInt8](webpData))
    }

    func testConvertLossyWithQuality() throws {
        // Skip on Linux: libpng has memory corruption issues that cause crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
        #endif

        let pngURL = try createTestPNG(width: 20, height: 20, color: (0, 255, 0, 255))
        let converter = WebpConverter(encoding: .lossy(quality: 80))

        try converter.convert(file: pngURL)

        let webpURL = pngURL.deletingPathExtension().appendingPathExtension("webp")
        XCTAssertTrue(FileManager.default.fileExists(atPath: webpURL.path))

        let webpData = try Data(contentsOf: webpURL)
        verifyWebPMagic([UInt8](webpData))
    }

    func testConvertPreservesOriginalPNG() throws {
        // Skip on Linux: libpng has memory corruption issues that cause crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
        #endif

        let pngURL = try createTestPNG(width: 5, height: 5, color: (0, 0, 255, 255))
        let originalData = try Data(contentsOf: pngURL)
        let converter = WebpConverter(encoding: .lossless)

        try converter.convert(file: pngURL)

        // Original PNG should still exist with same content
        XCTAssertTrue(FileManager.default.fileExists(atPath: pngURL.path))
        let afterData = try Data(contentsOf: pngURL)
        XCTAssertEqual(originalData, afterData)
    }

    func testConvertCreatesWebpWithCorrectExtension() throws {
        // Skip on Linux: libpng has memory corruption issues that cause crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
        #endif

        let pngURL = try createTestPNG(width: 3, height: 3, color: (128, 128, 128, 255), name: "test-image")
        let converter = WebpConverter(encoding: .lossless)

        try converter.convert(file: pngURL)

        let expectedWebpURL = tempDirectory.appendingPathComponent("test-image.webp")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedWebpURL.path))
    }

    // MARK: - Error Handling Tests

    func testConvertThrowsForNonExistentFile() {
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.png")
        let converter = WebpConverter(encoding: .lossless)

        XCTAssertThrowsError(try converter.convert(file: nonExistentURL)) { error in
            guard let webpError = error as? WebpConverterError else {
                XCTFail("Expected WebpConverterError")
                return
            }
            if case let .fileNotFound(path) = webpError {
                XCTAssertTrue(path.contains("nonexistent.png"))
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testConvertThrowsForInvalidPNG() throws {
        let invalidURL = tempDirectory.appendingPathComponent("invalid.png")
        try Data("not a png".utf8).write(to: invalidURL)
        let converter = WebpConverter(encoding: .lossless)

        XCTAssertThrowsError(try converter.convert(file: invalidURL)) { error in
            guard let webpError = error as? WebpConverterError else {
                XCTFail("Expected WebpConverterError")
                return
            }
            if case let .invalidInputFormat(path) = webpError {
                XCTAssertTrue(path.contains("invalid.png"))
            } else {
                XCTFail("Expected invalidInputFormat error")
            }
        }
    }

    // MARK: - Batch Conversion Tests

    func testConvertBatchWithEmptyArray() async throws {
        let converter = WebpConverter(encoding: .lossless)

        // Should not throw for empty array
        try await converter.convertBatch(files: [])
    }

    func testConvertBatchWithMultipleFiles() async throws {
        // Skip on Linux: libpng has thread-safety issues when creating multiple PNG files
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng thread-safety issues")
        #endif

        let pngURLs = try (0 ..< 5).map { i in
            try createTestPNG(width: 5, height: 5, color: (UInt8(i * 50), 100, 100, 255), name: "batch-\(i)")
        }
        let converter = WebpConverter(encoding: .lossy(quality: 75))

        try await converter.convertBatch(files: pngURLs)

        // Verify all WebP files were created
        for pngURL in pngURLs {
            let webpURL = pngURL.deletingPathExtension().appendingPathExtension("webp")
            XCTAssertTrue(FileManager.default.fileExists(atPath: webpURL.path), "Missing: \(webpURL.lastPathComponent)")
        }
    }

    func testConvertBatchCallsProgressCallback() async throws {
        // Skip on Linux: libpng has thread-safety issues when creating multiple PNG files
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng thread-safety issues")
        #endif

        let pngURLs = try (0 ..< 3).map { i in
            try createTestPNG(width: 3, height: 3, color: (100, 100, 100, 255), name: "progress-\(i)")
        }
        let converter = WebpConverter(encoding: .lossless)

        let progressCalls = ProgressTracker()
        try await converter.convertBatch(files: pngURLs) { current, total in
            await progressCalls.append((current, total))
        }

        // Should have 3 progress calls (one for each file)
        let calls = await progressCalls.calls
        XCTAssertEqual(calls.count, 3)

        // Each call should have total = 3
        for (_, total) in calls {
            XCTAssertEqual(total, 3)
        }

        // Current should progress from 1 to 3
        let currents = calls.map(\.0).sorted()
        XCTAssertEqual(currents, [1, 2, 3])
    }

    func testConvertBatchRespectsMaxConcurrent() async throws {
        // Skip on Linux: libpng has thread-safety issues when creating multiple PNG files
        // in rapid succession, causing memory corruption crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng thread-safety issues")
        #endif

        // Create many files to test concurrency limiting
        let pngURLs = try (0 ..< 10).map { i in
            try createTestPNG(width: 2, height: 2, color: (50, 50, 50, 255), name: "concurrent-\(i)")
        }
        let converter = WebpConverter(encoding: .lossless, maxConcurrent: 2)

        try await converter.convertBatch(files: pngURLs)

        // Verify all files were converted
        for pngURL in pngURLs {
            let webpURL = pngURL.deletingPathExtension().appendingPathExtension("webp")
            XCTAssertTrue(FileManager.default.fileExists(atPath: webpURL.path))
        }
    }

    // MARK: - Quality Comparison Tests

    func testLossyAndLosslessProduceDifferentSizes() throws {
        // Skip on Linux: libpng has memory corruption issues that cause crashes
        #if os(Linux)
            throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
        #endif

        // Create a larger image with more detail for meaningful comparison
        let pngURL = try createCheckerboardPNG(width: 100, height: 100, name: "quality-test")

        // Convert with lossless
        let losslessConverter = WebpConverter(encoding: .lossless)
        try losslessConverter.convert(file: pngURL)
        let losslessWebpURL = pngURL.deletingPathExtension().appendingPathExtension("webp")
        let losslessAttrs = try FileManager.default.attributesOfItem(atPath: losslessWebpURL.path)
        let losslessSize = (losslessAttrs[.size] as? Int) ?? 0

        // Remove the webp to convert again
        try FileManager.default.removeItem(at: losslessWebpURL)

        // Convert with lossy (low quality)
        let lossyConverter = WebpConverter(encoding: .lossy(quality: 10))
        try lossyConverter.convert(file: pngURL)
        let lossyAttrs = try FileManager.default.attributesOfItem(atPath: losslessWebpURL.path)
        let lossySize = (lossyAttrs[.size] as? Int) ?? 0

        // Both should produce valid files with non-zero size
        XCTAssertGreaterThan(losslessSize, 0, "Lossless should produce non-empty file")
        XCTAssertGreaterThan(lossySize, 0, "Lossy should produce non-empty file")

        // Sizes should be different (different encoding algorithms)
        // Note: For simple images like checkerboard, lossless can be smaller than lossy
        // because it can exploit repeating patterns efficiently
        XCTAssertNotEqual(lossySize, losslessSize, "Lossy and lossless should produce different sizes")
    }

    // MARK: - Helpers

    #if canImport(CoreGraphics) && canImport(ImageIO)
        private func createTestPNG(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8),
            name: String = "test"
        ) throws -> URL {
            let data = try createPNGData(width: width, height: height, color: color)
            let url = tempDirectory.appendingPathComponent("\(name).png")
            try data.write(to: url)
            return url
        }

        private func createCheckerboardPNG(width: Int, height: Int, name: String) throws -> URL {
            let bytesPerRow = width * 4
            var rgba = [UInt8](repeating: 0, count: width * height * 4)

            for y in 0 ..< height {
                for x in 0 ..< width {
                    let offset = (y * width + x) * 4
                    let isWhite = (x + y) % 2 == 0
                    let color: UInt8 = isWhite ? 255 : 0
                    rgba[offset] = color
                    rgba[offset + 1] = color
                    rgba[offset + 2] = color
                    rgba[offset + 3] = 255
                }
            }

            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: &rgba,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                  ),
                  let cgImage = context.makeImage()
            else {
                throw WebpConverterError.encodingFailed(file: name, reason: "Failed to create test image")
            }

            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                "public.png" as CFString,
                1,
                nil
            ) else {
                throw WebpConverterError.encodingFailed(file: name, reason: "Failed to create destination")
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw WebpConverterError.encodingFailed(file: name, reason: "Failed to finalize")
            }

            let url = tempDirectory.appendingPathComponent("\(name).png")
            try (data as Data).write(to: url)
            return url
        }

        private func createPNGData(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8)
        ) throws -> Data {
            let bytesPerRow = width * 4
            var rgba = [UInt8](repeating: 0, count: width * height * 4)

            for i in 0 ..< (width * height) {
                rgba[i * 4] = color.0
                rgba[i * 4 + 1] = color.1
                rgba[i * 4 + 2] = color.2
                rgba[i * 4 + 3] = color.3
            }

            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: &rgba,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                  ),
                  let cgImage = context.makeImage()
            else {
                throw WebpConverterError.encodingFailed(file: "test", reason: "Failed to create test image")
            }

            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                "public.png" as CFString,
                1,
                nil
            ) else {
                throw WebpConverterError.encodingFailed(file: "test", reason: "Failed to create destination")
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw WebpConverterError.encodingFailed(file: "test", reason: "Failed to finalize")
            }

            return data as Data
        }
    #else
        /// Creates a test PNG file using libpng (Linux)
        private func createTestPNG(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8),
            name: String = "test"
        ) throws -> URL {
            let data = try createPNGDataWithLibpng(width: width, height: height) { rgba in
                for i in 0 ..< (width * height) {
                    rgba[i * 4] = color.0
                    rgba[i * 4 + 1] = color.1
                    rgba[i * 4 + 2] = color.2
                    rgba[i * 4 + 3] = color.3
                }
            }
            let url = tempDirectory.appendingPathComponent("\(name).png")
            try data.write(to: url)
            return url
        }

        /// Creates a checkerboard PNG using libpng (Linux)
        private func createCheckerboardPNG(width: Int, height: Int, name: String) throws -> URL {
            let data = try createPNGDataWithLibpng(width: width, height: height) { rgba in
                for y in 0 ..< height {
                    for x in 0 ..< width {
                        let offset = (y * width + x) * 4
                        let isWhite = (x + y) % 2 == 0
                        let color: UInt8 = isWhite ? 255 : 0
                        rgba[offset] = color
                        rgba[offset + 1] = color
                        rgba[offset + 2] = color
                        rgba[offset + 3] = 255
                    }
                }
            }
            let url = tempDirectory.appendingPathComponent("\(name).png")
            try data.write(to: url)
            return url
        }

        /// Creates PNG data using libpng simplified API (Linux)
        private func createPNGDataWithLibpng(
            width: Int,
            height: Int,
            fillPixels: (UnsafeMutablePointer<UInt8>) -> Void
        ) throws -> Data {
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            rgba.withUnsafeMutableBufferPointer { buffer in
                fillPixels(buffer.baseAddress!)
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("png-create-\(UUID().uuidString).png")

            var image = png_image()
            image.version = UInt32(PNG_IMAGE_VERSION)
            image.width = UInt32(width)
            image.height = UInt32(height)
            // PNG_FORMAT_RGBA = 6 (PNG_FORMAT_FLAG_COLOR | PNG_FORMAT_FLAG_ALPHA)
            image.format = 6

            let writeSuccess = rgba.withUnsafeBytes { rgbaPtr -> Int32 in
                tempURL.path.withCString { pathPtr in
                    png_image_write_to_file(&image, pathPtr, 0, rgbaPtr.baseAddress, 0, nil)
                }
            }

            guard writeSuccess != 0 else {
                png_image_free(&image)
                throw WebpConverterError.encodingFailed(file: "test", reason: "Failed to write PNG with libpng")
            }

            // Note: png_image_write_to_file frees the image on success
            // Do NOT call png_image_free here to avoid double-free

            let data = try Data(contentsOf: tempURL)
            try? FileManager.default.removeItem(at: tempURL)

            return data
        }
    #endif

    private func verifyWebPMagic(_ data: [UInt8]) {
        XCTAssertGreaterThan(data.count, 12, "WebP data too small")
        XCTAssertEqual(data[0], 0x52, "Expected 'R'")
        XCTAssertEqual(data[1], 0x49, "Expected 'I'")
        XCTAssertEqual(data[2], 0x46, "Expected 'F'")
        XCTAssertEqual(data[3], 0x46, "Expected 'F'")
        XCTAssertEqual(data[8], 0x57, "Expected 'W'")
        XCTAssertEqual(data[9], 0x45, "Expected 'E'")
        XCTAssertEqual(data[10], 0x42, "Expected 'B'")
        XCTAssertEqual(data[11], 0x50, "Expected 'P'")
    }
}
