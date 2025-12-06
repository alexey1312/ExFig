import Foundation
@testable import SVGKit
import XCTest

final class NativeVectorDrawableConverterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    // MARK: - Single File Conversion Tests

    func testConvertSingleSVGFile() throws {
        // Create a simple SVG file
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("icon.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        // Convert
        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        // Verify XML file was created
        let xmlFile = tempDirectory.appendingPathComponent("icon.xml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: xmlFile.path))

        // Verify content
        let xmlContent = try String(contentsOf: xmlFile, encoding: .utf8)
        XCTAssertTrue(xmlContent.contains("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        XCTAssertTrue(xmlContent.contains("<vector"))
        XCTAssertTrue(xmlContent.contains("android:pathData=\"M12,4 L12,20\""))
    }

    func testConvertSingleSVGFileRemovesOriginal() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" fill="#FF0000"/>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("test.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        // SVG file should be removed
        XCTAssertFalse(FileManager.default.fileExists(atPath: svgFile.path))

        // XML file should exist
        let xmlFile = tempDirectory.appendingPathComponent("test.xml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: xmlFile.path))
    }

    func testConvertSVGWithGroups() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10, 10)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("grouped.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        let xmlFile = tempDirectory.appendingPathComponent("grouped.xml")
        let xmlContent = try String(contentsOf: xmlFile, encoding: .utf8)

        XCTAssertTrue(xmlContent.contains("<group"))
        XCTAssertTrue(xmlContent.contains("android:translateX=\"10\""))
        XCTAssertTrue(xmlContent.contains("android:translateY=\"10\""))
    }

    func testConvertSVGWithAutoMirrored() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M4,12 L20,12" fill="#000000"/>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("arrow.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter(autoMirrored: true)
        try converter.convert(inputDirectoryUrl: tempDirectory)

        let xmlFile = tempDirectory.appendingPathComponent("arrow.xml")
        let xmlContent = try String(contentsOf: xmlFile, encoding: .utf8)

        XCTAssertTrue(xmlContent.contains("android:autoMirrored=\"true\""))
    }

    func testConvertWithRTLFiles() throws {
        let svgContent1 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M4,12 L20,12" fill="#000000"/>
        </svg>
        """
        let svgContent2 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """

        try svgContent1.write(
            to: tempDirectory.appendingPathComponent("arrow_right.svg"),
            atomically: true,
            encoding: .utf8
        )
        try svgContent2.write(
            to: tempDirectory.appendingPathComponent("arrow_down.svg"),
            atomically: true,
            encoding: .utf8
        )

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory, rtlFiles: Set(["arrow_right"]))

        // RTL file should have autoMirrored
        let rtlXml = try String(contentsOf: tempDirectory.appendingPathComponent("arrow_right.xml"), encoding: .utf8)
        XCTAssertTrue(rtlXml.contains("android:autoMirrored=\"true\""))

        // Non-RTL file should NOT have autoMirrored
        let normalXml = try String(contentsOf: tempDirectory.appendingPathComponent("arrow_down.xml"), encoding: .utf8)
        XCTAssertFalse(normalXml.contains("android:autoMirrored"))
    }

    // MARK: - Directory Batch Conversion Tests

    func testConvertMultipleSVGFiles() throws {
        let svgContent1 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#FF0000"/>
        </svg>
        """
        let svgContent2 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M4,12 L20,12" fill="#00FF00"/>
        </svg>
        """

        try svgContent1.write(to: tempDirectory.appendingPathComponent("icon1.svg"), atomically: true, encoding: .utf8)
        try svgContent2.write(to: tempDirectory.appendingPathComponent("icon2.svg"), atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        // Both XML files should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon1.xml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon2.xml").path))

        // Both SVG files should be removed
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon1.svg").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon2.svg").path))
    }

    func testConvertIgnoresNonSVGFiles() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" fill="#000000"/>
        </svg>
        """
        let txtContent = "This is a text file"

        try svgContent.write(to: tempDirectory.appendingPathComponent("icon.svg"), atomically: true, encoding: .utf8)
        try txtContent.write(to: tempDirectory.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        // SVG should be converted
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon.xml").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("icon.svg").path))

        // TXT should be untouched
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("readme.txt").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("readme.xml").path))
    }

    func testConvertEmptyDirectory() throws {
        let converter = NativeVectorDrawableConverter()
        // Should not throw for empty directory
        XCTAssertNoThrow(try converter.convert(inputDirectoryUrl: tempDirectory))
    }

    // MARK: - Error Handling Tests

    func testConvertInvalidSVGContinuesProcessing() throws {
        let validSvg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" fill="#000000"/>
        </svg>
        """
        let invalidSvg = "This is not valid SVG content"

        try validSvg.write(to: tempDirectory.appendingPathComponent("valid.svg"), atomically: true, encoding: .utf8)
        try invalidSvg.write(to: tempDirectory.appendingPathComponent("invalid.svg"), atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        // Should not throw - continues processing other files
        XCTAssertNoThrow(try converter.convert(inputDirectoryUrl: tempDirectory))

        // Valid file should be converted
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("valid.xml").path))

        // Invalid SVG file should remain (not converted)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("invalid.svg").path))
    }

    func testConvertMissingDirectoryThrows() {
        let nonExistentUrl = tempDirectory.appendingPathComponent("nonexistent")
        let converter = NativeVectorDrawableConverter()

        XCTAssertThrowsError(try converter.convert(inputDirectoryUrl: nonExistentUrl))
    }

    // MARK: - Feature Tests

    func testConvertPreservesColorWithAlpha() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" fill="rgba(255, 0, 0, 0.5)"/>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("alpha.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        let xmlFile = tempDirectory.appendingPathComponent("alpha.xml")
        let xmlContent = try String(contentsOf: xmlFile, encoding: .utf8)

        // Should contain alpha in AARRGGBB format
        XCTAssertTrue(xmlContent.contains("#") && xmlContent.contains("FF0000"))
    }

    func testConvertPreservesStrokeAttributes() throws {
        let svgContent = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" stroke="#0000FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="bevel"/>
        </svg>
        """
        let svgFile = tempDirectory.appendingPathComponent("stroke.svg")
        try svgContent.write(to: svgFile, atomically: true, encoding: .utf8)

        let converter = NativeVectorDrawableConverter()
        try converter.convert(inputDirectoryUrl: tempDirectory)

        let xmlFile = tempDirectory.appendingPathComponent("stroke.xml")
        let xmlContent = try String(contentsOf: xmlFile, encoding: .utf8)

        XCTAssertTrue(xmlContent.contains("android:strokeColor=\"#0000FF\""))
        XCTAssertTrue(xmlContent.contains("android:strokeWidth=\"2\""))
        XCTAssertTrue(xmlContent.contains("android:strokeLineCap=\"round\""))
        XCTAssertTrue(xmlContent.contains("android:strokeLineJoin=\"bevel\""))
    }
}
