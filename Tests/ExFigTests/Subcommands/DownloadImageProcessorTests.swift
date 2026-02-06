@testable import ExFigCLI
@testable import ExFigCore
import Foundation
import XCTest

final class DownloadImageProcessorTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let testURL = URL(string: "https://figma.com/image.png")!

    // MARK: - processName Tests

    func testProcessNameNormalizesPathSeparators() {
        let result = DownloadImageProcessor.processName(
            "icons/arrow/left",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: nil
        )

        XCTAssertEqual(result, "icons_arrow_left")
    }

    func testProcessNameAppliesCamelCase() {
        let result = DownloadImageProcessor.processName(
            "my_icon_name",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertEqual(result, "myIconName")
    }

    func testProcessNameAppliesSnakeCase() {
        let result = DownloadImageProcessor.processName(
            "myIconName",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .snakeCase
        )

        XCTAssertEqual(result, "my_icon_name")
    }

    func testProcessNameAppliesPascalCase() {
        let result = DownloadImageProcessor.processName(
            "my_icon_name",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .pascalCase
        )

        XCTAssertEqual(result, "MyIconName")
    }

    func testProcessNameAppliesKebabCase() {
        let result = DownloadImageProcessor.processName(
            "myIconName",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .kebabCase
        )

        XCTAssertEqual(result, "my-icon-name")
    }

    func testProcessNameAppliesScreamingSnakeCase() {
        let result = DownloadImageProcessor.processName(
            "myIconName",
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .screamingSnakeCase
        )

        XCTAssertEqual(result, "MY_ICON_NAME")
    }

    func testProcessNameWithRegexReplacement() {
        let result = DownloadImageProcessor.processName(
            "icon/24/arrow_left",
            validateRegexp: "^icon_(.*)$",
            replaceRegexp: "ic_$1",
            nameStyle: nil
        )

        // Path separators are normalized first, then regex is applied
        XCTAssertEqual(result, "ic_24_arrow_left")
    }

    func testProcessNameWithRegexAndNameStyle() {
        let result = DownloadImageProcessor.processName(
            "icon/24/arrow_left",
            validateRegexp: "^icon_(.*)$",
            replaceRegexp: "$1",
            nameStyle: .camelCase
        )

        // Path separators normalized -> regex applied -> name style applied
        XCTAssertEqual(result, "24ArrowLeft")
    }

    func testProcessNameIgnoresInvalidRegex() {
        let result = DownloadImageProcessor.processName(
            "my_icon",
            validateRegexp: "[invalid", // Invalid regex
            replaceRegexp: "replaced",
            nameStyle: nil
        )

        // Should still normalize path separators even if regex is invalid
        XCTAssertEqual(result, "my_icon")
    }

    func testProcessNameRequiresBothRegexPatterns() {
        // Only validateRegexp, no replaceRegexp
        let result1 = DownloadImageProcessor.processName(
            "icon/name",
            validateRegexp: "^icon_(.*)$",
            replaceRegexp: nil,
            nameStyle: nil
        )
        XCTAssertEqual(result1, "icon_name") // Only normalization

        // Only replaceRegexp, no validateRegexp
        let result2 = DownloadImageProcessor.processName(
            "icon/name",
            validateRegexp: nil,
            replaceRegexp: "replaced",
            nameStyle: nil
        )
        XCTAssertEqual(result2, "icon_name") // Only normalization
    }

    // MARK: - processNames Tests

    func testProcessNamesTransformsAllPacks() {
        let packs = [
            makeImagePack(name: "icon/arrow"),
            makeImagePack(name: "icon/close"),
        ]

        let result = DownloadImageProcessor.processNames(
            packs,
            validateRegexp: nil,
            replaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "iconArrow")
        XCTAssertEqual(result[1].name, "iconClose")
    }

    // MARK: - splitByDarkMode Tests

    func testSplitByDarkModeWithNilSuffix() {
        let packs = [
            makeImagePack(name: "icon"),
            makeImagePack(name: "icon_dark"),
        ]

        let (light, dark) = DownloadImageProcessor.splitByDarkMode(packs, darkSuffix: nil)

        XCTAssertEqual(light.count, 2)
        XCTAssertNil(dark)
    }

    func testSplitByDarkModeSeparatesPacks() {
        let packs = [
            makeImagePack(name: "logo"),
            makeImagePack(name: "logo_dark"),
            makeImagePack(name: "banner"),
            makeImagePack(name: "banner_dark"),
            makeImagePack(name: "icon"),
        ]

        let (light, dark) = DownloadImageProcessor.splitByDarkMode(packs, darkSuffix: "_dark")

        XCTAssertEqual(light.count, 3)
        XCTAssertEqual(light.map(\.name).sorted(), ["banner", "icon", "logo"])

        XCTAssertNotNil(dark)
        XCTAssertEqual(dark?.count, 2)
        // Dark packs should have suffix stripped
        XCTAssertEqual(dark?.map(\.name).sorted(), ["banner", "logo"])
    }

    func testSplitByDarkModeWithNoDarkVariants() {
        let packs = [
            makeImagePack(name: "logo"),
            makeImagePack(name: "banner"),
        ]

        let (light, dark) = DownloadImageProcessor.splitByDarkMode(packs, darkSuffix: "_dark")

        XCTAssertEqual(light.count, 2)
        XCTAssertNil(dark)
    }

    func testSplitByDarkModeWithCustomSuffix() {
        let packs = [
            makeImagePack(name: "icon"),
            makeImagePack(name: "icon-night"),
        ]

        let (light, dark) = DownloadImageProcessor.splitByDarkMode(packs, darkSuffix: "-night")

        XCTAssertEqual(light.count, 1)
        XCTAssertEqual(light[0].name, "icon")

        XCTAssertNotNil(dark)
        XCTAssertEqual(dark?.count, 1)
        XCTAssertEqual(dark?[0].name, "icon")
    }

    // MARK: - createFileContents Tests

    func testCreateFileContentsForLightMode() {
        let packs = [makeImagePack(name: "icon")]
        let outputURL = URL(fileURLWithPath: "/tmp/output")

        let result = DownloadImageProcessor.createFileContents(
            from: packs,
            outputURL: outputURL,
            format: .png,
            dark: false,
            darkModeSuffix: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].destination.file.lastPathComponent, "icon.png")
        XCTAssertFalse(result[0].dark)
    }

    func testCreateFileContentsForDarkMode() {
        let packs = [makeImagePack(name: "icon")]
        let outputURL = URL(fileURLWithPath: "/tmp/output")

        let result = DownloadImageProcessor.createFileContents(
            from: packs,
            outputURL: outputURL,
            format: .png,
            dark: true,
            darkModeSuffix: "_dark"
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].destination.file.lastPathComponent, "icon_dark.png")
        XCTAssertTrue(result[0].dark)
    }

    func testCreateFileContentsForWebPUsesPngExtension() {
        // WebP files are downloaded as PNG first, then converted
        let packs = [makeImagePack(name: "image")]
        let outputURL = URL(fileURLWithPath: "/tmp/output")

        let result = DownloadImageProcessor.createFileContents(
            from: packs,
            outputURL: outputURL,
            format: .webp,
            dark: false,
            darkModeSuffix: nil
        )

        XCTAssertEqual(result.count, 1)
        // WebP downloads PNG first (conversion happens later)
        XCTAssertEqual(result[0].destination.file.lastPathComponent, "image.png")
    }

    func testCreateFileContentsForSVG() {
        let packs = [makeImagePack(name: "vector")]
        let outputURL = URL(fileURLWithPath: "/tmp/output")

        let result = DownloadImageProcessor.createFileContents(
            from: packs,
            outputURL: outputURL,
            format: .svg,
            dark: false,
            darkModeSuffix: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].destination.file.lastPathComponent, "vector.svg")
    }

    func testCreateFileContentsForMultiplePacks() {
        let packs = [
            makeImagePack(name: "icon1"),
            makeImagePack(name: "icon2"),
            makeImagePack(name: "icon3"),
        ]
        let outputURL = URL(fileURLWithPath: "/tmp/output")

        let result = DownloadImageProcessor.createFileContents(
            from: packs,
            outputURL: outputURL,
            format: .png,
            dark: false,
            darkModeSuffix: nil
        )

        XCTAssertEqual(result.count, 3)
        let fileNames = result.map(\.destination.file.lastPathComponent)
        XCTAssertTrue(fileNames.contains("icon1.png"))
        XCTAssertTrue(fileNames.contains("icon2.png"))
        XCTAssertTrue(fileNames.contains("icon3.png"))
    }

    // MARK: - applyNameStyle Tests

    func testApplyNameStyleCamelCase() {
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("my_icon", style: .camelCase), "myIcon")
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("MyIcon", style: .camelCase), "myIcon")
    }

    func testApplyNameStyleSnakeCase() {
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("myIcon", style: .snakeCase), "my_icon")
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("MyIcon", style: .snakeCase), "my_icon")
    }

    func testApplyNameStylePascalCase() {
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("my_icon", style: .pascalCase), "MyIcon")
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("myIcon", style: .pascalCase), "MyIcon")
    }

    func testApplyNameStyleKebabCase() {
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("myIcon", style: .kebabCase), "my-icon")
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("MyIcon", style: .kebabCase), "my-icon")
    }

    func testApplyNameStyleScreamingSnakeCase() {
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("myIcon", style: .screamingSnakeCase), "MY_ICON")
        XCTAssertEqual(DownloadImageProcessor.applyNameStyle("my_icon", style: .screamingSnakeCase), "MY_ICON")
    }

    // MARK: - Helper Methods

    private func makeImagePack(name: String) -> ImagePack {
        let image = Image(name: name, url: testURL, format: "png")
        return ImagePack(name: name, images: [image], platform: nil)
    }
}
