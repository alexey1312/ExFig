@testable import ExFig
import XCTest

final class FileIdExtractorTests: XCTestCase {
    private var extractor: FileIdExtractor!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        extractor = FileIdExtractor()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Basic Extraction

    func testExtractsLightFileId() throws {
        let configURL = try createConfig("""
        figma:
          lightFileId: "abc123"
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["abc123"])
    }

    func testExtractsBothLightAndDarkFileIds() throws {
        let configURL = try createConfig("""
        figma:
          lightFileId: "light-id"
          darkFileId: "dark-id"
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["light-id", "dark-id"])
    }

    func testExtractsTokensFileId() throws {
        let configURL = try createConfig("""
        figma:
          lightFileId: "main-file"
        common:
          variablesColors:
            tokensFileId: "tokens-file"
            tokensCollectionName: "Colors"
            lightModeName: "Light"
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["main-file", "tokens-file"])
    }

    // MARK: - Deduplication

    func testDeduplicatesSameFileIdAcrossConfigs() throws {
        let config1 = try createConfig("""
        figma:
          lightFileId: "shared-file"
        """, name: "config1.yaml")

        let config2 = try createConfig("""
        figma:
          lightFileId: "shared-file"
        """, name: "config2.yaml")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.contains("shared-file"))
    }

    func testDeduplicatesWhenDarkSameAsOtherLight() throws {
        let config1 = try createConfig("""
        figma:
          lightFileId: "file-a"
          darkFileId: "file-b"
        """, name: "config1.yaml")

        let config2 = try createConfig("""
        figma:
          lightFileId: "file-b"
        """, name: "config2.yaml")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result, ["file-a", "file-b"])
    }

    // MARK: - Multiple Configs

    func testExtractsFromMultipleConfigs() throws {
        let config1 = try createConfig("""
        figma:
          lightFileId: "file-1"
        """, name: "config1.yaml")

        let config2 = try createConfig("""
        figma:
          lightFileId: "file-2"
          darkFileId: "file-3"
        """, name: "config2.yaml")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result, ["file-1", "file-2", "file-3"])
    }

    // MARK: - Error Handling

    func testReturnsEmptySetForInvalidYaml() throws {
        let configURL = try createConfig("not: valid: yaml: syntax: [", name: "invalid.yaml")

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertTrue(result.isEmpty)
    }

    func testReturnsEmptySetForMissingLightFileId() throws {
        let configURL = try createConfig("""
        figma:
          darkFileId: "only-dark"
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        // lightFileId is required, so parsing should fail
        XCTAssertTrue(result.isEmpty)
    }

    func testReturnsEmptySetForNonexistentFile() {
        let nonexistent = tempDir.appendingPathComponent("nonexistent.yaml")

        let result = extractor.extractUniqueFileIds(from: [nonexistent])

        XCTAssertTrue(result.isEmpty)
    }

    func testSkipsInvalidConfigsButExtractsFromValid() throws {
        let valid = try createConfig("""
        figma:
          lightFileId: "valid-file"
        """, name: "valid.yaml")

        let invalid = try createConfig("invalid: [yaml", name: "invalid.yaml")

        let result = extractor.extractUniqueFileIds(from: [valid, invalid])

        XCTAssertEqual(result, ["valid-file"])
    }

    // MARK: - Empty Input

    func testReturnsEmptySetForEmptyInput() {
        let result = extractor.extractUniqueFileIds(from: [])

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Helpers

    private func createConfig(_ content: String, name: String = "test.yaml") throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
