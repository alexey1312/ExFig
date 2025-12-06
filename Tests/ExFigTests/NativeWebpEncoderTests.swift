@testable import ExFig
import Foundation
import XCTest

final class NativeWebpEncoderTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NativeWebpEncoderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithDefaultQuality() {
        let encoder = NativeWebpEncoder()
        XCTAssertEqual(encoder.quality, 80)
        XCTAssertFalse(encoder.lossless)
    }

    func testInitWithCustomQuality() {
        let encoder = NativeWebpEncoder(quality: 50, lossless: false)
        XCTAssertEqual(encoder.quality, 50)
        XCTAssertFalse(encoder.lossless)
    }

    func testInitWithLossless() {
        let encoder = NativeWebpEncoder(quality: 50, lossless: true)
        XCTAssertTrue(encoder.lossless)
    }

    func testInitClampsTooHighQuality() {
        let encoder = NativeWebpEncoder(quality: 150)
        XCTAssertEqual(encoder.quality, 100)
    }

    func testInitClampsTooLowQuality() {
        let encoder = NativeWebpEncoder(quality: -10)
        XCTAssertEqual(encoder.quality, 0)
    }

    // MARK: - Encoding Tests

    func testEncodeLossless() throws {
        let encoder = NativeWebpEncoder(lossless: true)
        let rgba = createSolidColorRGBA(width: 2, height: 2, r: 255, g: 0, b: 0, a: 255)

        let webpData = try encoder.encode(rgba: rgba, width: 2, height: 2)

        // Verify WebP magic bytes (RIFF....WEBP)
        XCTAssertGreaterThan(webpData.count, 12)
        XCTAssertEqual(webpData[0], 0x52) // R
        XCTAssertEqual(webpData[1], 0x49) // I
        XCTAssertEqual(webpData[2], 0x46) // F
        XCTAssertEqual(webpData[3], 0x46) // F
        XCTAssertEqual(webpData[8], 0x57) // W
        XCTAssertEqual(webpData[9], 0x45) // E
        XCTAssertEqual(webpData[10], 0x42) // B
        XCTAssertEqual(webpData[11], 0x50) // P
    }

    func testEncodeLossy() throws {
        let encoder = NativeWebpEncoder(quality: 80, lossless: false)
        let rgba = createSolidColorRGBA(width: 10, height: 10, r: 0, g: 255, b: 0, a: 255)

        let webpData = try encoder.encode(rgba: rgba, width: 10, height: 10)

        // Verify WebP magic bytes
        verifyWebPMagic(webpData)
    }

    func testEncodeDifferentQualitiesProduceDifferentSizes() throws {
        let rgbaData = createCheckerboardRGBA(width: 100, height: 100)

        let lowQualityEncoder = NativeWebpEncoder(quality: 10, lossless: false)
        let highQualityEncoder = NativeWebpEncoder(quality: 100, lossless: false)

        let lowQualityData = try lowQualityEncoder.encode(rgba: rgbaData, width: 100, height: 100)
        let highQualityData = try highQualityEncoder.encode(rgba: rgbaData, width: 100, height: 100)

        // Higher quality should generally produce larger files
        // (Note: This might not always hold for very simple images)
        XCTAssertNotEqual(lowQualityData.count, highQualityData.count)
    }

    func testEncodeVariousDimensions() throws {
        let encoder = NativeWebpEncoder(quality: 80)

        let dimensions = [(1, 1), (10, 10), (100, 50), (50, 100)]

        for (width, height) in dimensions {
            let rgba = createSolidColorRGBA(width: width, height: height, r: 128, g: 128, b: 128, a: 255)

            let webpData = try encoder.encode(rgba: rgba, width: width, height: height)
            verifyWebPMagic(webpData)
        }
    }

    // MARK: - File Output Tests

    func testEncodeToFile() throws {
        let encoder = NativeWebpEncoder(quality: 80)
        let rgba = createSolidColorRGBA(width: 4, height: 4, r: 0, g: 0, b: 255, a: 255)

        let outputURL = tempDirectory.appendingPathComponent("output.webp")
        try encoder.encode(rgba: rgba, width: 4, height: 4, to: outputURL)

        // Verify file exists and has valid WebP content
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        let savedData = try Data(contentsOf: outputURL)
        verifyWebPMagic([UInt8](savedData))
    }

    // MARK: - Error Handling Tests

    func testEncodeThrowsForZeroWidth() {
        let encoder = NativeWebpEncoder()
        let rgba = [UInt8](repeating: 255, count: 4)

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 0, height: 1)) { error in
            guard let webpError = error as? NativeWebpEncoderError else {
                XCTFail("Expected NativeWebpEncoderError")
                return
            }
            XCTAssertEqual(webpError, .invalidDimensions)
        }
    }

    func testEncodeThrowsForZeroHeight() {
        let encoder = NativeWebpEncoder()
        let rgba = [UInt8](repeating: 255, count: 4)

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 1, height: 0)) { error in
            guard let webpError = error as? NativeWebpEncoderError else {
                XCTFail("Expected NativeWebpEncoderError")
                return
            }
            XCTAssertEqual(webpError, .invalidDimensions)
        }
    }

    func testEncodeThrowsForNegativeDimensions() {
        let encoder = NativeWebpEncoder()
        let rgba = [UInt8](repeating: 255, count: 4)

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: -1, height: 1)) { error in
            guard let webpError = error as? NativeWebpEncoderError else {
                XCTFail("Expected NativeWebpEncoderError")
                return
            }
            XCTAssertEqual(webpError, .invalidDimensions)
        }
    }

    func testEncodeThrowsForInvalidRgbaSize() {
        let encoder = NativeWebpEncoder()
        let rgba = [UInt8](repeating: 255, count: 10) // Should be 4 bytes for 1x1

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 1, height: 1)) { error in
            guard let webpError = error as? NativeWebpEncoderError else {
                XCTFail("Expected NativeWebpEncoderError")
                return
            }
            if case let .invalidRgbaData(expected, actual) = webpError {
                XCTAssertEqual(expected, 4)
                XCTAssertEqual(actual, 10)
            } else {
                XCTFail("Expected invalidRgbaData error")
            }
        }
    }

    func testEncodeThrowsForEmptyRgba() {
        let encoder = NativeWebpEncoder()
        let rgba = [UInt8]()

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 1, height: 1)) { error in
            guard let webpError = error as? NativeWebpEncoderError else {
                XCTFail("Expected NativeWebpEncoderError")
                return
            }
            if case let .invalidRgbaData(expected, actual) = webpError {
                XCTAssertEqual(expected, 4)
                XCTAssertEqual(actual, 0)
            } else {
                XCTFail("Expected invalidRgbaData error")
            }
        }
    }

    // MARK: - Helpers

    // swiftlint:disable:next function_parameter_count
    private func createSolidColorRGBA(
        width: Int,
        height: Int,
        r: UInt8,
        g: UInt8,
        b: UInt8,
        a: UInt8
    ) -> [UInt8] {
        var rgba = [UInt8]()
        rgba.reserveCapacity(width * height * 4)

        for _ in 0 ..< (width * height) {
            rgba.append(r)
            rgba.append(g)
            rgba.append(b)
            rgba.append(a)
        }

        return rgba
    }

    private func createCheckerboardRGBA(width: Int, height: Int) -> [UInt8] {
        var rgba = [UInt8]()
        rgba.reserveCapacity(width * height * 4)

        for y in 0 ..< height {
            for x in 0 ..< width {
                let isWhite = (x + y) % 2 == 0
                let color: UInt8 = isWhite ? 255 : 0
                rgba.append(color) // R
                rgba.append(color) // G
                rgba.append(color) // B
                rgba.append(255) // A
            }
        }

        return rgba
    }

    private func verifyWebPMagic(_ data: [UInt8]) {
        XCTAssertGreaterThan(data.count, 12, "WebP data too small")
        XCTAssertEqual(data[0], 0x52, "Expected 'R'") // R
        XCTAssertEqual(data[1], 0x49, "Expected 'I'") // I
        XCTAssertEqual(data[2], 0x46, "Expected 'F'") // F
        XCTAssertEqual(data[3], 0x46, "Expected 'F'") // F
        XCTAssertEqual(data[8], 0x57, "Expected 'W'") // W
        XCTAssertEqual(data[9], 0x45, "Expected 'E'") // E
        XCTAssertEqual(data[10], 0x42, "Expected 'B'") // B
        XCTAssertEqual(data[11], 0x50, "Expected 'P'") // P
    }
}
