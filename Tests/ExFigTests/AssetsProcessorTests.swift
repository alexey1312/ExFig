// swiftlint:disable file_length type_body_length
import ExFigCore
import XCTest

final class AssetsProcessorTests: XCTestCase {
    func testProcessCamelCase() throws {
        let images = [
            ImagePack(image: Image(name: "ic_24_icon", url: URL(string: "1")!, format: "pdf")),
            ImagePack(image: Image(name: "ic_24_icon_name", url: URL(string: "2")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .camelCase
        )
        let icons = try processor.process(assets: images).get()

        XCTAssertEqual(
            icons.map(\.name),
            ["ic24Icon", "ic24IconName"]
        )
    }

    func testProcessSnakeCase() throws {
        let images = [
            ImagePack(image: Image(name: "ic/24/Icon", url: URL(string: "1")!, format: "pdf")),
            ImagePack(image: Image(name: "ic/24/icon/name", url: URL(string: "2")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .android,
            nameStyle: .snakeCase
        )
        let icons = try processor.process(assets: images).get()

        XCTAssertEqual(
            icons.map(\.name),
            ["ic_24_icon", "ic_24_icon_name"]
        )
    }

    func testProcessWithValidateAndReplace() throws {
        let images = [
            ImagePack(image: Image(name: "ic_24_icon", url: URL(string: "1")!, format: "pdf")),
            ImagePack(image: Image(name: "ic_24_icon_name", url: URL(string: "2")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: #"^(ic)_(\d\d)_([a-z0-9_]+)$"#,
            nameReplaceRegexp: #"icon_$2_$3"#,
            nameStyle: .camelCase
        )
        let icons = try processor.process(assets: images).get()

        XCTAssertEqual(
            icons.map(\.name),
            ["icon24Icon", "icon24IconName"]
        )
    }

    func testProcessWithReplaceImageNameInSnakeCase() throws {
        let images = [
            ImagePack(image: Image(name: "32 - Profile", url: URL(string: "1")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: "^(\\d\\d) - ([A-Za-z0-9 ]+)$",
            nameReplaceRegexp: #"icon_$2_$1"#,
            nameStyle: .snakeCase
        )
        let icons = try processor.process(assets: images).get()

        XCTAssertEqual(
            icons.map(\.name),
            ["icon_profile_32"]
        )
    }

    func testProcessWithReplaceImageName() throws {
        let images = [
            ImagePack(image: Image(name: "32 - Profile", url: URL(string: "1")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: "^(\\d\\d) - ([A-Za-z0-9 ]+)$",
            nameReplaceRegexp: #"icon_$2_$1"#,
            nameStyle: .snakeCase
        )
        let icons = try processor.process(light: images, dark: nil).get()

        XCTAssertEqual(
            icons.map(\.light.name),
            ["icon_profile_32"]
        )
    }

    func testProcessWithReplaceImageName2() throws {
        let images = [
            ImagePack(image: Image(name: "32 - Profile", url: URL(string: "1")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: "^(\\d\\d) - ([A-Za-z0-9 ]+)$",
            nameReplaceRegexp: #"icon_$2_$1"#,
            nameStyle: .snakeCase
        )
        let icons = try processor.process(light: images, dark: images).get()

        XCTAssertEqual(
            [icons.map(\.light.name), icons.map { $0.dark!.name }],
            [["icon_profile_32"], ["icon_profile_32"]]
        )
    }

    func testProcessWithReplaceForInvalidAsssetName() throws {
        let images = [
            ImagePack(image: Image(name: "ic24", url: URL(string: "1")!, format: "pdf")),
        ]

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: #"^(ic)_(\d\d)_([a-z0-9_]+)$"#,
            nameReplaceRegexp: #"icon_$2_$3"#,
            nameStyle: .camelCase
        )

        XCTAssertThrowsError(try processor.process(assets: images).get())
    }

    // Light count can exceed dark count
    func testProcessWithUniversalAsset() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darks = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )
        let colors = try processor.process(light: lights, dark: darks).get()

        XCTAssertEqual(
            [colors.compactMap(\.light.name), colors.compactMap { $0.dark?.name }],
            [["primaryLink", "primaryText"], ["primaryText"]]
        )
    }

    // Dark count cannot exceed light count
    func testProcessWithUniversalAsset2() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darks = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertThrowsError(try processor.process(light: lights, dark: darks).get())
    }

    // Light count can exceed lightHC count
    func testProcessWithUniversalAsset3() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let lightHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )
        let colors = try processor.process(light: lights, dark: nil, lightHC: lightHC).get()

        XCTAssertEqual(
            [colors.compactMap(\.light.name), colors.compactMap { $0.lightHC?.name }],
            [["primaryLink", "primaryText"], ["primaryText"]]
        )
    }

    // LightHC count cannot exceed light count
    func testProcessWithUniversalAsset4() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let lightHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryIcon", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertThrowsError(try processor.process(light: lights, dark: nil, lightHC: lightHC).get())
    }

    // LightHC count cannot exceed light count
    func testProcessWithUniversalAsset5() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darks = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let lightsHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryIcon", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertThrowsError(try processor.process(light: lights, dark: darks, lightHC: lightsHC).get())
    }

    // DarkHC count cannot exceed lightHC count
    func testProcessWithUniversalAsset6() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darks = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let lightsHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darksHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryIcon", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )

        XCTAssertThrowsError(try processor.process(light: lights, dark: darks, lightHC: lightsHC, darkHC: darksHC)
            .get())
    }

    // Light count can exceed dark, lightHC and darkHC count
    func testProcessWithUniversalAsset7() throws {
        let lights = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryIcon", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darks = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let lightHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
            Color(name: "primaryLink", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let darkHC = [
            Color(name: "primaryText", platform: .ios, red: 0, green: 0, blue: 0, alpha: 0),
        ]

        let processor = ColorsProcessor(
            platform: .ios,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase
        )
        let colors = try processor.process(light: lights, dark: darks, lightHC: lightHC, darkHC: darkHC).get()

        XCTAssertEqual(
            [
                colors.compactMap(\.light.name),
                colors.compactMap { $0.dark?.name },
                colors.compactMap { $0.lightHC?.name },
                colors.compactMap { $0.darkHC?.name },
            ],
            [
                ["primaryIcon", "primaryLink", "primaryText"],
                ["primaryLink", "primaryText"],
                ["primaryLink", "primaryText"],
                ["primaryText"],
            ]
        )
    }

    func testProcess() throws {
        let images = [
            ImagePack(
                image: Image(name: "icons / 24 / arrow back", url: URL(string: "/")!, format: "png"),
                platform: .android
            ),
        ]

        let processor = ImagesProcessor(
            platform: .android,
            nameValidateRegexp: #"^icons _ (\d\d) _ ([A-Za-z0-9 /_-]+)$"#,
            nameReplaceRegexp: #"n2_icon_$2_$1"#,
            nameStyle: .snakeCase
        )

        let result = processor.process(assets: images)

        let extracted = try result.get()

        XCTAssertEqual(extracted[0].name, "n2_icon_arrow_back_24")
    }

    // MARK: - processNames tests (granular cache support)

    func testProcessNamesWithCamelCase() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .camelCase
        )

        let names = ["motive-box-04-color", "ic_24_icon", "some/name"]
        let result = processor.processNames(names)

        XCTAssertEqual(result, ["motiveBox04Color", "ic24Icon", "someName"])
    }

    func testProcessNamesWithSnakeCase() {
        let processor = ImagesProcessor(
            platform: .android,
            nameStyle: .snakeCase
        )

        // CamelCase input: numbers get separated (like color naming)
        let camelCaseNames = ["motiveBox04Color", "IconName", "some/name"]
        let camelCaseResult = processor.processNames(camelCaseNames)
        XCTAssertEqual(camelCaseResult, ["motive_box_04_color", "icon_name", "some_name"])

        // kebab-case input: numbers stay attached (like image naming from Figma)
        let kebabCaseNames = ["motive-box04-color", "icon-name"]
        let kebabCaseResult = processor.processNames(kebabCaseNames)
        XCTAssertEqual(kebabCaseResult, ["motive_box04_color", "icon_name"])
    }

    func testProcessNamesWithPascalCase() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .pascalCase
        )

        let names = ["motive-box-04-color", "ic_24_icon", "some/name"]
        let result = processor.processNames(names)

        XCTAssertEqual(result, ["MotiveBox04Color", "Ic24Icon", "SomeName"])
    }

    func testProcessNamesWithKebabCase() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .kebabCase
        )

        // CamelCase input: numbers get separated
        let camelCaseNames = ["motiveBox04Color", "IconName", "some_name"]
        let camelCaseResult = processor.processNames(camelCaseNames)
        XCTAssertEqual(camelCaseResult, ["motive-box-04-color", "icon-name", "some-name"])

        // snake_case input with numbers: numbers stay attached
        let snakeCaseNames = ["motive_box04_color", "icon_name"]
        let snakeCaseResult = processor.processNames(snakeCaseNames)
        XCTAssertEqual(snakeCaseResult, ["motive-box04-color", "icon-name"])
    }

    func testProcessNamesWithScreamingSnakeCase() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .screamingSnakeCase
        )

        let names = ["motive-box-04-color", "ic_24_icon", "some/name"]
        let result = processor.processNames(names)

        XCTAssertEqual(result, ["MOTIVE_BOX_04_COLOR", "IC_24_ICON", "SOME_NAME"])
    }

    func testProcessNamesWithoutNameStyle() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: nil
        )

        let names = ["motive-box-04-color", "ic_24_icon"]
        let result = processor.processNames(names)

        // Without nameStyle, names should be returned as-is (with / normalization)
        XCTAssertEqual(result, ["motive-box-04-color", "ic_24_icon"])
    }

    func testProcessNamesWithSlashNormalization() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .camelCase
        )

        let names = ["icons/arrow", "icons/icons"]
        let result = processor.processNames(names)

        // "icons/icons" should become "icons" (duplication removed)
        // "icons/arrow" should become "icons_arrow" then camelCased
        XCTAssertEqual(result, ["iconsArrow", "icons"])
    }

    func testProcessNamesWithValidateAndReplace() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: #"^ic_(\d\d)_(.+)$"#,
            nameReplaceRegexp: #"icon_$1_$2"#,
            nameStyle: .camelCase
        )

        let names = ["ic_24_arrow", "ic_32_back"]
        let result = processor.processNames(names)

        XCTAssertEqual(result, ["icon24Arrow", "icon32Back"])
    }

    func testProcessNamesIgnoresNonMatchingRegexp() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: #"^ic_(\d\d)_(.+)$"#,
            nameReplaceRegexp: #"icon_$1_$2"#,
            nameStyle: .camelCase
        )

        // "no_match" doesn't match the regexp, so it should be processed without replacement
        let names = ["ic_24_arrow", "no_match"]
        let result = processor.processNames(names)

        XCTAssertEqual(result, ["icon24Arrow", "noMatch"])
    }

    func testProcessNamesEmptyArray() {
        let processor = ImagesProcessor(
            platform: .ios,
            nameStyle: .camelCase
        )

        let result = processor.processNames([])

        XCTAssertEqual(result, [])
    }
}
