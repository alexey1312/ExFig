@testable import ExFig
import ExFigKit
import XCTest

final class IconsLoaderConfigTests: XCTestCase {
    // MARK: - iOS Frame Name Resolution

    func testForIOS_entryFrameNameOverridesCommon() throws {
        let entry = try makeIOSEntry(figmaFrameName: "Actions")
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Actions")
    }

    func testForIOS_fallbackToCommonFrameName() throws {
        let entry = try makeIOSEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonIcons")
    }

    func testForIOS_fallbackToDefaultFrameName() throws {
        let entry = try makeIOSEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Icons")
    }

    func testForIOS_passesFormatField() throws {
        let entry = try makeIOSEntry(format: "svg")
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.format, .svg)
    }

    func testForIOS_passesPDFFormat() throws {
        let entry = try makeIOSEntry(format: "pdf")
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.format, .pdf)
    }

    func testForIOS_passesRenderModeFields() throws {
        let entry = try makeIOSEntry(
            renderMode: "original",
            renderModeDefaultSuffix: "_default",
            renderModeOriginalSuffix: "_original",
            renderModeTemplateSuffix: "_template"
        )
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.renderMode, .original)
        XCTAssertEqual(config.renderModeDefaultSuffix, "_default")
        XCTAssertEqual(config.renderModeOriginalSuffix, "_original")
        XCTAssertEqual(config.renderModeTemplateSuffix, "_template")
    }

    func testForIOS_nilRenderModeFieldsWhenNotProvided() throws {
        let entry = try makeIOSEntry()
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertNil(config.renderMode)
        XCTAssertNil(config.renderModeDefaultSuffix)
        XCTAssertNil(config.renderModeOriginalSuffix)
        XCTAssertNil(config.renderModeTemplateSuffix)
    }

    // MARK: - Android Frame Name Resolution

    func testForAndroid_entryFrameNameOverridesCommon() throws {
        let entry = try makeAndroidEntry(figmaFrameName: "Actions")
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Actions")
    }

    func testForAndroid_fallbackToCommonFrameName() throws {
        let entry = try makeAndroidEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonIcons")
    }

    func testForAndroid_fallbackToDefault() throws {
        let entry = try makeAndroidEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Icons")
    }

    func testForAndroid_hasNoIOSSpecificFields() throws {
        let entry = try makeAndroidEntry()
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertNil(config.format)
        XCTAssertNil(config.renderMode)
        XCTAssertNil(config.renderModeDefaultSuffix)
        XCTAssertNil(config.renderModeOriginalSuffix)
        XCTAssertNil(config.renderModeTemplateSuffix)
    }

    // MARK: - Flutter Frame Name Resolution

    func testForFlutter_entryFrameNameOverridesCommon() throws {
        let entry = try makeFlutterEntry(figmaFrameName: "Actions")
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Actions")
    }

    func testForFlutter_fallbackToCommonFrameName() throws {
        let entry = try makeFlutterEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonIcons")
    }

    func testForFlutter_fallbackToDefault() throws {
        let entry = try makeFlutterEntry(figmaFrameName: nil)
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Icons")
    }

    func testForFlutter_hasNoIOSSpecificFields() throws {
        let entry = try makeFlutterEntry()
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertNil(config.format)
        XCTAssertNil(config.renderMode)
        XCTAssertNil(config.renderModeDefaultSuffix)
        XCTAssertNil(config.renderModeOriginalSuffix)
        XCTAssertNil(config.renderModeTemplateSuffix)
    }

    // MARK: - Default Config

    func testDefaultConfig_usesCommonFrameName() {
        let params = Params.make(lightFileId: "test", iconsFrameName: "CommonIcons")

        let config = IconsLoaderConfig.defaultConfig(params: params)

        XCTAssertEqual(config.frameName, "CommonIcons")
    }

    func testDefaultConfig_fallbackToDefault() {
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.defaultConfig(params: params)

        XCTAssertEqual(config.frameName, "Icons")
    }

    func testDefaultConfig_hasNoIOSSpecificFields() {
        let params = Params.make(lightFileId: "test")

        let config = IconsLoaderConfig.defaultConfig(params: params)

        XCTAssertNil(config.format)
        XCTAssertNil(config.renderMode)
        XCTAssertNil(config.renderModeDefaultSuffix)
        XCTAssertNil(config.renderModeOriginalSuffix)
        XCTAssertNil(config.renderModeTemplateSuffix)
    }

    // MARK: - Helpers

    private func makeIOSEntry(
        figmaFrameName: String? = nil,
        format: String = "svg",
        assetsFolder: String = "Icons",
        nameStyle: String = "camelCase",
        renderMode: String? = nil,
        renderModeDefaultSuffix: String? = nil,
        renderModeOriginalSuffix: String? = nil,
        renderModeTemplateSuffix: String? = nil
    ) throws -> Params.iOS.IconsEntry {
        var json = """
        {
            "format": "\(format)",
            "assetsFolder": "\(assetsFolder)",
            "nameStyle": "\(nameStyle)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        if let renderMode {
            json += ", \"renderMode\": \"\(renderMode)\""
        }
        if let renderModeDefaultSuffix {
            json += ", \"renderModeDefaultSuffix\": \"\(renderModeDefaultSuffix)\""
        }
        if let renderModeOriginalSuffix {
            json += ", \"renderModeOriginalSuffix\": \"\(renderModeOriginalSuffix)\""
        }
        if let renderModeTemplateSuffix {
            json += ", \"renderModeTemplateSuffix\": \"\(renderModeTemplateSuffix)\""
        }
        json += "}"

        return try JSONDecoder().decode(Params.iOS.IconsEntry.self, from: Data(json.utf8))
    }

    private func makeAndroidEntry(
        figmaFrameName: String? = nil,
        output: String = "drawable"
    ) throws -> Params.Android.IconsEntry {
        var json = """
        {
            "output": "\(output)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        json += "}"

        return try JSONDecoder().decode(Params.Android.IconsEntry.self, from: Data(json.utf8))
    }

    private func makeFlutterEntry(
        figmaFrameName: String? = nil,
        output: String = "assets/icons"
    ) throws -> Params.Flutter.IconsEntry {
        var json = """
        {
            "output": "\(output)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        json += "}"

        return try JSONDecoder().decode(Params.Flutter.IconsEntry.self, from: Data(json.utf8))
    }
}
