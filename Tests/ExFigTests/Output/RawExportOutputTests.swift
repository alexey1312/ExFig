import CustomDump
@testable import ExFigCLI
import FigmaAPI
import Foundation
import XCTest

final class RawExportOutputTests: XCTestCase {
    // MARK: - Metadata

    func testMetadataContainsSourceInfo() {
        let metadata = RawExportMetadata(
            name: "Design System",
            fileId: "abc123",
            exfigVersion: "1.0.0"
        )

        XCTAssertEqual(metadata.name, "Design System")
        XCTAssertEqual(metadata.fileId, "abc123")
        XCTAssertEqual(metadata.exfigVersion, "1.0.0")
        XCTAssertNotNil(metadata.exportedAt)
    }

    func testMetadataEncodesToJSON() throws {
        let metadata = RawExportMetadata(
            name: "Design System",
            fileId: "abc123",
            exfigVersion: "1.0.0"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(metadata)
        let json = String(data: data, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"fileId\":\"abc123\"") ?? false)
        XCTAssertTrue(json?.contains("\"name\":\"Design System\"") ?? false)
        XCTAssertTrue(json?.contains("\"exfigVersion\":\"1.0.0\"") ?? false)
        XCTAssertTrue(json?.contains("\"exportedAt\"") ?? false)
    }

    // MARK: - RawExportOutput

    func testRawExportOutputStructure() {
        let metadata = RawExportMetadata(
            name: "Test File",
            fileId: "test123",
            exfigVersion: "2.0.0"
        )

        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light")],
            variables: [("1", "primary", ["1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0)])]
        )

        let output = RawExportOutput(
            source: metadata,
            data: variablesMeta
        )

        XCTAssertEqual(output.source.fileId, "test123")
        XCTAssertNotNil(output.data)
    }

    func testRawExportOutputEncodesToJSON() throws {
        let metadata = RawExportMetadata(
            name: "Test File",
            fileId: "test123",
            exfigVersion: "2.0.0"
        )

        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light")],
            variables: [("1", "primary", ["1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0)])]
        )

        let output = RawExportOutput(
            source: metadata,
            data: variablesMeta
        )

        let exporter = RawExporter()
        let jsonData = try exporter.serialize(output, compact: false)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("\"source\"") ?? false)
        XCTAssertTrue(jsonString?.contains("\"data\"") ?? false)
        XCTAssertTrue(jsonString?.contains("\"fileId\"") ?? false)
    }

    func testRawExportOutputCompactSerialization() throws {
        let metadata = RawExportMetadata(
            name: "Test File",
            fileId: "test123",
            exfigVersion: "2.0.0"
        )

        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light")],
            variables: [("1", "primary", ["1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0)])]
        )

        let output = RawExportOutput(
            source: metadata,
            data: variablesMeta
        )

        let exporter = RawExporter()
        let jsonData = try exporter.serialize(output, compact: true)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        // Compact JSON should not have indentation/newlines (except escaped ones)
        let lineCount = jsonString?.components(separatedBy: "\n").count ?? 0
        XCTAssertEqual(lineCount, 1, "Compact JSON should be single line")
    }

    // MARK: - Date Formatting

    func testExportedAtUsesISO8601Format() {
        let metadata = RawExportMetadata(
            name: "Test",
            fileId: "test",
            exfigVersion: "1.0"
        )

        // ISO 8601 format check
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: metadata.exportedAt))
    }
}
