@testable import ExFig
import XCTest
import Yams

/// Tests for the Migrate command's YAML transformation logic.
final class MigrateTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MigrateTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - YAML Validation Tests

    func testValidConfigWithFigmaSection() throws {
        let yaml = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        XCTAssertNotNil(parsed?["figma"])
    }

    func testInvalidConfigMissingFigmaSection() throws {
        let yaml = """
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        XCTAssertNil(parsed?["figma"])
    }

    func testInvalidConfigMissingLightFileId() throws {
        let yaml = """
        figma:
          darkFileId: "abc123"
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        let figma = parsed?["figma"] as? [String: Any]
        XCTAssertNil(figma?["lightFileId"])
    }

    // MARK: - Cache Section Detection Tests

    func testHasCacheSectionWhenPresent() throws {
        let yaml = """
        figma:
          lightFileId: "abc123"
        common:
          cache:
            enabled: true
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        let common = parsed?["common"] as? [String: Any]
        XCTAssertNotNil(common?["cache"])
    }

    func testHasCacheSectionWhenAbsent() throws {
        let yaml = """
        figma:
          lightFileId: "abc123"
        common:
          icons:
            format: svg
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        let common = parsed?["common"] as? [String: Any]
        XCTAssertNil(common?["cache"])
    }

    func testNoCacheSectionWithoutCommon() throws {
        let yaml = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """
        let parsed = try Yams.load(yaml: yaml) as? [String: Any]
        XCTAssertNil(parsed?["common"])
    }

    // MARK: - Indentation Detection Tests

    func testDetectTwoSpaceIndentation() {
        let content = """
        figma:
          lightFileId: "abc123"
          darkFileId: "def456"
        """
        let indent = detectIndentation(in: content)
        XCTAssertEqual(indent, "  ")
    }

    func testDetectFourSpaceIndentation() {
        let content = """
        figma:
            lightFileId: "abc123"
            darkFileId: "def456"
        """
        let indent = detectIndentation(in: content)
        XCTAssertEqual(indent, "    ")
    }

    func testDefaultIndentationForNoIndent() {
        let content = """
        figma:
        lightFileId: "abc123"
        """
        let indent = detectIndentation(in: content)
        XCTAssertEqual(indent, "  ") // Default
    }

    // MARK: - Cache Section Insertion Tests

    func testInsertCacheIntoExistingCommon() {
        let content = """
        figma:
          lightFileId: "abc123"
        common:
          icons:
            format: svg
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """

        let result = insertCacheIntoCommon(content: content, indent: "  ")

        // Verify cache section was added
        XCTAssertTrue(result.contains("cache:"))
        XCTAssertTrue(result.contains("enabled: true"))
        XCTAssertTrue(result.contains("path:"))

        // Verify original content preserved
        XCTAssertTrue(result.contains("icons:"))
        XCTAssertTrue(result.contains("format: svg"))
    }

    func testInsertCommonSectionWhenMissing() {
        let content = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """

        let result = insertCommonSection(content: content, indent: "  ")

        // Verify common section was added
        XCTAssertTrue(result.contains("common:"))
        XCTAssertTrue(result.contains("cache:"))
        XCTAssertTrue(result.contains("enabled: true"))

        // Verify original content preserved
        XCTAssertTrue(result.contains("figma:"))
        XCTAssertTrue(result.contains("ios:"))
    }

    func testCacheInsertionPreservesYAMLValidity() throws {
        let content = """
        figma:
          lightFileId: "abc123"
        common:
          icons:
            format: svg
        """

        let result = insertCacheIntoCommon(content: content, indent: "  ")

        // Verify result is valid YAML
        let parsed = try Yams.load(yaml: result) as? [String: Any]
        XCTAssertNotNil(parsed)
        XCTAssertNotNil(parsed?["figma"])
        XCTAssertNotNil(parsed?["common"])

        let common = parsed?["common"] as? [String: Any]
        XCTAssertNotNil(common?["cache"])
    }

    // MARK: - File Operations Tests

    func testMigrateCreatesOutputFile() throws {
        let inputPath = tempDirectory.appendingPathComponent("figma-export.yaml")
        let outputPath = tempDirectory.appendingPathComponent("exfig.yaml")

        let content = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./App.xcodeproj"
        """
        try content.write(to: inputPath, atomically: true, encoding: .utf8)

        // Simulate migration by inserting cache section
        let migrated = insertCommonSection(content: content, indent: "  ")
        try migrated.write(to: outputPath, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))

        let outputContent = try String(contentsOf: outputPath, encoding: .utf8)
        XCTAssertTrue(outputContent.contains("cache:"))
    }

    // MARK: - Private Helper Methods

    /// Detect indentation style from YAML content.
    private func detectIndentation(in content: String) -> String {
        for line in content.components(separatedBy: "\n") {
            let leadingSpaces = line.prefix(while: { $0 == " " })
            if !leadingSpaces.isEmpty, line.trimmingCharacters(in: .whitespaces).contains(":") {
                return String(leadingSpaces)
            }
        }
        return "  "
    }

    /// Insert cache section into existing common section.
    private func insertCacheIntoCommon(content: String, indent: String) -> String {
        let cacheBlock = """
        \(indent)cache:
        \(indent)\(indent)enabled: true
        \(indent)\(indent)path: ".exfig-cache.json"
        """

        let lines = content.components(separatedBy: "\n")
        var result: [String] = []

        for line in lines {
            result.append(line)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("common:") {
                result.append(cacheBlock)
            }
        }

        return result.joined(separator: "\n")
    }

    /// Insert new common section with cache.
    private func insertCommonSection(content: String, indent: String) -> String {
        let cacheBlock = """
        \(indent)cache:
        \(indent)\(indent)enabled: true
        \(indent)\(indent)path: ".exfig-cache.json"
        """

        let lines = content.components(separatedBy: "\n")
        var result: [String] = []
        var afterFigmaSection = false
        var figmaIndentLevel = 0
        var insertedCommon = false

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("figma:") {
                afterFigmaSection = true
                figmaIndentLevel = line.prefix(while: { $0 == " " }).count
                result.append(line)
                continue
            }

            if afterFigmaSection, !insertedCommon {
                let currentIndent = line.prefix(while: { $0 == " " }).count
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if currentIndent <= figmaIndentLevel, !trimmed.isEmpty, !trimmed.hasPrefix("#") {
                    result.append("")
                    result.append("common:")
                    result.append(cacheBlock)
                    result.append("")
                    insertedCommon = true
                    afterFigmaSection = false
                }
            }

            result.append(line)
        }

        if !insertedCommon {
            result.append("")
            result.append("common:")
            result.append(cacheBlock)
        }

        return result.joined(separator: "\n")
    }
}
