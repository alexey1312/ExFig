@testable import ExFigCore
import XCTest

final class DynamicTypeStyleTests: XCTestCase {
    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(DynamicTypeStyle.largeTitle.rawValue, "Large Title")
        XCTAssertEqual(DynamicTypeStyle.title1.rawValue, "Title 1")
        XCTAssertEqual(DynamicTypeStyle.title2.rawValue, "Title 2")
        XCTAssertEqual(DynamicTypeStyle.title3.rawValue, "Title 3")
        XCTAssertEqual(DynamicTypeStyle.headline.rawValue, "Headline")
        XCTAssertEqual(DynamicTypeStyle.body.rawValue, "Body")
        XCTAssertEqual(DynamicTypeStyle.callout.rawValue, "Callout")
        XCTAssertEqual(DynamicTypeStyle.subheadline.rawValue, "Subhead")
        XCTAssertEqual(DynamicTypeStyle.footnote.rawValue, "Footnote")
        XCTAssertEqual(DynamicTypeStyle.caption1.rawValue, "Caption 1")
        XCTAssertEqual(DynamicTypeStyle.caption2.rawValue, "Caption 2")
    }

    // MARK: - UIKit Style Names

    func testUIKitStyleNames() {
        XCTAssertEqual(DynamicTypeStyle.largeTitle.uiKitStyleName, "largeTitle")
        XCTAssertEqual(DynamicTypeStyle.title1.uiKitStyleName, "title1")
        XCTAssertEqual(DynamicTypeStyle.title2.uiKitStyleName, "title2")
        XCTAssertEqual(DynamicTypeStyle.title3.uiKitStyleName, "title3")
        XCTAssertEqual(DynamicTypeStyle.headline.uiKitStyleName, "headline")
        XCTAssertEqual(DynamicTypeStyle.body.uiKitStyleName, "body")
        XCTAssertEqual(DynamicTypeStyle.callout.uiKitStyleName, "callout")
        XCTAssertEqual(DynamicTypeStyle.subheadline.uiKitStyleName, "subheadline")
        XCTAssertEqual(DynamicTypeStyle.footnote.uiKitStyleName, "footnote")
        XCTAssertEqual(DynamicTypeStyle.caption1.uiKitStyleName, "caption1")
        XCTAssertEqual(DynamicTypeStyle.caption2.uiKitStyleName, "caption2")
    }

    // MARK: - SwiftUI Style Names

    func testSwiftUIStyleNames() {
        XCTAssertEqual(DynamicTypeStyle.largeTitle.swiftUIStyleName, "largeTitle")
        XCTAssertEqual(DynamicTypeStyle.title1.swiftUIStyleName, "title")
        XCTAssertEqual(DynamicTypeStyle.title2.swiftUIStyleName, "title2")
        XCTAssertEqual(DynamicTypeStyle.title3.swiftUIStyleName, "title3")
        XCTAssertEqual(DynamicTypeStyle.headline.swiftUIStyleName, "headline")
        XCTAssertEqual(DynamicTypeStyle.body.swiftUIStyleName, "body")
        XCTAssertEqual(DynamicTypeStyle.callout.swiftUIStyleName, "callout")
        XCTAssertEqual(DynamicTypeStyle.subheadline.swiftUIStyleName, "subheadline")
        XCTAssertEqual(DynamicTypeStyle.footnote.swiftUIStyleName, "footnote")
        XCTAssertEqual(DynamicTypeStyle.caption1.swiftUIStyleName, "caption")
        XCTAssertEqual(DynamicTypeStyle.caption2.swiftUIStyleName, "caption2")
    }
}

final class TextStyleTests: XCTestCase {
    // MARK: - Initialization

    func testInitWithRequiredParameters() {
        let style = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        XCTAssertEqual(style.name, "heading")
        XCTAssertEqual(style.fontName, "Helvetica")
        XCTAssertEqual(style.fontSize, 24)
        XCTAssertEqual(style.fontStyle, .title1)
        XCTAssertEqual(style.letterSpacing, 0.5)
        XCTAssertEqual(style.textCase, .original)
        XCTAssertNil(style.lineHeight)
        XCTAssertNil(style.platform)
    }

    func testInitWithAllParameters() {
        let style = TextStyle(
            name: "body",
            platform: .ios,
            fontName: "Arial",
            fontSize: 16,
            fontStyle: .body,
            lineHeight: 24,
            letterSpacing: 0.2,
            textCase: .uppercased
        )

        XCTAssertEqual(style.name, "body")
        XCTAssertEqual(style.platform, .ios)
        XCTAssertEqual(style.fontName, "Arial")
        XCTAssertEqual(style.fontSize, 16)
        XCTAssertEqual(style.fontStyle, .body)
        XCTAssertEqual(style.lineHeight, 24)
        XCTAssertEqual(style.letterSpacing, 0.2)
        XCTAssertEqual(style.textCase, .uppercased)
    }

    func testInitWithNilFontStyle() {
        let style = TextStyle(
            name: "custom",
            fontName: "CustomFont",
            fontSize: 18,
            fontStyle: nil,
            letterSpacing: 0
        )

        XCTAssertNil(style.fontStyle)
    }

    // MARK: - TextCase Enum

    func testTextCaseRawValues() {
        XCTAssertEqual(TextStyle.TextCase.original.rawValue, "original")
        XCTAssertEqual(TextStyle.TextCase.uppercased.rawValue, "uppercased")
        XCTAssertEqual(TextStyle.TextCase.lowercased.rawValue, "lowercased")
    }

    // MARK: - Equatable

    func testEqualityByName() {
        let style1 = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let style2 = TextStyle(
            name: "heading",
            fontName: "Arial",
            fontSize: 16,
            fontStyle: .body,
            letterSpacing: 0
        )

        XCTAssertEqual(style1, style2)
    }

    func testInequalityByName() {
        let style1 = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let style2 = TextStyle(
            name: "body",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        XCTAssertNotEqual(style1, style2)
    }

    // MARK: - Hashable

    func testHashValue() {
        let style1 = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let style2 = TextStyle(
            name: "heading",
            fontName: "Arial",
            fontSize: 16,
            fontStyle: .body,
            letterSpacing: 0
        )

        XCTAssertEqual(style1.hashValue, style2.hashValue)
    }

    func testHashableInSet() {
        let style1 = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let style2 = TextStyle(
            name: "body",
            fontName: "Arial",
            fontSize: 16,
            fontStyle: .body,
            letterSpacing: 0
        )

        let set: Set<TextStyle> = [style1, style2]

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Mutable Name

    func testMutableName() {
        var style = TextStyle(
            name: "old",
            fontName: "Font",
            fontSize: 12,
            fontStyle: nil,
            letterSpacing: 0
        )

        style.name = "new"

        XCTAssertEqual(style.name, "new")
    }
}
