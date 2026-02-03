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
        figma {
          lightFileId = "abc123"
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["abc123"])
    }

    func testExtractsBothLightAndDarkFileIds() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "light-id"
          darkFileId = "dark-id"
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["light-id", "dark-id"])
    }

    func testExtractsTokensFileId() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "main-file"
        }
        common {
          variablesColors {
            tokensFileId = "tokens-file"
            tokensCollectionName = "Colors"
            lightModeName = "Light"
          }
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result, ["main-file", "tokens-file"])
    }

    // MARK: - Deduplication

    func testDeduplicatesSameFileIdAcrossConfigs() throws {
        let config1 = try createConfig("""
        figma {
          lightFileId = "shared-file"
        }
        """, name: "config1.pkl")

        let config2 = try createConfig("""
        figma {
          lightFileId = "shared-file"
        }
        """, name: "config2.pkl")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.contains("shared-file"))
    }

    func testDeduplicatesWhenDarkSameAsOtherLight() throws {
        let config1 = try createConfig("""
        figma {
          lightFileId = "file-a"
          darkFileId = "file-b"
        }
        """, name: "config1.pkl")

        let config2 = try createConfig("""
        figma {
          lightFileId = "file-b"
        }
        """, name: "config2.pkl")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result, ["file-a", "file-b"])
    }

    // MARK: - Multiple Configs

    func testExtractsFromMultipleConfigs() throws {
        let config1 = try createConfig("""
        figma {
          lightFileId = "file-1"
        }
        """, name: "config1.pkl")

        let config2 = try createConfig("""
        figma {
          lightFileId = "file-2"
          darkFileId = "file-3"
        }
        """, name: "config2.pkl")

        let result = extractor.extractUniqueFileIds(from: [config1, config2])

        XCTAssertEqual(result, ["file-1", "file-2", "file-3"])
    }

    // MARK: - Error Handling

    func testReturnsEmptySetForInvalidPkl() throws {
        let configURL = try createConfig("not valid pkl syntax {{{", name: "invalid.pkl")

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertTrue(result.isEmpty)
    }

    func testExtractsDarkFileIdWhenLightFileIdMissing() throws {
        let configURL = try createConfig("""
        figma {
          darkFileId = "only-dark"
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        // lightFileId is now optional, so config parses successfully
        // Only darkFileId should be extracted
        XCTAssertEqual(result, Set(["only-dark"]))
    }

    func testReturnsEmptySetForNonexistentFile() {
        let nonexistent = tempDir.appendingPathComponent("nonexistent.pkl")

        let result = extractor.extractUniqueFileIds(from: [nonexistent])

        XCTAssertTrue(result.isEmpty)
    }

    func testSkipsInvalidConfigsButExtractsFromValid() throws {
        let valid = try createConfig("""
        figma {
          lightFileId = "valid-file"
        }
        """, name: "valid.pkl")

        let invalid = try createConfig("invalid pkl {{{", name: "invalid.pkl")

        let result = extractor.extractUniqueFileIds(from: [valid, invalid])

        XCTAssertEqual(result, ["valid-file"])
    }

    // MARK: - Empty Input

    func testReturnsEmptySetForEmptyInput() {
        let result = extractor.extractUniqueFileIds(from: [])

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - High Contrast File IDs

    func testExtractsHighContrastFileIds() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "light-file"
          darkFileId = "dark-file"
          lightHighContrastFileId = "light-hc"
          darkHighContrastFileId = "dark-hc"
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains("light-file"))
        XCTAssertTrue(result.contains("dark-file"))
        XCTAssertTrue(result.contains("light-hc"))
        XCTAssertTrue(result.contains("dark-hc"))
    }

    // MARK: - Multi-Entry Colors

    func testExtractsMultiEntryColorsTokensFileIds() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "design-file"
        }
        ios {
          xcodeprojPath = "Test.xcodeproj"
          target = "Test"
          xcassetsPath = "Assets.xcassets"
          xcassetsInMainBundle = true
          colors = new Listing {
            new {
              tokensFileId = "ios-tokens-1"
              tokensCollectionName = "Colors"
              lightModeName = "Light"
              useColorAssets = true
              nameStyle = "camelCase"
            }
            new {
              tokensFileId = "ios-tokens-2"
              tokensCollectionName = "Brand"
              lightModeName = "Light"
              useColorAssets = true
              nameStyle = "camelCase"
            }
          }
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("ios-tokens-1"))
        XCTAssertTrue(result.contains("ios-tokens-2"))
    }

    func testExtractsMultiPlatformMultiEntryColors() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "design-file"
        }
        ios {
          xcodeprojPath = "Test.xcodeproj"
          target = "Test"
          xcassetsPath = "Assets.xcassets"
          xcassetsInMainBundle = true
          colors = new Listing {
            new {
              tokensFileId = "ios-tokens"
              tokensCollectionName = "Colors"
              lightModeName = "Light"
              useColorAssets = true
              nameStyle = "camelCase"
            }
          }
        }
        android {
          mainRes = "./res"
          colors = new Listing {
            new {
              tokensFileId = "android-tokens"
              tokensCollectionName = "Colors"
              lightModeName = "Light"
            }
          }
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("ios-tokens"))
        XCTAssertTrue(result.contains("android-tokens"))
    }

    func testCombinesCommonAndMultiEntryTokens() throws {
        let configURL = try createConfig("""
        figma {
          lightFileId = "design-file"
        }
        common {
          variablesColors {
            tokensFileId = "common-tokens"
            tokensCollectionName = "Shared"
            lightModeName = "Light"
          }
        }
        ios {
          xcodeprojPath = "Test.xcodeproj"
          target = "Test"
          xcassetsPath = "Assets.xcassets"
          xcassetsInMainBundle = true
          colors = new Listing {
            new {
              tokensFileId = "ios-specific"
              tokensCollectionName = "Brand"
              lightModeName = "Light"
              useColorAssets = true
              nameStyle = "camelCase"
            }
          }
        }
        """)

        let result = extractor.extractUniqueFileIds(from: [configURL])

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("common-tokens"))
        XCTAssertTrue(result.contains("ios-specific"))
    }

    // MARK: - Helpers

    private func createConfig(_ content: String, name: String = "test.pkl") throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
