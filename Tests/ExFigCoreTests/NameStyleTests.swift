@testable import ExFigCore
import XCTest

final class NameStyleTests: XCTestCase {
    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(NameStyle.camelCase.rawValue, "camelCase")
        XCTAssertEqual(NameStyle.snakeCase.rawValue, "snake_case")
        XCTAssertEqual(NameStyle.pascalCase.rawValue, "PascalCase")
        XCTAssertEqual(NameStyle.kebabCase.rawValue, "kebab-case")
        XCTAssertEqual(NameStyle.screamingSnakeCase.rawValue, "SCREAMING_SNAKE_CASE")
    }

    // MARK: - Initialization from Raw Value

    func testInitFromRawValueCamelCase() {
        let style = NameStyle(rawValue: "camelCase")

        XCTAssertEqual(style, .camelCase)
    }

    func testInitFromRawValueSnakeCase() {
        let style = NameStyle(rawValue: "snake_case")

        XCTAssertEqual(style, .snakeCase)
    }

    func testInitFromRawValuePascalCase() {
        let style = NameStyle(rawValue: "PascalCase")

        XCTAssertEqual(style, .pascalCase)
    }

    func testInitFromRawValueKebabCase() {
        let style = NameStyle(rawValue: "kebab-case")

        XCTAssertEqual(style, .kebabCase)
    }

    func testInitFromRawValueScreamingSnakeCase() {
        let style = NameStyle(rawValue: "SCREAMING_SNAKE_CASE")

        XCTAssertEqual(style, .screamingSnakeCase)
    }

    func testInitFromInvalidRawValue() {
        let style = NameStyle(rawValue: "invalid")

        XCTAssertNil(style)
    }

    // MARK: - CaseIterable Conformance

    func testAllCasesCount() {
        XCTAssertEqual(NameStyle.allCases.count, 6)
    }

    func testAllCasesContainsExpectedValues() {
        let allCases = NameStyle.allCases

        XCTAssertTrue(allCases.contains(.camelCase))
        XCTAssertTrue(allCases.contains(.snakeCase))
        XCTAssertTrue(allCases.contains(.pascalCase))
        XCTAssertTrue(allCases.contains(.flatCase))
        XCTAssertTrue(allCases.contains(.kebabCase))
        XCTAssertTrue(allCases.contains(.screamingSnakeCase))
    }

    // MARK: - Decodable Conformance

    func testDecodeCamelCase() throws {
        let json = Data("\"camelCase\"".utf8)

        let decoded = try JSONDecoder().decode(NameStyle.self, from: json)

        XCTAssertEqual(decoded, .camelCase)
    }

    func testDecodeSnakeCase() throws {
        let json = Data("\"snake_case\"".utf8)

        let decoded = try JSONDecoder().decode(NameStyle.self, from: json)

        XCTAssertEqual(decoded, .snakeCase)
    }

    func testDecodePascalCase() throws {
        let json = Data("\"PascalCase\"".utf8)

        let decoded = try JSONDecoder().decode(NameStyle.self, from: json)

        XCTAssertEqual(decoded, .pascalCase)
    }

    func testDecodeKebabCase() throws {
        let json = Data("\"kebab-case\"".utf8)

        let decoded = try JSONDecoder().decode(NameStyle.self, from: json)

        XCTAssertEqual(decoded, .kebabCase)
    }

    func testDecodeScreamingSnakeCase() throws {
        let json = Data("\"SCREAMING_SNAKE_CASE\"".utf8)

        let decoded = try JSONDecoder().decode(NameStyle.self, from: json)

        XCTAssertEqual(decoded, .screamingSnakeCase)
    }

    func testDecodeInvalidValueThrows() {
        let json = Data("\"unknown_style\"".utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(NameStyle.self, from: json))
    }

    // MARK: - Sendable Conformance

    func testSendableConformance() async {
        let style: NameStyle = .camelCase

        let result = await Task {
            style.rawValue
        }.value

        XCTAssertEqual(result, "camelCase")
    }

    // MARK: - Equatable

    func testEquality() {
        XCTAssertEqual(NameStyle.camelCase, NameStyle.camelCase)
        XCTAssertEqual(NameStyle.snakeCase, NameStyle.snakeCase)
    }

    func testInequality() {
        XCTAssertNotEqual(NameStyle.camelCase, NameStyle.snakeCase)
        XCTAssertNotEqual(NameStyle.pascalCase, NameStyle.kebabCase)
    }
}
