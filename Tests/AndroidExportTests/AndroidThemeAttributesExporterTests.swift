@testable import AndroidExport
import ExFigCore
import OrderedCollections
import XCTest

final class AndroidThemeAttributesExporterTests: XCTestCase {
    // MARK: - Basic Export

    func testBasicExport() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "background_primary", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.attrsContent.contains(
            "<attr name=\"colorBackgroundPrimary\" format=\"color\" />"
        ))
        XCTAssertTrue(result.stylesContent.contains(
            "<item name=\"colorBackgroundPrimary\">@color/background_primary</item>"
        ))
    }

    func testMultipleColors() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "background_primary", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "text_primary", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "border_default", red: 0.5, green: 0.5, blue: 0.5, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertEqual(result.count, 3)

        // Check attrs content
        XCTAssertTrue(result.attrsContent.contains("colorBackgroundPrimary"))
        XCTAssertTrue(result.attrsContent.contains("colorTextPrimary"))
        XCTAssertTrue(result.attrsContent.contains("colorBorderDefault"))

        // Check styles content
        XCTAssertTrue(result.stylesContent.contains("@color/background_primary"))
        XCTAssertTrue(result.stylesContent.contains("@color/text_primary"))
        XCTAssertTrue(result.stylesContent.contains("@color/border_default"))
    }

    // MARK: - Prefix Stripping

    func testPrefixStripping() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(
                light: Color(name: "extensions_background_error", red: 1, green: 0, blue: 0, alpha: 1),
                dark: nil
            ),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Should strip "extensions_" prefix
        XCTAssertTrue(result.attrsContent.contains("colorBackgroundError"))
        XCTAssertFalse(result.attrsContent.contains("colorExtensionsBackgroundError"))

        // But reference should use original XML name
        XCTAssertTrue(result.stylesContent.contains("@color/extensions_background_error"))
    }

    func testMultiplePrefixStripping() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_", "information_", "statement_", "additional_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(
                light: Color(name: "extensions_background_error", red: 1, green: 0, blue: 0, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "information_text_primary", red: 0, green: 0, blue: 1, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "statement_border_focused", red: 0, green: 1, blue: 0, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "background_primary", red: 1, green: 1, blue: 1, alpha: 1),
                dark: nil
            ),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Check stripped names
        XCTAssertTrue(result.attrsContent.contains("colorBackgroundError"))
        XCTAssertTrue(result.attrsContent.contains("colorTextPrimary"))
        XCTAssertTrue(result.attrsContent.contains("colorBorderFocused"))
        XCTAssertTrue(result.attrsContent.contains("colorBackgroundPrimary"))

        // Check original references preserved
        XCTAssertTrue(result.stylesContent.contains("@color/extensions_background_error"))
        XCTAssertTrue(result.stylesContent.contains("@color/information_text_primary"))
        XCTAssertTrue(result.stylesContent.contains("@color/statement_border_focused"))
        XCTAssertTrue(result.stylesContent.contains("@color/background_primary"))
    }

    // MARK: - Attribute Map

    func testAttributeMap() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(
                light: Color(name: "extensions_background_error", red: 1, green: 0, blue: 0, alpha: 1),
                dark: nil
            ),
            AssetPair(light: Color(name: "text_primary", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertEqual(result.attributeMap["colorBackgroundError"], "extensions_background_error")
        XCTAssertEqual(result.attributeMap["colorTextPrimary"], "text_primary")
    }

    // MARK: - Indentation

    func testAttrsIndentation() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "bg", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Should have 4-space indent for attrs
        XCTAssertTrue(result.attrsContent.hasPrefix("    <attr"))
    }

    func testStylesIndentation() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "bg", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Should have 8-space indent for style items (inside <style> tag)
        XCTAssertTrue(result.stylesContent.hasPrefix("        <item"))
    }

    // MARK: - Sorting

    func testOutputIsSorted() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "zebra", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "apple", red: 1, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "banana", red: 1, green: 1, blue: 0, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        let attrLines = result.attrsContent.split(separator: "\n").map(String.init)
        let styleLines = result.stylesContent.split(separator: "\n").map(String.init)

        // Should be sorted alphabetically by attribute name
        XCTAssertTrue(attrLines[0].contains("colorApple"))
        XCTAssertTrue(attrLines[1].contains("colorBanana"))
        XCTAssertTrue(attrLines[2].contains("colorZebra"))

        XCTAssertTrue(styleLines[0].contains("colorApple"))
        XCTAssertTrue(styleLines[1].contains("colorBanana"))
        XCTAssertTrue(styleLines[2].contains("colorZebra"))
    }

    // MARK: - Empty Input

    func testEmptyColorPairs() {
        let exporter = AndroidThemeAttributesExporter()

        let result = exporter.export(colorPairs: [])

        XCTAssertEqual(result.count, 0)
        XCTAssertTrue(result.attrsContent.isEmpty)
        XCTAssertTrue(result.stylesContent.isEmpty)
        XCTAssertTrue(result.attributeMap.isEmpty)
    }

    // MARK: - Custom Prefix

    func testCustomPrefix() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: [],
            style: .pascalCase,
            prefix: "theme"
        )

        let colorPairs = [
            AssetPair(light: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertTrue(result.attrsContent.contains("themeBackground"))
        XCTAssertTrue(result.stylesContent.contains("themeBackground"))
    }

    // MARK: - Real World Example

    func testRealWorldExample() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_", "information_", "statement_", "additional_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(
                light: Color(name: "background_primary", red: 1, green: 1, blue: 1, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "background_secondary", red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "extensions_background_error", red: 1, green: 0.9, blue: 0.9, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "text_and_icon_primary", red: 0, green: 0, blue: 0, alpha: 1),
                dark: nil
            ),
            AssetPair(
                light: Color(name: "statement_border_focused", red: 0, green: 0.5, blue: 1, alpha: 1),
                dark: nil
            ),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Expected attrs.xml content
        let expectedAttrs = [
            "    <attr name=\"colorBackgroundError\" format=\"color\" />",
            "    <attr name=\"colorBackgroundPrimary\" format=\"color\" />",
            "    <attr name=\"colorBackgroundSecondary\" format=\"color\" />",
            "    <attr name=\"colorBorderFocused\" format=\"color\" />",
            "    <attr name=\"colorTextAndIconPrimary\" format=\"color\" />",
        ]

        for expected in expectedAttrs {
            XCTAssertTrue(result.attrsContent.contains(expected), "Missing: \(expected)")
        }

        // Expected styles.xml content (with original @color/ references)
        let expectedStyles = [
            "        <item name=\"colorBackgroundError\">@color/extensions_background_error</item>",
            "        <item name=\"colorBackgroundPrimary\">@color/background_primary</item>",
            "        <item name=\"colorBackgroundSecondary\">@color/background_secondary</item>",
            "        <item name=\"colorBorderFocused\">@color/statement_border_focused</item>",
            "        <item name=\"colorTextAndIconPrimary\">@color/text_and_icon_primary</item>",
        ]

        for expected in expectedStyles {
            XCTAssertTrue(result.stylesContent.contains(expected), "Missing: \(expected)")
        }
    }

    // MARK: - Collision Detection

    func testCollisionDetection() {
        // Both colors will transform to "colorTextPrimary" when prefix is stripped
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(light: Color(name: "text_primary", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(
                light: Color(name: "extensions_text_primary", red: 1, green: 0, blue: 0, alpha: 1),
                dark: nil
            ),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // Should detect collision
        XCTAssertTrue(result.hasCollisions)
        XCTAssertEqual(result.collisions.count, 1)

        // First occurrence should be kept
        XCTAssertEqual(result.collisions[0].attributeName, "colorTextPrimary")
        XCTAssertEqual(result.collisions[0].keptXmlName, "text_primary")
        XCTAssertEqual(result.collisions[0].discardedXmlName, "extensions_text_primary")

        // Only one attribute should be in the output
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.attributeMap["colorTextPrimary"], "text_primary")
    }

    func testNoCollisionWithDifferentNames() {
        let exporter = AndroidThemeAttributesExporter()

        let colorPairs = [
            AssetPair(light: Color(name: "text_primary", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "text_secondary", red: 0.5, green: 0.5, blue: 0.5, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertFalse(result.hasCollisions)
        XCTAssertEqual(result.collisions.count, 0)
        XCTAssertEqual(result.count, 2)
    }

    func testMultipleCollisions() {
        let exporter = AndroidThemeAttributesExporter(
            stripPrefixes: ["extensions_", "info_"],
            style: .pascalCase,
            prefix: "color"
        )

        let colorPairs = [
            AssetPair(light: Color(name: "bg", red: 1, green: 1, blue: 1, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "extensions_bg", red: 0.9, green: 0.9, blue: 0.9, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "info_bg", red: 0.8, green: 0.8, blue: 0.8, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        XCTAssertTrue(result.hasCollisions)
        XCTAssertEqual(result.collisions.count, 2)
        XCTAssertEqual(result.count, 1) // Only first "bg" kept
    }

    // MARK: - OrderedDictionary

    func testAttributeMapPreservesInsertionOrder() {
        let exporter = AndroidThemeAttributesExporter()

        // Colors in specific order
        let colorPairs = [
            AssetPair(light: Color(name: "charlie", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "alpha", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
            AssetPair(light: Color(name: "bravo", red: 0, green: 0, blue: 0, alpha: 1), dark: nil),
        ]

        let result = exporter.export(colorPairs: colorPairs)

        // OrderedDictionary preserves insertion order
        let keys = Array(result.attributeMap.keys)
        XCTAssertEqual(keys[0], "colorCharlie")
        XCTAssertEqual(keys[1], "colorAlpha")
        XCTAssertEqual(keys[2], "colorBravo")
    }
}
