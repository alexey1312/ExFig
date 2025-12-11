// swiftlint:disable file_length type_body_length
@testable import ExFig
import XCTest

final class ImagesConfigurationTests: XCTestCase {
    // MARK: - iOS ImagesConfiguration

    func testIOSImagesConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "assetsFolder": "Illustrations",
            "nameStyle": "camelCase"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].assetsFolder, "Illustrations")
        XCTAssertFalse(config.isMultiple)
    }

    func testIOSImagesConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "InDrive",
                "assetsFolder": "inDrive",
                "nameStyle": "camelCase",
                "imageSwift": "./Generated/InDrive.swift"
            },
            {
                "figmaFrameName": "Promo",
                "assetsFolder": "promo",
                "nameStyle": "snake_case",
                "scales": [1.0, 2.0, 3.0],
                "swiftUIImageSwift": "./Generated/SwiftUIPromo.swift"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "InDrive")
        XCTAssertEqual(config.entries[0].assetsFolder, "inDrive")
        XCTAssertEqual(config.entries[0].nameStyle, .camelCase)
        XCTAssertEqual(config.entries[0].imageSwift?.lastPathComponent, "InDrive.swift")
        XCTAssertNil(config.entries[0].scales)

        XCTAssertEqual(config.entries[1].figmaFrameName, "Promo")
        XCTAssertEqual(config.entries[1].assetsFolder, "promo")
        XCTAssertEqual(config.entries[1].nameStyle, .snakeCase)
        XCTAssertEqual(config.entries[1].scales, [1.0, 2.0, 3.0])
        XCTAssertEqual(config.entries[1].swiftUIImageSwift?.lastPathComponent, "SwiftUIPromo.swift")
    }

    func testIOSImagesEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Illustrations",
            "assetsFolder": "Assets",
            "nameStyle": "camelCase",
            "scales": [1.0, 2.0, 3.0],
            "imageSwift": "./Generated/Images.swift",
            "swiftUIImageSwift": "./Generated/SwiftUIImages.swift"
        }
        """

        let entry = try JSONDecoder().decode(
            Params.iOS.ImagesEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Illustrations")
        XCTAssertEqual(entry.assetsFolder, "Assets")
        XCTAssertEqual(entry.nameStyle, .camelCase)
        XCTAssertEqual(entry.scales, [1.0, 2.0, 3.0])
        XCTAssertEqual(entry.imageSwift?.lastPathComponent, "Images.swift")
        XCTAssertEqual(entry.swiftUIImageSwift?.lastPathComponent, "SwiftUIImages.swift")
    }

    func testIOSImagesEntriesConversionFromLegacy() throws {
        let json = """
        {
            "assetsFolder": "Legacy",
            "nameStyle": "snake_case"
        }
        """

        let config = try JSONDecoder().decode(
            Params.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].figmaFrameName) // Legacy doesn't have this
        XCTAssertEqual(entries[0].assetsFolder, "Legacy")
        XCTAssertEqual(entries[0].nameStyle, .snakeCase)
    }

    // MARK: - Android ImagesConfiguration

    func testAndroidImagesConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "output": "drawable",
            "format": "svg"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Android.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].output, "drawable")
        XCTAssertEqual(config.entries[0].format, .svg)
        XCTAssertFalse(config.isMultiple)
    }

    func testAndroidImagesConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Illustrations",
                "output": "drawable-illustrations",
                "format": "svg"
            },
            {
                "figmaFrameName": "Photos",
                "output": "drawable-photos",
                "format": "webp",
                "scales": [1.0, 1.5, 2.0, 3.0, 4.0],
                "webpOptions": {
                    "encoding": "lossy",
                    "quality": 80
                }
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Android.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Illustrations")
        XCTAssertEqual(config.entries[0].output, "drawable-illustrations")
        XCTAssertEqual(config.entries[0].format, .svg)
        XCTAssertNil(config.entries[0].scales)

        XCTAssertEqual(config.entries[1].figmaFrameName, "Photos")
        XCTAssertEqual(config.entries[1].output, "drawable-photos")
        XCTAssertEqual(config.entries[1].format, .webp)
        XCTAssertEqual(config.entries[1].scales, [1.0, 1.5, 2.0, 3.0, 4.0])
        XCTAssertEqual(config.entries[1].webpOptions?.encoding, .lossy)
        XCTAssertEqual(config.entries[1].webpOptions?.quality, 80)
    }

    func testAndroidImagesEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Images",
            "output": "drawable",
            "format": "png",
            "scales": [1.0, 2.0, 3.0],
            "webpOptions": {
                "encoding": "lossless"
            }
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Android.ImagesEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Images")
        XCTAssertEqual(entry.output, "drawable")
        XCTAssertEqual(entry.format, .png)
        XCTAssertEqual(entry.scales, [1.0, 2.0, 3.0])
        XCTAssertEqual(entry.webpOptions?.encoding, .lossless)
    }

    // MARK: - Flutter ImagesConfiguration

    func testFlutterImagesConfigurationParsesLegacySingleObject() throws {
        let json = """
        {
            "output": "assets/images"
        }
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .single = config else {
            XCTFail("Expected .single case")
            return
        }

        XCTAssertEqual(config.entries.count, 1)
        XCTAssertEqual(config.entries[0].output, "assets/images")
        XCTAssertFalse(config.isMultiple)
    }

    func testFlutterImagesConfigurationParsesMultipleEntries() throws {
        let json = """
        [
            {
                "figmaFrameName": "Illustrations",
                "output": "assets/images/illustrations",
                "dartFile": "lib/generated/illustrations.dart",
                "className": "Illustrations"
            },
            {
                "figmaFrameName": "Promo",
                "output": "assets/images/promo",
                "dartFile": "lib/generated/promo.dart",
                "className": "PromoImages",
                "scales": [1.0, 2.0, 3.0],
                "format": "webp"
            }
        ]
        """

        let config = try JSONDecoder().decode(
            Params.Flutter.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case")
            return
        }

        XCTAssertEqual(config.entries.count, 2)
        XCTAssertTrue(config.isMultiple)

        XCTAssertEqual(config.entries[0].figmaFrameName, "Illustrations")
        XCTAssertEqual(config.entries[0].output, "assets/images/illustrations")
        XCTAssertEqual(config.entries[0].dartFile, "lib/generated/illustrations.dart")
        XCTAssertEqual(config.entries[0].className, "Illustrations")
        XCTAssertNil(config.entries[0].scales)

        XCTAssertEqual(config.entries[1].figmaFrameName, "Promo")
        XCTAssertEqual(config.entries[1].output, "assets/images/promo")
        XCTAssertEqual(config.entries[1].dartFile, "lib/generated/promo.dart")
        XCTAssertEqual(config.entries[1].className, "PromoImages")
        XCTAssertEqual(config.entries[1].scales, [1.0, 2.0, 3.0])
        XCTAssertEqual(config.entries[1].format, .webp)
    }

    func testFlutterImagesEntryParsesAllFields() throws {
        let json = """
        {
            "figmaFrameName": "Images",
            "output": "assets/images",
            "dartFile": "lib/images.dart",
            "className": "AppImages",
            "scales": [1.0, 2.0, 3.0],
            "format": "png",
            "webpOptions": {
                "encoding": "lossy",
                "quality": 90
            }
        }
        """

        let entry = try JSONDecoder().decode(
            Params.Flutter.ImagesEntry.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(entry.figmaFrameName, "Images")
        XCTAssertEqual(entry.output, "assets/images")
        XCTAssertEqual(entry.dartFile, "lib/images.dart")
        XCTAssertEqual(entry.className, "AppImages")
        XCTAssertEqual(entry.scales, [1.0, 2.0, 3.0])
        XCTAssertEqual(entry.format, .png)
        XCTAssertEqual(entry.webpOptions?.encoding, .lossy)
        XCTAssertEqual(entry.webpOptions?.quality, 90)
    }

    // MARK: - Full Params Integration

    func testFullParamsWithIOSImagesArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Images.xcassets",
                "xcassetsInMainBundle": true,
                "images": [
                    {
                        "figmaFrameName": "InDrive",
                        "assetsFolder": "InDrive",
                        "nameStyle": "camelCase"
                    },
                    {
                        "figmaFrameName": "Promo",
                        "assetsFolder": "Promo",
                        "nameStyle": "snake_case"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.images)
        XCTAssertEqual(params.ios?.images?.entries.count, 2)
        XCTAssertTrue(params.ios?.images?.isMultiple ?? false)
    }

    func testFullParamsWithIOSImagesLegacy() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "ios": {
                "xcodeprojPath": ".swiftpm/xcode/package.xcworkspace",
                "target": "TestTarget",
                "xcassetsPath": "./Resources/Images.xcassets",
                "xcassetsInMainBundle": true,
                "images": {
                    "assetsFolder": "Images",
                    "nameStyle": "camelCase"
                }
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.ios?.images)
        XCTAssertEqual(params.ios?.images?.entries.count, 1)
        XCTAssertFalse(params.ios?.images?.isMultiple ?? true)
    }

    func testFullParamsWithAndroidImagesArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "android": {
                "mainRes": "./app/src/main/res",
                "images": [
                    {
                        "figmaFrameName": "Illustrations",
                        "output": "drawable-illustrations",
                        "format": "svg"
                    },
                    {
                        "figmaFrameName": "Photos",
                        "output": "drawable-photos",
                        "format": "webp"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.android?.images)
        XCTAssertEqual(params.android?.images?.entries.count, 2)
        XCTAssertTrue(params.android?.images?.isMultiple ?? false)
    }

    func testFullParamsWithFlutterImagesArray() throws {
        let json = """
        {
            "figma": {
                "lightFileId": "test-file"
            },
            "flutter": {
                "output": "./lib/generated",
                "images": [
                    {
                        "figmaFrameName": "Illustrations",
                        "output": "assets/illustrations"
                    },
                    {
                        "figmaFrameName": "Photos",
                        "output": "assets/photos"
                    }
                ]
            }
        }
        """

        let params = try JSONDecoder().decode(Params.self, from: Data(json.utf8))

        XCTAssertNotNil(params.flutter?.images)
        XCTAssertEqual(params.flutter?.images?.entries.count, 2)
        XCTAssertTrue(params.flutter?.images?.isMultiple ?? false)
    }

    // MARK: - Edge Cases

    func testIOSImagesConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testAndroidImagesConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Android.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testFlutterImagesConfigurationWithEmptyArray() throws {
        let json = "[]"

        let config = try JSONDecoder().decode(
            Params.Flutter.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        guard case .multiple = config else {
            XCTFail("Expected .multiple case for empty array")
            return
        }

        XCTAssertEqual(config.entries.count, 0)
        XCTAssertTrue(config.isMultiple)
    }

    func testIOSImagesConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.iOS.ImagesConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testAndroidImagesConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Android.ImagesConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }

    func testFlutterImagesConfigurationFailsWithInvalidType() throws {
        let json = "\"not_an_object_or_array\""

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                Params.Flutter.ImagesConfiguration.self,
                from: Data(json.utf8)
            )
        )
    }
}
