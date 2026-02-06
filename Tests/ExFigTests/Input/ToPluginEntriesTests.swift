// swiftlint:disable file_length type_body_length

import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
@testable import ExFigCLI
import ExFigCore
import XCTest

final class ToPluginEntriesTests: XCTestCase {
    // MARK: - Helpers

    private func makeCommon(
        variablesColors: PKLConfig.Common.VariablesColors? = nil,
        icons: PKLConfig.Common.Icons? = nil,
        images: PKLConfig.Common.Images? = nil
    ) -> PKLConfig.Common {
        let json = makeCommonJSON(
            variablesColors: variablesColors,
            icons: icons,
            images: images
        )
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(PKLConfig.Common.self, from: Data(json.utf8))
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func makeCommonJSON(
        variablesColors: PKLConfig.Common.VariablesColors?,
        icons: PKLConfig.Common.Icons?,
        images: PKLConfig.Common.Images?
    ) -> String {
        var parts: [String] = []

        if let vc = variablesColors {
            var vcParts: [String] = []
            vcParts.append("\"tokensFileId\": \"\(vc.tokensFileId)\"")
            vcParts.append("\"tokensCollectionName\": \"\(vc.tokensCollectionName)\"")
            vcParts.append("\"lightModeName\": \"\(vc.lightModeName)\"")
            if let d = vc.darkModeName { vcParts.append("\"darkModeName\": \"\(d)\"") }
            if let v = vc.nameValidateRegexp { vcParts.append("\"nameValidateRegexp\": \"\(v)\"") }
            if let r = vc.nameReplaceRegexp { vcParts.append("\"nameReplaceRegexp\": \"\(r)\"") }
            parts.append("\"variablesColors\": {\(vcParts.joined(separator: ", "))}")
        }

        if let ic = icons {
            var icParts: [String] = []
            if let f = ic.figmaFrameName { icParts.append("\"figmaFrameName\": \"\(f)\"") }
            if let v = ic.nameValidateRegexp { icParts.append("\"nameValidateRegexp\": \"\(v)\"") }
            if let r = ic.nameReplaceRegexp { icParts.append("\"nameReplaceRegexp\": \"\(r)\"") }
            parts.append("\"icons\": {\(icParts.joined(separator: ", "))}")
        }

        if let im = images {
            var imParts: [String] = []
            if let f = im.figmaFrameName { imParts.append("\"figmaFrameName\": \"\(f)\"") }
            if let v = im.nameValidateRegexp { imParts.append("\"nameValidateRegexp\": \"\(v)\"") }
            if let r = im.nameReplaceRegexp { imParts.append("\"nameReplaceRegexp\": \"\(r)\"") }
            parts.append("\"images\": {\(imParts.joined(separator: ", "))}")
        }

        return "{\(parts.joined(separator: ", "))}"
    }

    private func makeVariablesColors(
        tokensFileId: String = "tokens-file",
        tokensCollectionName: String = "Design Tokens",
        lightModeName: String = "Light",
        darkModeName: String? = "Dark",
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) -> PKLConfig.Common.VariablesColors {
        var parts: [String] = []
        parts.append("\"tokensFileId\": \"\(tokensFileId)\"")
        parts.append("\"tokensCollectionName\": \"\(tokensCollectionName)\"")
        parts.append("\"lightModeName\": \"\(lightModeName)\"")
        if let d = darkModeName { parts.append("\"darkModeName\": \"\(d)\"") }
        if let v = nameValidateRegexp { parts.append("\"nameValidateRegexp\": \"\(v)\"") }
        if let r = nameReplaceRegexp { parts.append("\"nameReplaceRegexp\": \"\(r)\"") }
        let json = "{\(parts.joined(separator: ", "))}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(PKLConfig.Common.VariablesColors.self, from: Data(json.utf8))
    }

    private func makeCommonIcons(
        figmaFrameName: String? = "Icons",
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) -> PKLConfig.Common.Icons {
        var parts: [String] = []
        if let f = figmaFrameName { parts.append("\"figmaFrameName\": \"\(f)\"") }
        if let v = nameValidateRegexp { parts.append("\"nameValidateRegexp\": \"\(v)\"") }
        if let r = nameReplaceRegexp { parts.append("\"nameReplaceRegexp\": \"\(r)\"") }
        let json = "{\(parts.joined(separator: ", "))}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(PKLConfig.Common.Icons.self, from: Data(json.utf8))
    }

    private func makeCommonImages(
        figmaFrameName: String? = "Images",
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) -> PKLConfig.Common.Images {
        var parts: [String] = []
        if let f = figmaFrameName { parts.append("\"figmaFrameName\": \"\(f)\"") }
        if let v = nameValidateRegexp { parts.append("\"nameValidateRegexp\": \"\(v)\"") }
        if let r = nameReplaceRegexp { parts.append("\"nameReplaceRegexp\": \"\(r)\"") }
        let json = "{\(parts.joined(separator: ", "))}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(PKLConfig.Common.Images.self, from: Data(json.utf8))
    }

    // MARK: - iOS Colors toPluginEntries

    func testIOSColorsLegacyWithVariablesColorsMergesFields() throws {
        let json = """
        {
            "useColorAssets": true,
            "assetsFolder": "Colors",
            "nameStyle": "camelCase"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(variablesColors: makeVariablesColors())
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "tokens-file")
        XCTAssertEqual(entries[0].tokensCollectionName, "Design Tokens")
        XCTAssertEqual(entries[0].lightModeName, "Light")
        XCTAssertEqual(entries[0].darkModeName, "Dark")
        XCTAssertTrue(entries[0].useColorAssets)
        XCTAssertEqual(entries[0].assetsFolder, "Colors")
        XCTAssertEqual(entries[0].nameStyle, .camelCase)
    }

    func testIOSColorsLegacyWithoutVariablesColorsReturnsEmpty() throws {
        let json = """
        {
            "useColorAssets": true,
            "assetsFolder": "Colors",
            "nameStyle": "camelCase"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertTrue(entries.isEmpty)
    }

    func testIOSColorsLegacyWithCommonButNoVariablesColorsReturnsEmpty() throws {
        let json = """
        {
            "useColorAssets": false,
            "assetsFolder": "TestFolder",
            "nameStyle": "snake_case"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon()
        let entries = config.toPluginEntries(common: common)
        XCTAssertTrue(entries.isEmpty)
    }

    func testIOSColorsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "tokensFileId": "f1",
                "tokensCollectionName": "C1",
                "lightModeName": "L",
                "useColorAssets": true,
                "nameStyle": "camelCase"
            },
            {
                "tokensFileId": "f2",
                "tokensCollectionName": "C2",
                "lightModeName": "L2",
                "useColorAssets": false,
                "nameStyle": "snake_case"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].tokensFileId, "f1")
        XCTAssertEqual(entries[1].tokensFileId, "f2")
    }

    // MARK: - iOS Icons toPluginEntries

    func testIOSIconsLegacyMergesCommonFields() throws {
        let json = """
        {
            "format": "svg",
            "assetsFolder": "Icons",
            "nameStyle": "camelCase"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(icons: makeCommonIcons(
            figmaFrameName: "MyIcons",
            nameValidateRegexp: "^ic_(.+)$",
            nameReplaceRegexp: "icon_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "MyIcons")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^ic_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "icon_$1")
        XCTAssertEqual(entries[0].format, .svg)
        XCTAssertEqual(entries[0].assetsFolder, "Icons")
    }

    func testIOSIconsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "format": "svg",
                "assetsFolder": "Actions",
                "nameStyle": "camelCase"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Actions")
    }

    // MARK: - iOS Images toPluginEntries

    func testIOSImagesLegacyMergesCommonFields() throws {
        let json = """
        {
            "assetsFolder": "Images",
            "nameStyle": "camelCase",
            "scales": [1.0, 2.0, 3.0]
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(images: makeCommonImages(
            figmaFrameName: "MyImages",
            nameValidateRegexp: "^img_(.+)$",
            nameReplaceRegexp: "image_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "MyImages")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^img_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "image_$1")
        XCTAssertEqual(entries[0].scales, [1.0, 2.0, 3.0])
    }

    func testIOSImagesMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Photos",
                "assetsFolder": "Photos",
                "nameStyle": "camelCase"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Photos")
    }

    // MARK: - Android Colors toPluginEntries

    func testAndroidColorsLegacyWithVariablesColorsMergesFields() throws {
        let json = """
        {
            "xmlOutputFileName": "my_colors.xml",
            "composePackageName": "com.example.colors"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(variablesColors: makeVariablesColors(
            tokensFileId: "android-tokens",
            tokensCollectionName: "Android Colors",
            lightModeName: "Day"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "android-tokens")
        XCTAssertEqual(entries[0].tokensCollectionName, "Android Colors")
        XCTAssertEqual(entries[0].lightModeName, "Day")
        XCTAssertEqual(entries[0].xmlOutputFileName, "my_colors.xml")
        XCTAssertEqual(entries[0].composePackageName, "com.example.colors")
    }

    func testAndroidColorsLegacyWithoutVariablesColorsReturnsEmpty() throws {
        let json = """
        {
            "xmlOutputFileName": "colors.xml"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertTrue(entries.isEmpty)
    }

    func testAndroidColorsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "tokensFileId": "f1",
                "tokensCollectionName": "C1",
                "lightModeName": "Light",
                "xmlOutputFileName": "base.xml"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "f1")
    }

    // MARK: - Android Icons toPluginEntries

    func testAndroidIconsLegacyMergesCommonFields() throws {
        let json = """
        {
            "output": "drawable"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(icons: makeCommonIcons(
            figmaFrameName: "AndroidIcons",
            nameValidateRegexp: "^ic_(.+)$",
            nameReplaceRegexp: "icon_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "AndroidIcons")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^ic_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "icon_$1")
        XCTAssertEqual(entries[0].output, "drawable")
    }

    func testAndroidIconsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "NavIcons",
                "output": "drawable-nav"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "NavIcons")
    }

    // MARK: - Android Images toPluginEntries

    func testAndroidImagesLegacyMergesCommonFields() throws {
        let json = """
        {
            "output": "drawable-images",
            "format": "png"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(images: makeCommonImages(
            figmaFrameName: "AndroidImages",
            nameValidateRegexp: "^img_(.+)$",
            nameReplaceRegexp: "image_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "AndroidImages")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^img_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "image_$1")
        XCTAssertEqual(entries[0].output, "drawable-images")
    }

    func testAndroidImagesMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Photos",
                "output": "drawable-photos",
                "format": "webp"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Android.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Photos")
    }

    // MARK: - Flutter Colors toPluginEntries

    func testFlutterColorsLegacyWithVariablesColorsMergesFields() throws {
        let json = """
        {
            "output": "colors.dart",
            "className": "AppColors"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(variablesColors: makeVariablesColors(
            tokensFileId: "flutter-tokens",
            lightModeName: "Light"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "flutter-tokens")
        XCTAssertEqual(entries[0].lightModeName, "Light")
        XCTAssertEqual(entries[0].output, "colors.dart")
        XCTAssertEqual(entries[0].className, "AppColors")
    }

    func testFlutterColorsLegacyWithoutVariablesColorsReturnsEmpty() throws {
        let json = """
        {
            "output": "colors.dart"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertTrue(entries.isEmpty)
    }

    func testFlutterColorsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "tokensFileId": "f1",
                "tokensCollectionName": "C1",
                "lightModeName": "L",
                "output": "base.dart",
                "className": "Base"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "f1")
    }

    // MARK: - Flutter Icons toPluginEntries

    func testFlutterIconsLegacyMergesCommonFields() throws {
        let json = """
        {
            "output": "assets/icons",
            "dartFile": "lib/icons.dart",
            "className": "Icons"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(icons: makeCommonIcons(
            figmaFrameName: "FlutterIcons",
            nameValidateRegexp: "^fl_(.+)$",
            nameReplaceRegexp: "icon_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "FlutterIcons")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^fl_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "icon_$1")
        XCTAssertEqual(entries[0].output, "assets/icons")
    }

    func testFlutterIconsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Nav",
                "output": "assets/nav"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Nav")
    }

    // MARK: - Flutter Images toPluginEntries

    func testFlutterImagesLegacyMergesCommonFields() throws {
        let json = """
        {
            "output": "assets/images",
            "scales": [1.0, 2.0]
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(images: makeCommonImages(
            figmaFrameName: "FlutterImages",
            nameValidateRegexp: "^img_(.+)$",
            nameReplaceRegexp: "image_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "FlutterImages")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^img_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "image_$1")
        XCTAssertEqual(entries[0].scales, [1.0, 2.0])
    }

    func testFlutterImagesMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Illustrations",
                "output": "assets/illustrations"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Flutter.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Illustrations")
    }

    // MARK: - Web Colors toPluginEntries

    func testWebColorsLegacyWithVariablesColorsMergesFields() throws {
        let json = """
        {
            "outputDirectory": "styles",
            "cssFileName": "colors.css",
            "tsFileName": "colors.ts"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(variablesColors: makeVariablesColors(
            tokensFileId: "web-tokens",
            lightModeName: "Light",
            darkModeName: "Dark"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "web-tokens")
        XCTAssertEqual(entries[0].lightModeName, "Light")
        XCTAssertEqual(entries[0].darkModeName, "Dark")
        XCTAssertEqual(entries[0].outputDirectory, "styles")
        XCTAssertEqual(entries[0].cssFileName, "colors.css")
        XCTAssertEqual(entries[0].tsFileName, "colors.ts")
    }

    func testWebColorsLegacyWithoutVariablesColorsReturnsEmpty() throws {
        let json = """
        {
            "outputDirectory": "styles"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertTrue(entries.isEmpty)
    }

    func testWebColorsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "tokensFileId": "f1",
                "tokensCollectionName": "C1",
                "lightModeName": "L",
                "outputDirectory": "base-styles"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.ColorsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tokensFileId, "f1")
    }

    // MARK: - Web Icons toPluginEntries

    func testWebIconsLegacyMergesCommonFields() throws {
        let json = """
        {
            "outputDirectory": "src/icons"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(icons: makeCommonIcons(
            figmaFrameName: "WebIcons",
            nameValidateRegexp: "^web_(.+)$",
            nameReplaceRegexp: "icon_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "WebIcons")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^web_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "icon_$1")
        XCTAssertEqual(entries[0].outputDirectory, "src/icons")
    }

    func testWebIconsMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Actions",
                "outputDirectory": "src/icons/actions"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Actions")
    }

    // MARK: - Web Images toPluginEntries

    func testWebImagesLegacyMergesCommonFields() throws {
        let json = """
        {
            "outputDirectory": "src/images"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let common = makeCommon(images: makeCommonImages(
            figmaFrameName: "WebImages",
            nameValidateRegexp: "^web_img_(.+)$",
            nameReplaceRegexp: "img_$1"
        ))
        let entries = config.toPluginEntries(common: common)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "WebImages")
        XCTAssertEqual(entries[0].nameValidateRegexp, "^web_img_(.+)$")
        XCTAssertEqual(entries[0].nameReplaceRegexp, "img_$1")
        XCTAssertEqual(entries[0].outputDirectory, "src/images")
    }

    func testWebImagesMultipleReturnsAsIs() throws {
        let json = """
        [
            {
                "figmaFrameName": "Photos",
                "outputDirectory": "src/photos"
            }
        ]
        """
        let config = try JSONDecoder().decode(
            PKLConfig.Web.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].figmaFrameName, "Photos")
    }

    // MARK: - Legacy with nil common (icons/images)

    func testIOSIconsLegacyWithNilCommonUsesNilFields() throws {
        let json = """
        {
            "format": "pdf",
            "assetsFolder": "Icons",
            "nameStyle": "snake_case"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.IconsConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].figmaFrameName)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
        XCTAssertEqual(entries[0].format, .pdf)
    }

    func testIOSImagesLegacyWithNilCommonUsesNilFields() throws {
        let json = """
        {
            "assetsFolder": "Images",
            "nameStyle": "camelCase"
        }
        """
        let config = try JSONDecoder().decode(
            PKLConfig.iOS.ImagesConfiguration.self,
            from: Data(json.utf8)
        )

        let entries = config.toPluginEntries(common: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].figmaFrameName)
        XCTAssertNil(entries[0].nameValidateRegexp)
        XCTAssertNil(entries[0].nameReplaceRegexp)
    }
}

// swiftlint:enable file_length type_body_length
