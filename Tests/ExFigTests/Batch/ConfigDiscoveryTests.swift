@testable import ExFigCLI
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

    func testDiscoverPklFilesInDirectory() throws {
        // Given: A directory with multiple PKL files
        try createConfigFile(name: "ios-app.pkl")
        try createConfigFile(name: "android-app.pkl")
        try createConfigFile(name: "web-app.pkl")

        // When: Discovering configs
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)

        // Then: All PKL files are found
        XCTAssertEqual(configs.count, 3)
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "ios-app.pkl" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "android-app.pkl" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "web-app.pkl" })
    }

    func testDiscoverOnlyPklFiles() throws {
        // Given: A directory with mixed file types
        try createConfigFile(name: "valid.pkl")
        try createConfigFile(name: "also-valid.pkl")
        try createFile(name: "readme.md", content: "# README")
        try createFile(name: "config.json", content: "{}")
        try createFile(name: "old-config.yaml", content: "figma: {}")

        // When: Discovering configs
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)

        // Then: Only PKL files are found
        XCTAssertEqual(configs.count, 2)
        XCTAssertTrue(configs.allSatisfy { $0.pathExtension == "pkl" })
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
        try createConfigFile(name: "valid-exfig.pkl")
        try createFile(name: "invalid.pkl", content: "not_a_config = true")
        try createFile(name: "empty.pkl", content: "")

        // When: Discovering and filtering configs
        let discovery = ConfigDiscovery()
        let allConfigs = try discovery.discoverConfigs(in: tempDirectory)
        let validConfigs = discovery.filterValidConfigs(allConfigs)

        // Then: Only valid configs pass
        XCTAssertEqual(validConfigs.count, 1)
        XCTAssertEqual(validConfigs.first?.lastPathComponent, "valid-exfig.pkl")
    }

    func testValidateConfigWithExFigAmends() throws {
        // Given: A PKL file that amends ExFig
        try createConfigFile(name: "with-exfig.pkl")

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("with-exfig.pkl")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid
        XCTAssertTrue(isValid)
    }

    func testValidateConfigWithoutExFigAmends() throws {
        // Given: A PKL file without ExFig amends
        try createFile(name: "no-exfig.pkl", content: """
        name = "something else"
        value = 123
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("no-exfig.pkl")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is invalid
        XCTAssertFalse(isValid)
    }

    func testValidateConfigWithPlatformSection() throws {
        // Given: A PKL file with ios section (platform indicator)
        try createFile(name: "ios-platform.pkl", content: """
        ios {
          xcodeprojPath = "./MyApp.xcodeproj"
        }
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("ios-platform.pkl")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid (has platform section)
        XCTAssertTrue(isValid)
    }

    func testValidateConfigWithAndroidSection() throws {
        // Given: A PKL file with android section
        try createFile(name: "android-platform.pkl", content: """
        android {
          mainRes = "./app/src/main/res"
        }
        """)

        // When: Validating
        let discovery = ConfigDiscovery()
        let url = tempDirectory.appendingPathComponent("android-platform.pkl")
        let isValid = discovery.isValidExFigConfig(at: url)

        // Then: Config is valid
        XCTAssertTrue(isValid)
    }

    // MARK: - Output Path Conflict Detection Tests

    func testDetectOutputPathConflicts() throws {
        // Given: Two configs with overlapping output paths
        let config1 = try createConfigFileAndReturnURL(
            name: "app1.pkl",
            iosXcassetsPath: "./Resources/Assets.xcassets"
        )
        let config2 = try createConfigFileAndReturnURL(
            name: "app2.pkl",
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
            name: "app1.pkl",
            iosXcassetsPath: "./App1/Resources/Assets.xcassets"
        )
        let config2 = try createConfigFileAndReturnURL(
            name: "app2.pkl",
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
        try createConfigFile(name: "config1.pkl")
        try createConfigFile(name: "config2.pkl")
        try createConfigFile(name: "config3.pkl")

        let urls = [
            tempDirectory.appendingPathComponent("config1.pkl"),
            tempDirectory.appendingPathComponent("config3.pkl"),
        ]

        // When: Discovering from file list
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(from: urls)

        // Then: Only specified files are returned
        XCTAssertEqual(configs.count, 2)
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "config1.pkl" })
        XCTAssertTrue(configs.contains { $0.lastPathComponent == "config3.pkl" })
        XCTAssertFalse(configs.contains { $0.lastPathComponent == "config2.pkl" })
    }

    func testDiscoverFromMixedValidAndInvalidPaths() throws {
        // Given: Some existing and non-existing files
        try createConfigFile(name: "exists.pkl")
        let existingURL = tempDirectory.appendingPathComponent("exists.pkl")
        let nonExistingURL = tempDirectory.appendingPathComponent("does-not-exist.pkl")

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
        amends ".exfig/schemas/ExFig.pkl"

        figma {
          lightFileId = "abc123"
        }
        ios {
          xcodeprojPath = "./MyApp.xcodeproj"
          target = "MyApp"
          xcassetsPath = "./Resources/Assets.xcassets"
          xcassetsInMainBundle = true
        }
        """
        try createFile(name: name, content: content)
    }

    private func createConfigFileAndReturnURL(name: String, iosXcassetsPath: String) throws -> URL {
        let content = """
        amends ".exfig/schemas/ExFig.pkl"

        figma {
          lightFileId = "abc123"
        }
        ios {
          xcodeprojPath = "./MyApp.xcodeproj"
          target = "MyApp"
          xcassetsPath = "\(iosXcassetsPath)"
          xcassetsInMainBundle = true
        }
        """
        try createFile(name: name, content: content)
        return tempDirectory.appendingPathComponent(name)
    }

    private func createFile(name: String, content: String) throws {
        let url = tempDirectory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
