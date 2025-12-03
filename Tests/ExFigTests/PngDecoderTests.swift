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

final class PngDecoderTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PngDecoderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Valid PNG Tests

    func testDecodeValidPNG() throws {
        // Create a 2x2 test PNG
        let pngURL = try createTestPNG(width: 2, height: 2, color: (255, 0, 0, 255))

        let decoder = PngDecoder()
        let result = try decoder.decode(file: pngURL)

        XCTAssertEqual(result.width, 2)
        XCTAssertEqual(result.height, 2)
        XCTAssertEqual(result.rgba.count, 2 * 2 * 4)
    }

    func testDecodeExtractsCorrectDimensions() throws {
        let pngURL = try createTestPNG(width: 10, height: 5, color: (0, 255, 0, 255))

        let decoder = PngDecoder()
        let result = try decoder.decode(file: pngURL)

        XCTAssertEqual(result.width, 10)
        XCTAssertEqual(result.height, 5)
        XCTAssertEqual(result.byteCount, 10 * 5 * 4)
    }

    func testDecodePreservesColorValues() throws {
        // Create a solid red PNG
        let pngURL = try createTestPNG(width: 1, height: 1, color: (255, 0, 0, 255))

        let decoder = PngDecoder()
        let result = try decoder.decode(file: pngURL)

        // First pixel should be red (RGBA)
        XCTAssertEqual(result.rgba[0], 255, "Red channel")
        XCTAssertEqual(result.rgba[1], 0, "Green channel")
        XCTAssertEqual(result.rgba[2], 0, "Blue channel")
        XCTAssertEqual(result.rgba[3], 255, "Alpha channel")
    }

    func testDecodePNGWithAlpha() throws {
        // Create a semi-transparent PNG
        let pngURL = try createTestPNG(width: 1, height: 1, color: (255, 0, 0, 128))

        let decoder = PngDecoder()
        let result = try decoder.decode(file: pngURL)

        XCTAssertEqual(result.rgba[3], 128, "Alpha should be preserved")
    }

    func testDecodePNGWithoutAlpha() throws {
        // Create an opaque PNG (alpha = 255)
        let pngURL = try createTestPNG(width: 1, height: 1, color: (0, 128, 255, 255))

        let decoder = PngDecoder()
        let result = try decoder.decode(file: pngURL)

        XCTAssertEqual(result.rgba[3], 255, "Opaque alpha should be 255")
    }

    // MARK: - Error Handling Tests

    func testDecodeThrowsForMissingFile() {
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.png")

        let decoder = PngDecoder()
        XCTAssertThrowsError(try decoder.decode(file: nonExistentURL)) { error in
            guard let pngError = error as? PngDecoderError else {
                XCTFail("Expected PngDecoderError")
                return
            }
            if case let .fileNotFound(path) = pngError {
                XCTAssertTrue(path.contains("nonexistent.png"))
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testDecodeThrowsForInvalidData() throws {
        // Create a file with invalid data (not PNG)
        let invalidURL = tempDirectory.appendingPathComponent("invalid.png")
        try Data("not a png file".utf8).write(to: invalidURL)

        let decoder = PngDecoder()
        XCTAssertThrowsError(try decoder.decode(file: invalidURL)) { error in
            guard let pngError = error as? PngDecoderError else {
                XCTFail("Expected PngDecoderError")
                return
            }
            XCTAssertEqual(pngError, .invalidFormat)
        }
    }

    func testDecodeThrowsForCorruptedPNG() throws {
        // Create a file with PNG magic bytes but corrupted content
        let corruptedURL = tempDirectory.appendingPathComponent("corrupted.png")
        var data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG magic
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Invalid chunk
        try data.write(to: corruptedURL)

        let decoder = PngDecoder()
        XCTAssertThrowsError(try decoder.decode(file: corruptedURL)) { error in
            guard let pngError = error as? PngDecoderError else {
                XCTFail("Expected PngDecoderError, got: \(error)")
                return
            }
            // Should be either invalidFormat or decodingFailed
            switch pngError {
            case .invalidFormat, .decodingFailed:
                break // Expected
            case .fileNotFound:
                XCTFail("Expected invalidFormat or decodingFailed")
            }
        }
    }

    func testDecodeFromData() throws {
        // Create PNG data
        let pngData = try createTestPNGData(width: 3, height: 3, color: (0, 255, 0, 255))

        let decoder = PngDecoder()
        let result = try decoder.decode(data: pngData)

        XCTAssertEqual(result.width, 3)
        XCTAssertEqual(result.height, 3)
        XCTAssertEqual(result.rgba.count, 3 * 3 * 4)
    }

    func testDecodeFromDataThrowsForEmptyData() {
        let decoder = PngDecoder()
        XCTAssertThrowsError(try decoder.decode(data: Data())) { error in
            guard let pngError = error as? PngDecoderError else {
                XCTFail("Expected PngDecoderError")
                return
            }
            XCTAssertEqual(pngError, .invalidFormat)
        }
    }

    // MARK: - Helpers

    #if canImport(CoreGraphics) && canImport(ImageIO)
        private func createTestPNG(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8)
        ) throws -> URL {
            let data = try createTestPNGData(width: width, height: height, color: color)
            let url = tempDirectory.appendingPathComponent("test-\(UUID().uuidString).png")
            try data.write(to: url)
            return url
        }

        private func createTestPNGData(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8)
        ) throws -> Data {
            let bytesPerRow = width * 4
            var rgba = [UInt8](repeating: 0, count: width * height * 4)

            // Fill with color
            for i in 0 ..< (width * height) {
                rgba[i * 4] = color.0
                rgba[i * 4 + 1] = color.1
                rgba[i * 4 + 2] = color.2
                rgba[i * 4 + 3] = color.3
            }

            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
                throw PngDecoderError.decodingFailed(reason: "Failed to create color space")
            }

            guard let context = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else {
                throw PngDecoderError.decodingFailed(reason: "Failed to create context")
            }

            guard let cgImage = context.makeImage() else {
                throw PngDecoderError.decodingFailed(reason: "Failed to create CGImage")
            }

            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                "public.png" as CFString,
                1,
                nil
            ) else {
                throw PngDecoderError.decodingFailed(reason: "Failed to create destination")
            }

            CGImageDestinationAddImage(destination, cgImage, nil)

            guard CGImageDestinationFinalize(destination) else {
                throw PngDecoderError.decodingFailed(reason: "Failed to finalize")
            }

            return data as Data
        }
    #else
        /// Creates a test PNG file using libpng (Linux)
        private func createTestPNG(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8)
        ) throws -> URL {
            let data = try createTestPNGData(width: width, height: height, color: color)
            let url = tempDirectory.appendingPathComponent("test-\(UUID().uuidString).png")
            try data.write(to: url)
            return url
        }

        /// Creates PNG data using libpng simplified API (Linux)
        private func createTestPNGData(
            width: Int,
            height: Int,
            color: (UInt8, UInt8, UInt8, UInt8)
        ) throws -> Data {
            // Create RGBA pixel buffer
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            for i in 0 ..< (width * height) {
                rgba[i * 4] = color.0
                rgba[i * 4 + 1] = color.1
                rgba[i * 4 + 2] = color.2
                rgba[i * 4 + 3] = color.3
            }

            // Write to temporary file using libpng
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("png-create-\(UUID().uuidString).png")

            var image = png_image()
            image.version = UInt32(PNG_IMAGE_VERSION)
            image.width = UInt32(width)
            image.height = UInt32(height)
            image.format = UInt32(PNG_FORMAT_RGBA)

            let writeSuccess = rgba.withUnsafeBytes { rgbaPtr -> Int32 in
                tempURL.path.withCString { pathPtr in
                    png_image_write_to_file(&image, pathPtr, 0, rgbaPtr.baseAddress, 0, nil)
                }
            }

            guard writeSuccess != 0 else {
                png_image_free(&image)
                throw PngDecoderError.decodingFailed(reason: "Failed to write test PNG")
            }

            png_image_free(&image)

            // Read back as Data
            let data = try Data(contentsOf: tempURL)
            try? FileManager.default.removeItem(at: tempURL)

            return data
        }
    #endif
}
