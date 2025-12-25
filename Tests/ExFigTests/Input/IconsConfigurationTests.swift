// swiftlint:disable file_length type_body_length
@testable import ExFig
import XCTest

final class IconsConfigurationTests: XCTestCase {
    // MARK: - iOS IconsConfiguration

    func testIOSIconsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "format": "svg",
            "assetsFolder": "Icons",
            "nameStyle": "camelCase"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertNil(config.entries[0].figmaFrameName)
        XCTAssertEqual(config.entries[0].format, .svg)
        XCTAssertEqual(config.entries[0].assetsFolder, "Icons")
        XCTAssertFalse(config.isMultiple)
    }

    func testIOSIconsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "format": "svg",
                "assetsFolder": "Actions",
                "nameStyle": "camelCase"
            },
            {
                "figmaFrameName": "Navigation",
                "format": "pdf",
                "assetsFolder": "Navigation",
                "nameStyle": "snake_case"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Actions")
        XCTAssertEqual(config.entries[0].format, .svg)
        XCTAssertEqual(config.entries[0].assetsFolder, "Actions")
        XCTAssertEqual(config.entries[0].nameStyle, .camelCase)

        XCTAssertEqual(config.entries[1].figmaFrameName, "Navigation")
        XCTAssertEqual(config.entries[1].format, .pdf)
        XCTAssertEqual(config.entries[1].assetsFolder, "Navigation")
        XCTAssertEqual(config.entries[1].nameStyle, .snakeCase)
    }

    func testIOSIconsEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Icons",
            "format": "svg",
            "assetsFolder": "Assets",
            "preservesVectorRepresentation": ["icon_*"],
            "nameStyle": "camelCase",
            "imageSwift": "./Generated/Icons.swift",
            "swiftUIImageSwift": "./Generated/SwiftUIIcons.swift",
            "renderMode": "template",
            "renderModeDefaultSuffix": "_default",
            "renderModeOriginalSuffix": "_original",
            "renderModeTemplateSuffix": "_template"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.iOS.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Icons")
        XCTAssertEqual(entry.format, .svg)
        XCTAssertEqual(entry.assetsFolder, "Assets")
        XCTAssertEqual(entry.preservesVectorRepresentation, ["icon_*"])
        XCTAssertEqual(entry.imageSwift?.lastPathComponent, "Icons.swift")
        XCTAssertEqual(entry.swiftUIImageSwift?.lastPathComponent, "SwiftUIIcons.swift")
        XCTAssertEqual(entry.renderMode, .template)
        XCTAssertEqual(entry.renderModeDefaultSuffix, "_default")
        XCTAssertEqual(entry.renderModeOriginalSuffix, "_original")
        XCTAssertEqual(entry.renderModeTemplateSuffix, "_template")
    }

    func testIOSIconsEntriesConversionFromLegacy() throws {
        let json = """
        {
            "format": "pdf",
            "assetsFolder": "Legacy",
            "nameStyle": "snake_case",
            "renderMode": "original"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].figmaFrameName) // Legacy doesn't have this
        XCTAssertEqual(entries[0].format, .pdf)
        XCTAssertEqual(entries[0].assetsFolder, "Legacy")
        XCTAssertEqual(entries[0].nameStyle, .snakeCase)
        XCTAssertEqual(entries[0].renderMode, .original)
    }

    // MARK: - Android IconsConfiguration

    func testAndroidIconsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "output": "drawable"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].output, "drawable")
        XCTAssertFalse(config.isMultiple)
    }

    func testAndroidIconsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "output": "drawable-actions",
                "composePackageName": "com.example.icons.actions"
            },
            {
                "figmaFrameName": "Navigation",
                "output": "drawable-nav",
                "composeFormat": "imageVector",
                "composeExtensionTarget": "com.example.AppIcons"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Actions")
        XCTAssertEqual(config.entries[0].output, "drawable-actions")
        XCTAssertEqual(config.entries[0].composePackageName, "com.example.icons.actions")

        XCTAssertEqual(config.entries[1].figmaFrameName, "Navigation")
        XCTAssertEqual(config.entries[1].output, "drawable-nav")
        XCTAssertEqual(config.entries[1].composeFormat, .imageVector)
        XCTAssertEqual(config.entries[1].composeExtensionTarget, "com.example.AppIcons")
    }

    func testAndroidIconsEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Icons",
            "output": "drawable",
            "composePackageName": "com.example.icons",
            "composeFormat": "resourceReference",
            "composeExtensionTarget": "com.example.AppIcons"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Android.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Icons")
        XCTAssertEqual(entry.output, "drawable")
        XCTAssertEqual(entry.composePackageName, "com.example.icons")
        XCTAssertEqual(entry.composeFormat, .resourceReference)
        XCTAssertEqual(entry.composeExtensionTarget, "com.example.AppIcons")
    }

    // MARK: - Flutter IconsConfiguration

    func testFlutterIconsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "output": "assets/icons"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].output, "assets/icons")
        XCTAssertFalse(config.isMultiple)
    }

    func testFlutterIconsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "output": "assets/icons/actions",
                "dartFile": "lib/generated/action_icons.dart",
                "className": "ActionIcons"
            },
            {
                "figmaFrameName": "Navigation",
                "output": "assets/icons/nav",
                "dartFile": "lib/generated/nav_icons.dart",
                "className": "NavIcons"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Actions")
        XCTAssertEqual(config.entries[0].output, "assets/icons/actions")
        XCTAssertEqual(config.entries[0].dartFile, "lib/generated/action_icons.dart")
        XCTAssertEqual(config.entries[0].className, "ActionIcons")

        XCTAssertEqual(config.entries[1].figmaFrameName, "Navigation")
        XCTAssertEqual(config.entries[1].output, "assets/icons/nav")
    }

    func testFlutterIconsEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Icons",
            "output": "assets/icons",
            "dartFile": "lib/icons.dart",
            "className": "AppIcons"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Flutter.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Icons")
        XCTAssertEqual(entry.output, "assets/icons")
        XCTAssertEqual(entry.dartFile, "lib/icons.dart")
        XCTAssertEqual(entry.className, "AppIcons")
    }

    // MARK: - Full Params Integration

    func testFullParamsWithIOSIconsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Icons.xcassets",
                "xcassetsInMainBundle": true,
                "icons": [
                    {
                        "figmaFrameName": "Actions",
                        "format": "svg",
                        "assetsFolder": "Actions",
                        "nameStyle": "camelCase"
                    },
                    {
                        "figmaFrameName": "Navigation",
                        "format": "pdf",
                        "assetsFolder": "Navigation",
                        "nameStyle": "snake_case"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.icons)
        XCTAssertEqual(params.ios?.icons?.entries.count, 2)
        XCTAssertTrue(params.ios?.icons?.isMultiple ?? false)
    }

    func testFullParamsWithIOSIconsLegacy() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Icons.xcassets",
                "xcassetsInMainBundle": true,
                "icons": {
                    "format": "svg",
                    "assetsFolder": "Icons",
                    "nameStyle": "camelCase"
                }
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.icons)
        XCTAssertEqual(params.ios?.icons?.entries.count, 1)
        XCTAssertFalse(params.ios?.icons?.isMultiple ?? true)
    }

    func testFullParamsWithAndroidIconsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "android": {
                "mainRes": "./app/src/main/res",
                "icons": [
                    {
                        "figmaFrameName": "Actions",
                        "output": "drawable-actions"
                    },
                    {
                        "figmaFrameName": "Navigation",
                        "output": "drawable-nav"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.android?.icons)
        XCTAssertEqual(params.android?.icons?.entries.count, 2)
        XCTAssertTrue(params.android?.icons?.isMultiple ?? false)
    }

    func testFullParamsWithFlutterIconsArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "flutter": {
                "output": "./lib/generated",
                "icons": [
                    {
                        "figmaFrameName": "Actions",
                        "output": "assets/actions"
                    },
                    {
                        "figmaFrameName": "Navigation",
                        "output": "assets/nav"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.flutter?.icons)
        XCTAssertEqual(params.flutter?.icons?.entries.count, 2)
        XCTAssertTrue(params.flutter?.icons?.isMultiple ?? false)
    }

    // MARK: - Edge Cases

    func testIOSIconsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testAndroidIconsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testFlutterIconsConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testIOSIconsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.iOS.IconsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testAndroidIconsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Android.IconsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testFlutterIconsConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Flutter.IconsConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    // MARK: - Per-Entry Regex Fields Tests

    func testIOSIconsEntryParsesRegexFields() throws {
        let json = """
        {
            "figmaFrameName": "Flags",
            "format": "svg",
            "assetsFolder": "Flags",
            "nameStyle": "camelCase",
            "nameValidateRegexp": "^flags_(.+)$",
            "nameReplaceRegexp": "ic_flag_$1"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.iOS.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Flags")
        XCTAssertEqual(entry.nameValidateRegexp, "^flags_(.+)$")
        XCTAssertEqual(entry.nameReplaceRegexp, "ic_flag_$1")
        XCTAssertEqual(entry.nameStyle, .camelCase)
    }

    func testIOSIconsEntryRegexFieldsAreOptional() throws {
        let json = """
        {
            "format": "svg",
            "assetsFolder": "Icons"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.iOS.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
    }

    func testAndroidIconsEntryParsesRegexAndStyleFields() throws {
        let json = """
        {
            "figmaFrameName": "Flags",
            "output": "flag",
            "nameStyle": "snake_case",
            "nameValidateRegexp": "^flags_(.+)$",
            "nameReplaceRegexp": "ic_flag_$1"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Android.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Flags")
        XCTAssertEqual(entry.nameValidateRegexp, "^flags_(.+)$")
        XCTAssertEqual(entry.nameReplaceRegexp, "ic_flag_$1")
        XCTAssertEqual(entry.nameStyle, .snakeCase)
    }

    func testAndroidIconsEntryRegexAndStyleFieldsAreOptional() throws {
        let json = """
        {
            "output": "drawable"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Android.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
        XCTAssertNil(entry.nameStyle)
    }

    func testFlutterIconsEntryParsesRegexAndStyleFields() throws {
        let json = """
        {
            "figmaFrameName": "Flags",
            "output": "assets/flags",
            "nameStyle": "snake_case",
            "nameValidateRegexp": "^flags_(.+)$",
            "nameReplaceRegexp": "ic_flag_$1"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Flutter.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Flags")
        XCTAssertEqual(entry.nameValidateRegexp, "^flags_(.+)$")
        XCTAssertEqual(entry.nameReplaceRegexp, "ic_flag_$1")
        XCTAssertEqual(entry.nameStyle, .snakeCase)
    }

    func testFlutterIconsEntryRegexAndStyleFieldsAreOptional() throws {
        let json = """
        {
            "output": "assets/icons"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Flutter.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
        XCTAssertNil(entry.nameStyle)
    }

    // MARK: - Web IconsConfiguration Tests

    func testWebIconsConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "outputDirectory": "icons"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Web.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].outputDirectory, "icons")
        XCTAssertFalse(config.isMultiple)
    }

    func testWebIconsConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "outputDirectory": "icons/actions"
            },
            {
                "figmaFrameName": "Navigation",
                "outputDirectory": "icons/nav",
                "iconSize": 20
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Web.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Actions")
        XCTAssertEqual(config.entries[0].outputDirectory, "icons/actions")

        XCTAssertEqual(config.entries[1].figmaFrameName, "Navigation")
        XCTAssertEqual(config.entries[1].outputDirectory, "icons/nav")
        XCTAssertEqual(config.entries[1].iconSize, 20)
    }

    func testWebIconsEntryParsesRegexAndStyleFields() throws {
        let json = """
        {
            "figmaFrameName": "Flags",
            "outputDirectory": "icons/flags",
            "nameStyle": "snake_case",
            "nameValidateRegexp": "^flags_(.+)$",
            "nameReplaceRegexp": "ic_flag_$1"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Web.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Flags")
        XCTAssertEqual(entry.nameValidateRegexp, "^flags_(.+)$")
        XCTAssertEqual(entry.nameReplaceRegexp, "ic_flag_$1")
        XCTAssertEqual(entry.nameStyle, .snakeCase)
    }

    func testWebIconsEntryRegexAndStyleFieldsAreOptional() throws {
        let json = """
        {
            "outputDirectory": "icons"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Web.IconsEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
        XCTAssertNil(entry.nameStyle)
    }

    // MARK: - Legacy to Entries Conversion

    func testIOSLegacyToEntriesPreservesNilForRegexFields() throws {
        let json = """
        {
            "format": "svg",
            "assetsFolder": "Legacy"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
    }

    func testAndroidLegacyToEntriesPreservesNilForRegexFields() throws {
        let json = """
        {
            "output": "drawable"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
        XCTAssertNil(entries[0].nameStyle)
    }

    func testFlutterLegacyToEntriesPreservesNilForRegexFields() throws {
        let json = """
        {
            "output": "assets/icons"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
        XCTAssertNil(entries[0].nameStyle)
    }

    func testWebLegacyToEntriesPreservesNilForRegexFields() throws {
        let json = """
        {
            "outputDirectory": "icons"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Web.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
        XCTAssertNil(entries[0].nameStyle)
    }
}
