// swiftlint:disable file_length type_body_length
@testable import ExFig
import XCTest

final class ColorsConfigurationTests: XCTestCase {
    // MARK: - iOS ColorsConfiguration

    func testIOSColorsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "useColorAssets": true,
            "assetsFolder": "Colors",
            "nameStyle": "camelCase"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertTrue(config.entries[0].useColorAssets)
        XCTAssertEqual(config.entries[0].assetsFolder, "Colors")
        XCTAssertFalse(config.isMultiple)
    }

    func testIOSColorsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "tokensFileId": "file1",
                "tokensCollectionName": "Base palette",
                "lightModeName": "Light",
                "useColorAssets": true,
                "assetsFolder": "BaseColors",
                "nameStyle": "camelCase",
                "colorSwift": "./Generated/BaseColors.swift"
            },
            {
                "tokensFileId": "file2",
                "tokensCollectionName": "Statement palette",
                "lightModeName": "Light",
                "darkModeName": "Dark",
                "useColorAssets": true,
                "assetsFolder": "StatementColors",
                "nameStyle": "snake_case",
                "colorSwift": "./Generated/StatementColors.swift"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].tokensFileId, "file1")
        XCTAssertEqual(config.entries[0].tokensCollectionName, "Base palette")
        XCTAssertEqual(config.entries[0].lightModeName, "Light")
        XCTAssertNil(config.entries[0].darkModeName)
        XCTAssertEqual(config.entries[0].assetsFolder, "BaseColors")
        XCTAssertEqual(config.entries[0].nameStyle, .camelCase)

        XCTAssertEqual(config.entries[1].tokensFileId, "file2")
        XCTAssertEqual(config.entries[1].tokensCollectionName, "Statement palette")
        XCTAssertEqual(config.entries[1].darkModeName, "Dark")
        XCTAssertEqual(config.entries[1].assetsFolder, "StatementColors")
        XCTAssertEqual(config.entries[1].nameStyle, .snakeCase)
    }

    func testIOSColorsEntryParsesAllFields() throws {
        let json = """
        {
            "tokensFileId": "abc123",
            "tokensCollectionName": "Design Tokens",
            "lightModeName": "Light",
            "darkModeName": "Dark",
            "lightHCModeName": "Light HC",
            "darkHCModeName": "Dark HC",
            "primitivesModeName": "Primitives",
            "nameValidateRegexp": "^color_.*",
            "nameReplaceRegexp": "color_",
            "useColorAssets": true,
            "assetsFolder": "DesignColors",
            "nameStyle": "camelCase",
            "groupUsingNamespace": true,
            "colorSwift": "./Generated/Colors.swift",
            "swiftuiColorSwift": "./Generated/SwiftUIColors.swift"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.iOS.ColorsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.tokensFileId, "abc123")
        XCTAssertEqual(entry.tokensCollectionName, "Design Tokens")
        XCTAssertEqual(entry.lightModeName, "Light")
        XCTAssertEqual(entry.darkModeName, "Dark")
        XCTAssertEqual(entry.lightHCModeName, "Light HC")
        XCTAssertEqual(entry.darkHCModeName, "Dark HC")
        XCTAssertEqual(entry.primitivesModeName, "Primitives")
        XCTAssertEqual(entry.nameValidateRegexp, "^color_.*")
        XCTAssertEqual(entry.nameReplaceRegexp, "color_")
        XCTAssertTrue(entry.useColorAssets)
        XCTAssertEqual(entry.assetsFolder, "DesignColors")
        XCTAssertEqual(entry.nameStyle, .camelCase)
        XCTAssertEqual(entry.groupUsingNamespace, true)
        XCTAssertEqual(entry.colorSwift?.lastPathComponent, "Colors.swift")
        XCTAssertEqual(entry.swiftuiColorSwift?.lastPathComponent, "SwiftUIColors.swift")
    }

    // MARK: - Android ColorsConfiguration

    func testAndroidColorsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "xmlOutputFileName": "custom_colors.xml"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].xmlOutputFileName, "custom_colors.xml")
        XCTAssertFalse(config.isMultiple)
    }

    func testAndroidColorsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "tokensFileId": "file1",
                "tokensCollectionName": "Base palette",
                "lightModeName": "Light",
                "xmlOutputFileName": "base_colors.xml"
            },
            {
                "tokensFileId": "file2",
                "tokensCollectionName": "Theme palette",
                "lightModeName": "Light",
                "darkModeName": "Dark",
                "xmlOutputFileName": "theme_colors.xml",
                "composePackageName": "com.example.theme"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].tokensFileId, "file1")
        XCTAssertEqual(config.entries[0].tokensCollectionName, "Base palette")
        XCTAssertEqual(config.entries[0].xmlOutputFileName, "base_colors.xml")
        XCTAssertNil(config.entries[0].composePackageName)

        XCTAssertEqual(config.entries[1].tokensFileId, "file2")
        XCTAssertEqual(config.entries[1].darkModeName, "Dark")
        XCTAssertEqual(config.entries[1].xmlOutputFileName, "theme_colors.xml")
        XCTAssertEqual(config.entries[1].composePackageName, "com.example.theme")
    }

    func testAndroidColorsEntryParsesAllFields() throws {
        let json = """
        {
            "tokensFileId": "abc123",
            "tokensCollectionName": "Design Tokens",
            "lightModeName": "Light",
            "darkModeName": "Dark",
            "lightHCModeName": "Light HC",
            "darkHCModeName": "Dark HC",
            "primitivesModeName": "Primitives",
            "nameValidateRegexp": "^color_.*",
            "nameReplaceRegexp": "color_",
            "xmlOutputFileName": "design_colors.xml",
            "composePackageName": "com.example.colors"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Android.ColorsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.tokensFileId, "abc123")
        XCTAssertEqual(entry.tokensCollectionName, "Design Tokens")
        XCTAssertEqual(entry.lightModeName, "Light")
        XCTAssertEqual(entry.darkModeName, "Dark")
        XCTAssertEqual(entry.lightHCModeName, "Light HC")
        XCTAssertEqual(entry.darkHCModeName, "Dark HC")
        XCTAssertEqual(entry.primitivesModeName, "Primitives")
        XCTAssertEqual(entry.nameValidateRegexp, "^color_.*")
        XCTAssertEqual(entry.nameReplaceRegexp, "color_")
        XCTAssertEqual(entry.xmlOutputFileName, "design_colors.xml")
        XCTAssertEqual(entry.composePackageName, "com.example.colors")
    }

    // MARK: - Flutter ColorsConfiguration

    func testFlutterColorsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "output": "colors.dart",
            "className": "AppColors"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].output, "colors.dart")
        XCTAssertEqual(config.entries[0].className, "AppColors")
        XCTAssertFalse(config.isMultiple)
    }

    func testFlutterColorsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "tokensFileId": "file1",
                "tokensCollectionName": "Base palette",
                "lightModeName": "Light",
                "output": "base_colors.dart",
                "className": "BaseColors"
            },
            {
                "tokensFileId": "file2",
                "tokensCollectionName": "Theme palette",
                "lightModeName": "Light",
                "darkModeName": "Dark",
                "output": "theme_colors.dart",
                "className": "ThemeColors"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].tokensFileId, "file1")
        XCTAssertEqual(config.entries[0].tokensCollectionName, "Base palette")
        XCTAssertEqual(config.entries[0].output, "base_colors.dart")
        XCTAssertEqual(config.entries[0].className, "BaseColors")

        XCTAssertEqual(config.entries[1].tokensFileId, "file2")
        XCTAssertEqual(config.entries[1].darkModeName, "Dark")
        XCTAssertEqual(config.entries[1].output, "theme_colors.dart")
        XCTAssertEqual(config.entries[1].className, "ThemeColors")
    }

    func testFlutterColorsEntryParsesAllFields() throws {
        let json = """
        {
            "tokensFileId": "abc123",
            "tokensCollectionName": "Design Tokens",
            "lightModeName": "Light",
            "darkModeName": "Dark",
            "lightHCModeName": "Light HC",
            "darkHCModeName": "Dark HC",
            "primitivesModeName": "Primitives",
            "nameValidateRegexp": "^color_.*",
            "nameReplaceRegexp": "color_",
            "output": "design_colors.dart",
            "className": "DesignColors"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Flutter.ColorsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.tokensFileId, "abc123")
        XCTAssertEqual(entry.tokensCollectionName, "Design Tokens")
        XCTAssertEqual(entry.lightModeName, "Light")
        XCTAssertEqual(entry.darkModeName, "Dark")
        XCTAssertEqual(entry.lightHCModeName, "Light HC")
        XCTAssertEqual(entry.darkHCModeName, "Dark HC")
        XCTAssertEqual(entry.primitivesModeName, "Primitives")
        XCTAssertEqual(entry.nameValidateRegexp, "^color_.*")
        XCTAssertEqual(entry.nameReplaceRegexp, "color_")
        XCTAssertEqual(entry.output, "design_colors.dart")
        XCTAssertEqual(entry.className, "DesignColors")
    }

    // MARK: - Full Params Integration

    func testFullParamsWithIOSColorsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Colors.xcassets",
                "xcassetsInMainBundle": true,
                "colors": [
                    {
                        "tokensFileId": "file1",
                        "tokensCollectionName": "Base",
                        "lightModeName": "Light",
                        "useColorAssets": true,
                        "assetsFolder": "Base",
                        "nameStyle": "camelCase"
                    },
                    {
                        "tokensFileId": "file2",
                        "tokensCollectionName": "Theme",
                        "lightModeName": "Light",
                        "useColorAssets": true,
                        "assetsFolder": "Theme",
                        "nameStyle": "camelCase"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.colors)
        XCTAssertEqual(params.ios?.colors?.entries.count, 2)
        XCTAssertTrue(params.ios?.colors?.isMultiple ?? false)
    }

    func testFullParamsWithIOSColorsLegacy() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Colors.xcassets",
                "xcassetsInMainBundle": true,
                "colors": {
                    "useColorAssets": true,
                    "assetsFolder": "Colors",
                    "nameStyle": "camelCase"
                }
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.colors)
        XCTAssertEqual(params.ios?.colors?.entries.count, 1)
        XCTAssertFalse(params.ios?.colors?.isMultiple ?? true)
    }

    func testFullParamsWithAndroidColorsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "android": {
                "mainRes": "./app/src/main/res",
                "colors": [
                    {
                        "tokensFileId": "file1",
                        "tokensCollectionName": "Base",
                        "lightModeName": "Light",
                        "xmlOutputFileName": "base_colors.xml"
                    },
                    {
                        "tokensFileId": "file2",
                        "tokensCollectionName": "Theme",
                        "lightModeName": "Light",
                        "xmlOutputFileName": "theme_colors.xml"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.android?.colors)
        XCTAssertEqual(params.android?.colors?.entries.count, 2)
        XCTAssertTrue(params.android?.colors?.isMultiple ?? false)
    }

    func testFullParamsWithFlutterColorsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "flutter": {
                "output": "./lib/generated",
                "colors": [
                    {
                        "tokensFileId": "file1",
                        "tokensCollectionName": "Base",
                        "lightModeName": "Light",
                        "output": "base_colors.dart",
                        "className": "BaseColors"
                    },
                    {
                        "tokensFileId": "file2",
                        "tokensCollectionName": "Theme",
                        "lightModeName": "Light",
                        "output": "theme_colors.dart",
                        "className": "ThemeColors"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.flutter?.colors)
        XCTAssertEqual(params.flutter?.colors?.entries.count, 2)
        XCTAssertTrue(params.flutter?.colors?.isMultiple ?? false)
    }

    // MARK: - Edge Cases

    func testIOSColorsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testAndroidColorsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testFlutterColorsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testIOSColorsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.iOS.ColorsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testAndroidColorsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Android.ColorsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testFlutterColorsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Flutter.ColorsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }
}
