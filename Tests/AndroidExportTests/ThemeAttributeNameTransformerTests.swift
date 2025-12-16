@testable import AndroidExport
import ExFigCore
import XCTest

final class ThemeAttributeNameTransformerTests: XCTestCase {
    // MARK: - Basic Transformation (Default Settings)

    func testBasicTransformation() {
        let transformer = ThemeAttributeNameTransformer()
        XCTAssertEqual(transformer.transform("background_primary"), "colorBackgroundPrimary")
    }

    func testMultipleWordsTransformation() {
        let transformer = ThemeAttributeNameTransformer()
        XCTAssertEqual(transformer.transform("text_and_icon_primary"), "colorTextAndIconPrimary")
    }

    func testSingleWordTransformation() {
        let transformer = ThemeAttributeNameTransformer()
        XCTAssertEqual(transformer.transform("primary"), "colorPrimary")
    }

    // MARK: - Prefix Stripping

    func testPrefixStripping() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("extensions_background_error"), "colorBackgroundError")
    }

    func testMultiplePrefixStrippingOptions() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: ["extensions_", "information_", "statement_", "additional_"],
            style: .pascalCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("extensions_background_error"), "colorBackgroundError")
        XCTAssertEqual(transformer.transform("information_text_primary"), "colorTextPrimary")
        XCTAssertEqual(transformer.transform("statement_border_focused"), "colorBorderFocused")
        XCTAssertEqual(transformer.transform("additional_icon_warning"), "colorIconWarning")
    }

    func testPrefixStrippingOnlyFirst() {
        // Should only strip the first matching prefix
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )
        XCTAssertEqual(
            transformer.transform("extensions_extensions_double"),
            "colorExtensionsDouble"
        )
    }

    func testNoMatchingPrefix() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("background_secondary"), "colorBackgroundSecondary")
    }

    // MARK: - Different Styles

    func testCamelCaseStyle() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .camelCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("background_primary"), "colorBackgroundPrimary")
    }

    func testSnakeCaseStyle() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .snakeCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("background_primary"), "color_background_primary")
    }

    func testKebabCaseStyle() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .kebabCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("background_primary"), "color-background-primary")
    }

    func testScreamingSnakeCaseStyle() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .screamingSnakeCase,
            prefix: "color"
        )
        XCTAssertEqual(transformer.transform("background_primary"), "COLOR_BACKGROUND_PRIMARY")
    }

    // MARK: - Custom Prefix

    func testCustomPrefix() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .pascalCase,
            prefix: "theme"
        )
        XCTAssertEqual(transformer.transform("background_primary"), "themeBackgroundPrimary")
    }

    func testEmptyPrefix() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: [],
            style: .pascalCase,
            prefix: ""
        )
        XCTAssertEqual(transformer.transform("background_primary"), "BackgroundPrimary")
    }

    // MARK: - Real-World Examples from Requirements

    func testRealWorldExamples() {
        let transformer = ThemeAttributeNameTransformer(
            stripPrefixes: ["extensions_", "information_", "statement_", "additional_"],
            style: .pascalCase,
            prefix: "color"
        )

        // Examples from the spec
        XCTAssertEqual(transformer.transform("background_primary"), "colorBackgroundPrimary")
        XCTAssertEqual(transformer.transform("extensions_background_error"), "colorBackgroundError")
        XCTAssertEqual(transformer.transform("text_and_icon_primary"), "colorTextAndIconPrimary")
        XCTAssertEqual(transformer.transform("statement_border_focused"), "colorBorderFocused")
    }
}
