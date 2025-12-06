@testable import AndroidExport
import ExFigCore
import Foundation
import XCTest

final class AndroidImageVectorExporterTests: XCTestCase {
    var outputDirectory: URL!

    override func setUp() {
        super.setUp()
        outputDirectory = URL(fileURLWithPath: "/tmp/test-icons")
    }

    override func tearDown() {
        outputDirectory = nil
        super.tearDown()
    }

    // MARK: - Single Export

    func testExportSingleIcon() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            extensionTarget: nil,
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "arrow_down", svgData: svgData)

        XCTAssertEqual(fileContents.destination.file.absoluteString, "ArrowDown.kt")
        XCTAssertEqual(fileContents.destination.directory, outputDirectory)

        let code = String(data: fileContents.data!, encoding: .utf8)!
        XCTAssertTrue(code.contains("package com.example.icons"))
        XCTAssertTrue(code.contains("public val ArrowDown: ImageVector"))
    }

    func testExportSingleIconWithExtensionTarget() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            extensionTarget: "com.example.AppIcons",
            generatePreview: true
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "star", svgData: svgData)
        let code = String(data: fileContents.data!, encoding: .utf8)!

        XCTAssertTrue(code.contains("public val AppIcons.Star: ImageVector"))
        XCTAssertTrue(code.contains("@Preview"))
    }

    // MARK: - Batch Export

    func testExportMultipleIcons() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg1 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """

        let svg2 = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M4,12 L20,12" fill="#000000"/>
        </svg>
        """

        let svgFiles: [String: Data] = [
            "arrow_up": Data(svg1.utf8),
            "arrow_right": Data(svg2.utf8),
        ]

        let files = try exporter.export(svgFiles: svgFiles)

        XCTAssertEqual(files.count, 2)

        let fileNames = files.map(\.destination.file.absoluteString)
        XCTAssertTrue(fileNames.contains("ArrowUp.kt"))
        XCTAssertTrue(fileNames.contains("ArrowRight.kt"))
    }

    // MARK: - Color Mappings

    func testExportWithColorMapping() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            generatePreview: false,
            colorMappings: ["000000": "MaterialTheme.colorScheme.onSurface"]
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "icon", svgData: svgData)
        let code = String(data: fileContents.data!, encoding: .utf8)!

        XCTAssertTrue(code.contains("MaterialTheme.colorScheme.onSurface"))
        XCTAssertFalse(code.contains("Color(0xFF000000)"))
    }

    // MARK: - File Naming

    func testFileNameConversion() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        // Test snake_case
        var file = try exporter.exportSingle(name: "arrow_back_ios", svgData: svgData)
        XCTAssertEqual(file.destination.file.absoluteString, "ArrowBackIos.kt")

        // Test kebab-case
        file = try exporter.exportSingle(name: "arrow-forward-ios", svgData: svgData)
        XCTAssertEqual(file.destination.file.absoluteString, "ArrowForwardIos.kt")

        // Test single word
        file = try exporter.exportSingle(name: "home", svgData: svgData)
        XCTAssertEqual(file.destination.file.absoluteString, "Home.kt")
    }

    // MARK: - SVG Parsing Integration

    func testExportComplexSVG() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        // Material Design checkmark icon
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z" fill="#000000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "check", svgData: svgData)
        let code = String(data: fileContents.data!, encoding: .utf8)!

        XCTAssertTrue(code.contains("moveTo("))
        XCTAssertTrue(code.contains("lineTo("))
        XCTAssertTrue(code.contains("close()"))
    }

    func testExportSVGWithCircle() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10" fill="#FF0000"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "circle", svgData: svgData)
        let code = String(data: fileContents.data!, encoding: .utf8)!

        // Circle is converted to arc commands
        XCTAssertTrue(code.contains("arcTo") || code.contains("arcToRelative"))
        XCTAssertTrue(code.contains("Color(0xFFFF0000)"))
    }

    func testExportSVGWithStrokeProperties() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example.icons",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M4,4 L20,20" fill="none" stroke="#000000" stroke-width="2" \
        stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        """
        let svgData = Data(svg.utf8)

        let fileContents = try exporter.exportSingle(name: "line", svgData: svgData)
        let code = String(data: fileContents.data!, encoding: .utf8)!

        XCTAssertTrue(code.contains("strokeLineWidth = 2f"))
        XCTAssertTrue(code.contains("strokeLineCap = StrokeCap.Round"))
        XCTAssertTrue(code.contains("strokeLineJoin = StrokeJoin.Round"))
    }

    // MARK: - Output Directory

    func testOutputDirectoryIsPreserved() throws {
        let customDir = URL(fileURLWithPath: "/custom/path/to/icons")
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: customDir, config: config)

        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0" fill="#000000"/>
        </svg>
        """

        let file = try exporter.exportSingle(name: "test", svgData: Data(svg.utf8))

        XCTAssertEqual(file.destination.directory, customDir)
    }

    // MARK: - Error Cases

    func testExportInvalidSVG() throws {
        let config = AndroidImageVectorExporter.Config(
            packageName: "com.example",
            generatePreview: false
        )
        let exporter = AndroidImageVectorExporter(outputDirectory: outputDirectory, config: config)

        let invalidSVG = "<html><body>Not an SVG</body></html>"
        let svgData = Data(invalidSVG.utf8)

        XCTAssertThrowsError(try exporter.exportSingle(name: "invalid", svgData: svgData))
    }
}
