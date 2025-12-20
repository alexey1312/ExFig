@testable import ExFig
import Foundation
import XCTest

final class NativeHeicEncoderTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NativeHeicEncoderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithDefaultQuality() {
        let encoder = NativeHeicEncoder()
        XCTAssertEqual(encoder.quality, 90)
        XCTAssertFalse(encoder.lossless)
    }

    func testInitWithCustomQuality() {
        let encoder = NativeHeicEncoder(quality: 50, lossless: false)
        XCTAssertEqual(encoder.quality, 50)
        XCTAssertFalse(encoder.lossless)
    }

    func testInitWithLossless() {
        let encoder = NativeHeicEncoder(quality: 50, lossless: true)
        XCTAssertTrue(encoder.lossless)
    }

    func testInitClampsTooHighQuality() {
        let encoder = NativeHeicEncoder(quality: 150)
        XCTAssertEqual(encoder.quality, 100)
    }

    func testInitClampsTooLowQuality() {
        let encoder = NativeHeicEncoder(quality: -10)
        XCTAssertEqual(encoder.quality, 0)
    }

    // MARK: - Platform Availability

    func testIsAvailableOnMacOS() {
        #if os(macOS)
            // Should be available on macOS 10.13.4+
            if #available(macOS 10.13.4, *) {
                XCTAssertTrue(NativeHeicEncoder.isAvailable())
            } else {
                XCTAssertFalse(NativeHeicEncoder.isAvailable())
            }
        #else
            XCTAssertFalse(NativeHeicEncoder.isAvailable())
        #endif
    }

    // MARK: - Encoding Tests

    func testEncodeLossy() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder(quality: 80, lossless: false)
        let rgba = createSolidColorRGBA(width: 10, height: 10, r: 0, g: 255, b: 0, a: 255)

        let heicData = try encoder.encode(rgba: rgba, width: 10, height: 10)

        // Verify HEIC file starts with ftyp box
        verifyHeicMagic([UInt8](heicData))
    }

    func testEncodeLossless() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder(lossless: true)
        let rgba = createSolidColorRGBA(width: 4, height: 4, r: 255, g: 0, b: 0, a: 255)

        let heicData = try encoder.encode(rgba: rgba, width: 4, height: 4)

        // Verify HEIC file structure
        XCTAssertGreaterThan(heicData.count, 12)
    }

    func testEncodeVariousDimensions() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder(quality: 80)

        // Note: HEIC requires even dimensions, so test with various even sizes
        let dimensions = [(2, 2), (10, 10), (100, 50), (50, 100)]

        for (width, height) in dimensions {
            let rgba = createSolidColorRGBA(width: width, height: height, r: 128, g: 128, b: 128, a: 255)
            let heicData = try encoder.encode(rgba: rgba, width: width, height: height)
            XCTAssertGreaterThan(heicData.count, 0, "Empty HEIC data for \(width)x\(height)")
        }
    }

    func testEncodeOddDimensionsPads() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder(quality: 80)
        // Odd dimensions should be padded to even
        let rgba = createSolidColorRGBA(width: 3, height: 5, r: 255, g: 0, b: 0, a: 255)

        let heicData = try encoder.encode(rgba: rgba, width: 3, height: 5)
        XCTAssertGreaterThan(heicData.count, 0)
    }

    // MARK: - File Output Tests

    func testEncodeToFile() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder(quality: 80)
        let rgba = createSolidColorRGBA(width: 4, height: 4, r: 0, g: 0, b: 255, a: 255)

        let outputURL = tempDirectory.appendingPathComponent("output.heic")
        try encoder.encode(rgba: rgba, width: 4, height: 4, to: outputURL)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        let savedData = try Data(contentsOf: outputURL)
        XCTAssertGreaterThan(savedData.count, 0)
    }

    // MARK: - Error Handling Tests

    func testEncodeThrowsForZeroWidth() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder()
        let rgba = [UInt8](repeating: 255, count: 4)

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 0, height: 1)) { error in
            guard let heicError = error as? NativeHeicEncoderError else {
                XCTFail("Expected NativeHeicEncoderError")
                return
            }
            XCTAssertEqual(heicError, .invalidDimensions)
        }
    }

    func testEncodeThrowsForZeroHeight() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder()
        let rgba = [UInt8](repeating: 255, count: 4)

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 1, height: 0)) { error in
            guard let heicError = error as? NativeHeicEncoderError else {
                XCTFail("Expected NativeHeicEncoderError")
                return
            }
            XCTAssertEqual(heicError, .invalidDimensions)
        }
    }

    func testEncodeThrowsForInvalidRgbaSize() throws {
        #if !os(macOS)
            throw XCTSkip("HEIC encoding is only available on macOS")
        #endif

        guard NativeHeicEncoder.isAvailable() else {
            throw XCTSkip("HEIC encoding not available on this macOS version")
        }

        let encoder = NativeHeicEncoder()
        let rgba = [UInt8](repeating: 255, count: 10) // Should be 4 bytes for 1x1

        XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 1, height: 1)) { error in
            guard let heicError = error as? NativeHeicEncoderError else {
                XCTFail("Expected NativeHeicEncoderError")
                return
            }
            if case let .invalidRgbaData(expected, actual) = heicError {
                XCTAssertEqual(expected, 4)
                XCTAssertEqual(actual, 10)
            } else {
                XCTFail("Expected invalidRgbaData error")
            }
        }
    }

    func testPlatformNotSupported() throws {
        #if os(macOS)
            // Can't easily test this on macOS - platform is available
            throw XCTSkip("Cannot test platform not supported on macOS")
        #else
            let encoder = NativeHeicEncoder()
            let rgba = createSolidColorRGBA(width: 2, height: 2, r: 255, g: 0, b: 0, a: 255)

            XCTAssertThrowsError(try encoder.encode(rgba: rgba, width: 2, height: 2)) { error in
                guard let heicError = error as? NativeHeicEncoderError else {
                    XCTFail("Expected NativeHeicEncoderError")
                    return
                }
                XCTAssertEqual(heicError, .platformNotSupported)
            }
        #endif
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

    private func verifyHeicMagic(_ data: [UInt8]) {
        // HEIC files start with ftyp box
        // Format: [4 bytes size][4 bytes 'ftyp'][brand]...
        XCTAssertGreaterThan(data.count, 12, "HEIC data too small")
        // ftyp signature at bytes 4-7
        XCTAssertEqual(data[4], 0x66, "Expected 'f'") // f
        XCTAssertEqual(data[5], 0x74, "Expected 't'") // t
        XCTAssertEqual(data[6], 0x79, "Expected 'y'") // y
        XCTAssertEqual(data[7], 0x70, "Expected 'p'") // p
    }
}
