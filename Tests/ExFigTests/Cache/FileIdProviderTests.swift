// swiftlint:disable file_length type_body_length
@testable import ExFigCLI
import Foundation
import XCTest

final class FileIdProviderTests: XCTestCase {
    // MARK: - Variables API (Primary Colors Path)

    func testIncludesCommonVariablesColorsTokensFileId() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "common": {
            "variablesColors": {
              "tokensFileId": "tokens-file",
              "tokensCollectionName": "Colors",
              "lightModeName": "Light"
            }
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertTrue(result.contains("tokens-file"))
        XCTAssertTrue(result.contains("design-file"))
    }

    func testTokensFileIdDifferentFromLightFileId() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "common": {
            "variablesColors": {
              "tokensFileId": "separate-tokens-file",
              "tokensCollectionName": "Colors",
              "lightModeName": "Light"
            }
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("separate-tokens-file"))
    }

    func testTokensFileIdSameAsLightFileIdDeduplicates() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "same-file"
          },
          "common": {
            "variablesColors": {
              "tokensFileId": "same-file",
              "tokensCollectionName": "Colors",
              "lightModeName": "Light"
            }
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.contains("same-file"))
    }

    // MARK: - Base Figma File IDs

    func testIncludesLightFileIdOnly() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "light-only"
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result, ["light-only"])
    }

    func testIncludesDarkFileId() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "light-file",
            "darkFileId": "dark-file"
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result, ["light-file", "dark-file"])
    }

    func testIncludesHighContrastFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "light-file",
            "darkFileId": "dark-file",
            "lightHighContrastFileId": "light-hc",
            "darkHighContrastFileId": "dark-hc"
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains("light-file"))
        XCTAssertTrue(result.contains("dark-file"))
        XCTAssertTrue(result.contains("light-hc"))
        XCTAssertTrue(result.contains("dark-hc"))
    }

    // MARK: - Multi-Entry iOS Colors

    func testIOSMultiEntryColorsExtractsTokensFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "ios": {
            "xcodeprojPath": "Test.xcodeproj",
            "target": "Test",
            "xcassetsPath": "Assets.xcassets",
            "xcassetsInMainBundle": true,
            "colors": [
              {
                "tokensFileId": "ios-tokens-1",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              },
              {
                "tokensFileId": "ios-tokens-2",
                "tokensCollectionName": "Brand",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("ios-tokens-1"))
        XCTAssertTrue(result.contains("ios-tokens-2"))
    }

    func testIOSSingleColorsDoesNotAddTokensFileId() throws {
        // Entry without tokensFileId uses common.variablesColors for source
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "ios": {
            "xcodeprojPath": "Test.xcodeproj",
            "target": "Test",
            "xcassetsPath": "Assets.xcassets",
            "xcassetsInMainBundle": true,
            "colors": [{
              "useColorAssets": true,
              "nameStyle": "camelCase"
            }]
          }
        }
        """)

        let result = params.getFileIds()

        // Only design-file, no tokens from ios.colors (entry has no tokensFileId)
        XCTAssertEqual(result, ["design-file"])
    }

    // MARK: - Multi-Entry Android Colors

    func testAndroidMultiEntryColorsExtractsTokensFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "android": {
            "mainRes": "./res",
            "colors": [
              {
                "tokensFileId": "android-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("android-tokens"))
    }

    // MARK: - Multi-Entry Flutter Colors

    func testFlutterMultiEntryColorsExtractsTokensFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "flutter": {
            "output": "./flutter",
            "colors": [
              {
                "tokensFileId": "flutter-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("flutter-tokens"))
    }

    // MARK: - Multi-Entry Web Colors

    func testWebMultiEntryColorsExtractsTokensFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "web": {
            "output": "./web",
            "colors": [
              {
                "tokensFileId": "web-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("web-tokens"))
    }

    // MARK: - Cross-Platform Deduplication

    func testDeduplicatesSharedTokensFileIdAcrossPlatforms() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "ios": {
            "xcodeprojPath": "Test.xcodeproj",
            "target": "Test",
            "xcassetsPath": "Assets.xcassets",
            "xcassetsInMainBundle": true,
            "colors": [
              {
                "tokensFileId": "shared-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              }
            ]
          },
          "android": {
            "mainRes": "./res",
            "colors": [
              {
                "tokensFileId": "shared-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        // Should have 2 unique IDs, not 3
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("shared-tokens"))
    }

    func testCombinesCommonAndMultiEntryTokensFileIds() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "common": {
            "variablesColors": {
              "tokensFileId": "common-tokens",
              "tokensCollectionName": "Shared",
              "lightModeName": "Light"
            }
          },
          "ios": {
            "xcodeprojPath": "Test.xcodeproj",
            "target": "Test",
            "xcassetsPath": "Assets.xcassets",
            "xcassetsInMainBundle": true,
            "colors": [
              {
                "tokensFileId": "ios-specific-tokens",
                "tokensCollectionName": "Brand",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("common-tokens"))
        XCTAssertTrue(result.contains("ios-specific-tokens"))
    }

    // MARK: - Edge Cases

    func testFiltersEmptyTokensFileIdInMultiEntry() throws {
        let params = try parseParams("""
        {
          "figma": {
            "lightFileId": "design-file"
          },
          "ios": {
            "xcodeprojPath": "Test.xcodeproj",
            "target": "Test",
            "xcassetsPath": "Assets.xcassets",
            "xcassetsInMainBundle": true,
            "colors": [
              {
                "tokensFileId": "valid-tokens",
                "tokensCollectionName": "Colors",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              },
              {
                "tokensFileId": "",
                "tokensCollectionName": "Empty",
                "lightModeName": "Light",
                "useColorAssets": true,
                "nameStyle": "camelCase"
              }
            ]
          }
        }
        """)

        let result = params.getFileIds()

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("design-file"))
        XCTAssertTrue(result.contains("valid-tokens"))
        XCTAssertFalse(result.contains(""))
    }

    // MARK: - Helpers

    private func parseParams(_ json: String) throws -> PKLConfig {
        let decoder = JSONDecoder()
        return try decoder.decode(PKLConfig.self, from: Data(json.utf8))
    }
}
