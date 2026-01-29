@testable import ExFig
import XCTest

final class ConfigDiscoveryTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConfigDiscoveryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - Directory Scanning Tests

    func testDiscoverYamlFilesInDirectory() throws {
        // Given: A directory with multiple YAML files
        try createConfigFile(name: "ios-app.yaml")
        try createConfigFile(name: "android-app.yaml")
        try createConfigFile(name: "web-app.yaml")

        // When: Discovering configs
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)

        // Then: All YAML files are found
        XCTAssertEqual(configs.count, 3)
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "ios-app.yaml" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "android-app.yaml" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "web-app.yaml" })
    }

    func testDiscoverOnlyYamlFiles() throws {
        // Given: A directory with mixed file types
        try createConfigFile(name: "valid.yaml")
        try createConfigFile(name: "also-valid.yml")
        try createFile(name: "readme.md", content: "# README")
        try createFile(name: "config.json", content: "{}")

        // When: Discovering configs
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)

        // Then: Only YAML files are found
        XCTAssertEqual(configs.count, 2)
        XCTAssertTrue(configs.allSatisfy { $0.pathExtension == "yaml" || $0.pathExtension == "yml" })
    }

    func testDiscoverEmptyDirectory() throws {
        // Given: An empty directory

        // When: Discovering configs
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)

        // Then: No configs found
        XCTAssertTrue(configs.isEmpty)
    }

    func testDiscoverNonExistentDirectory() throws {
        // Given: A non-existent directory
        let nonExistent = tempDirectory.appendingPathComponent("does-not-exist")

        // When/Then: Discovering configs throws error
        let discovery = ConfigDiscovery()
        XCTAssertThrowsError(try discovery.discoverConfigs(in: nonExistent)) { error in
            guard let discoveryError = error as? ConfigDiscoveryError else {
                XCTFail("Expected ConfigDiscoveryError, got \(error)")
                return
            }
            if case .directoryNotFound = discoveryError {
                // Expected
            } else {
                XCTFail("Expected directoryNotFound, got \(discoveryError)")
            }
        }
    }

    // MARK: - Config Validation Tests

    func testFilterValidExFigConfigs() throws {
        // Given: A directory with valid and invalid configs
        try createConfigFile(name: "valid-exfig.yaml")
        try createFile(name: "invalid.yaml", content: "not_a_config: true")
        try createFile(name: "empty.yaml", content: "")

        // When: Discovering and filtering configs
        let discovery = ConfigDiscovery()
        let allConfigs = try discovery.discoverConfigs(in: tempDirectory)
        let validConfigs = discovery.filterValidConfigs(allConfigs)

        // Then: Only valid configs pass
        XCTAssertEqual(validConfigs.count, 1)
        XCTAssertEqual(validConfigs.first?.lastPathComponent, "valid-exfig.yaml")
    }

    func testValidateConfigWithFigmaSection() throws {
        // Given: A YAML file with figma section
        try createConfigFile(name: "with-figma.yaml")

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("with-figma.yaml")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid
        XCTAssertTrue(isValid)
    }

    func testValidateConfigWithoutFigmaSection() throws {
        // Given: A YAML file without figma section
        try createFile(name: "no-figma.yaml", content: """
        ios:
          target: MyApp
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("no-figma.yaml")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is invalid
        XCTAssertFalse(isValid)
    }

    func testValidateConfigWithVariablesColors() throws {
        // Given: A YAML file with common.variablesColors (Variables API)
        try createFile(name: "variables-colors.yaml", content: """
        common:
          variablesColors:
            tokensFileId: "abc123"
            tokensCollectionName: "Colors"
            lightModeName: "Light"
            darkModeName: "Dark"
        ios:
          colors:
            output: "Colors.swift"
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("variables-colors.yaml")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid (Variables API doesn't require figma section)
        XCTAssertTrue(isValid)
    }

    func testValidateConfigWithPlatformColors() throws {
        // Given: A YAML file with platform-specific colors but no figma section
        try createFile(name: "platform-colors.yaml", content: """
        ios:
          colors:
            output: "Colors.swift"
            entries:
              - variablesColors:
                  tokensFileId: "abc123"
                  tokensCollectionName: "Colors"
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("platform-colors.yaml")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid (multi-entry colors doesn't require figma section)
        XCTAssertTrue(isValid)
    }

    // MARK: - Output Path Conflict Detection Tests

    func testDetectOutputPathConflicts() throws {
        // Given: Two configs with overlapping output paths
        let config1 = try createConfigFileAndReturnURL(
            name: "app1.yaml",
            iosXcassetsPath: "./Resources/Assets.xcassets"
        )
        let config2 = try createConfigFileAndReturnURL(
            name: "app2.yaml",
            iosXcassetsPath: "./Resources/Assets.xcassets"
        )

        // When: Checking for conflicts
        let discovery = ConfigDiscovery()
        let conflicts = try discovery.detectOutputPathConflicts([config1, config2])

        // Then: Conflict is detected
        XCTAssertFalse(conflicts.isEmpty)
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.configs.count, 2)
    }

    func testNoConflictsWithDifferentOutputPaths() throws {
        // Given: Two configs with different output paths
        let config1 = try createConfigFileAndReturnURL(
            name: "app1.yaml",
            iosXcassetsPath: "./App1/Resources/Assets.xcassets"
        )
        let config2 = try createConfigFileAndReturnURL(
            name: "app2.yaml",
            iosXcassetsPath: "./App2/Resources/Assets.xcassets"
        )

        // When: Checking for conflicts
        let discovery = ConfigDiscovery()
        let conflicts = try discovery.detectOutputPathConflicts([config1, config2])

        // Then: No conflicts
        XCTAssertTrue(conflicts.isEmpty)
    }

    // MARK: - Explicit File List Tests

    func testDiscoverFromExplicitFileList() throws {
        // Given: Specific config files
        try createConfigFile(name: "config1.yaml")
        try createConfigFile(name: "config2.yaml")
        try createConfigFile(name: "config3.yaml")

        let urls = [
            tempDirectory.appendingPathComponent("config1.yaml"),
            tempDirectory.appendingPathComponent("config3.yaml"),
        ]

        // When: Discovering from file list
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(from: urls)

        // Then: Only specified files are returned
        XCTAssertEqual(configs.count, 2)
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "config1.yaml" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "config3.yaml" })
        XCTAssertFalse(configs.contains { $0.lastPathComponent == "config2.yaml" })
    }

    func testDiscoverFromMixedValidAndInvalidPaths() throws {
        // Given: Some existing and non-existing files
        try createConfigFile(name: "exists.yaml")
        let existingURL = tempDirectory.appendingPathComponent("exists.yaml")
        let nonExistingURL = tempDirectory.appendingPathComponent("does-not-exist.yaml")

        // When/Then: Throws error for non-existing file
        let discovery = ConfigDiscovery()
        XCTAssertThrowsError(try discovery.discoverConfigs(from: [existingURL, nonExistingURL])) { error in
            guard let discoveryError = error as? ConfigDiscoveryError else {
                XCTFail("Expected ConfigDiscoveryError, got \(error)")
                return
            }
            if case .fileNotFound = discoveryError {
                // Expected
            } else {
                XCTFail("Expected fileNotFound, got \(discoveryError)")
            }
        }
    }

    // MARK: - Helper Methods

    private func createConfigFile(name: String) throws {
        let content = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./MyApp.xcodeproj"
          target: "MyApp"
          xcassetsPath: "./Resources/Assets.xcassets"
          xcassetsInMainBundle: true
        """
        try createFile(name: name, content: content)
    }

    private func createConfigFileAndReturnURL(name: String, iosXcassetsPath: String) throws -> URL {
        let content = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "./MyApp.xcodeproj"
          target: "MyApp"
          xcassetsPath: "\(iosXcassetsPath)"
          xcassetsInMainBundle: true
        """
        try createFile(name: name, content: content)
        return tempDirectory.appendingPathComponent(name)
    }

    private func createFile(name: String, content: String) throws {
        let url = tempDirectory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
