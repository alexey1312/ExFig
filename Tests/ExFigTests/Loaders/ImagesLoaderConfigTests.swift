import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
@testable import ExFigCLI
import ExFigCore
import XCTest

final class ImagesLoaderConfigTests: XCTestCase {
    // MARK: - iOS Frame Name Resolution

    func testForIOS_entryFrameNameOverridesCommon() throws {
        let entry = try makeIOSEntry(figmaFrameName: "Promo")
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Promo")
    }

    func testForIOS_fallbackToCommonFrameName() throws {
        let entry = try makeIOSEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonImages")
    }

    func testForIOS_fallbackToDefaultFrameName() throws {
        let entry = try makeIOSEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Illustrations")
    }

    func testForIOS_passesScalesField() throws {
        let entry = try makeIOSEntry(scales: [1.0, 2.0, 3.0])
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertEqual(config.scales, [1.0, 2.0, 3.0])
    }

    func testForIOS_nilScalesWhenNotProvided() throws {
        let entry = try makeIOSEntry()
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertNil(config.scales)
    }

    func testForIOS_formatIsAlwaysNil() throws {
        let entry = try makeIOSEntry()
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)

        XCTAssertNil(config.format, "iOS always uses PNG, so format should be nil")
    }

    // MARK: - Android Frame Name Resolution

    func testForAndroid_entryFrameNameOverridesCommon() throws {
        let entry = try makeAndroidEntry(figmaFrameName: "Photos")
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Photos")
    }

    func testForAndroid_fallbackToCommonFrameName() throws {
        let entry = try makeAndroidEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonImages")
    }

    func testForAndroid_fallbackToDefault() throws {
        let entry = try makeAndroidEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Illustrations")
    }

    func testForAndroid_passesScalesField() throws {
        let entry = try makeAndroidEntry(scales: [1.0, 1.5, 2.0, 3.0, 4.0])
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.scales, [1.0, 1.5, 2.0, 3.0, 4.0])
    }

    func testForAndroid_formatSVG() throws {
        let entry = try makeAndroidEntry(format: "svg")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.format, .svg)
    }

    func testForAndroid_formatPNG() throws {
        let entry = try makeAndroidEntry(format: "png")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.format, .png)
    }

    func testForAndroid_formatWebP() throws {
        let entry = try makeAndroidEntry(format: "webp")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forAndroid(entry: entry, params: params)

        XCTAssertEqual(config.format, .webp)
    }

    // MARK: - Flutter Frame Name Resolution

    func testForFlutter_entryFrameNameOverridesCommon() throws {
        let entry = try makeFlutterEntry(figmaFrameName: "Banners")
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Banners")
    }

    func testForFlutter_fallbackToCommonFrameName() throws {
        let entry = try makeFlutterEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "CommonImages")
    }

    func testForFlutter_fallbackToDefault() throws {
        let entry = try makeFlutterEntry(figmaFrameName: nil)
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.frameName, "Illustrations")
    }

    func testForFlutter_passesScalesField() throws {
        let entry = try makeFlutterEntry(scales: [1.0, 2.0, 3.0])
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.scales, [1.0, 2.0, 3.0])
    }

    func testForFlutter_formatSVG() throws {
        let entry = try makeFlutterEntry(format: "svg")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.format, .svg)
    }

    func testForFlutter_formatPNG() throws {
        let entry = try makeFlutterEntry(format: "png")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.format, .png)
    }

    func testForFlutter_formatWebP() throws {
        let entry = try makeFlutterEntry(format: "webp")
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertEqual(config.format, .webp)
    }

    func testForFlutter_formatNilWhenNotProvided() throws {
        let entry = try makeFlutterEntry()
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.forFlutter(entry: entry, params: params)

        XCTAssertNil(config.format)
    }

    // MARK: - Default Config

    func testDefaultConfig_usesCommonFrameName() {
        let params = PKLConfig.make(lightFileId: "test", imagesFrameName: "CommonImages")

        let config = ImagesLoaderConfig.defaultConfig(params: params)

        XCTAssertEqual(config.frameName, "CommonImages")
    }

    func testDefaultConfig_fallbackToDefault() {
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.defaultConfig(params: params)

        XCTAssertEqual(config.frameName, "Illustrations")
    }

    func testDefaultConfig_hasNilScales() {
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.defaultConfig(params: params)

        XCTAssertNil(config.scales)
    }

    func testDefaultConfig_hasNilFormat() {
        let params = PKLConfig.make(lightFileId: "test")

        let config = ImagesLoaderConfig.defaultConfig(params: params)

        XCTAssertNil(config.format)
    }

    // MARK: - Helpers

    private func makeIOSEntry(
        figmaFrameName: String? = nil,
        assetsFolder: String = "Images",
        nameStyle: String = "camelCase",
        scales: [Double]? = nil
    ) throws -> iOSImagesEntry {
        var json = """
        {
            "assetsFolder": "\(assetsFolder)",
            "nameStyle": "\(nameStyle)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        if let scales {
            let scalesJson = scales.map { String($0) }.joined(separator: ", ")
            json += ", \"scales\": [\(scalesJson)]"
        }
        json += "}"

        return try JSONDecoder().decode(iOSImagesEntry.self, from: Data(json.utf8))
    }

    private func makeAndroidEntry(
        figmaFrameName: String? = nil,
        output: String = "drawable",
        format: String = "svg",
        scales: [Double]? = nil
    ) throws -> AndroidImagesEntry {
        var json = """
        {
            "output": "\(output)",
            "format": "\(format)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        if let scales {
            let scalesJson = scales.map { String($0) }.joined(separator: ", ")
            json += ", \"scales\": [\(scalesJson)]"
        }
        json += "}"

        return try JSONDecoder().decode(AndroidImagesEntry.self, from: Data(json.utf8))
    }

    private func makeFlutterEntry(
        figmaFrameName: String? = nil,
        output: String = "assets/images",
        scales: [Double]? = nil,
        format: String? = nil
    ) throws -> FlutterImagesEntry {
        var json = """
        {
            "output": "\(output)"
        """

        if let figmaFrameName {
            json = json.replacingOccurrences(of: "{", with: "{ \"figmaFrameName\": \"\(figmaFrameName)\",")
        }
        if let scales {
            let scalesJson = scales.map { String($0) }.joined(separator: ", ")
            json += ", \"scales\": [\(scalesJson)]"
        }
        if let format {
            json += ", \"format\": \"\(format)\""
        }
        json += "}"

        return try JSONDecoder().decode(FlutterImagesEntry.self, from: Data(json.utf8))
    }
}
