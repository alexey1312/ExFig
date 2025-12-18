@testable import ExFigCore
import XCTest

final class StringCaseTests: XCTestCase {
    func testSnakeCase() throws {
        XCTAssertTrue("snake".isSnakeCase)
        XCTAssertTrue("snake_case".isSnakeCase)
        XCTAssertTrue("snake_case_example".isSnakeCase)
        XCTAssertFalse("NOTSNAKECASE".isSnakeCase)
        XCTAssertFalse("not_a_SNAKECASE_String".isSnakeCase)
        XCTAssertFalse("notSnakeCase".isSnakeCase)
        XCTAssertFalse("AlsoNotSnakeCase".isSnakeCase)

        XCTAssertEqual("snake".snakeCased(), "snake")
        XCTAssertEqual("snake cased".snakeCased(), "snake_cased")
        XCTAssertEqual("snakeCased".snakeCased(), "snake_cased")
        XCTAssertEqual("snake Cased_String".snakeCased(), "snake_cased_string")
        XCTAssertEqual("_this is*  not-Very%difficult".snakeCased(), "this_is_not_very_difficult")
        XCTAssertEqual("snakeCASE".snakeCased(), "snake_case")
    }

    func testLowerCamelCase() throws {
        XCTAssertTrue("lower".isLowerCamelCase)
        XCTAssertTrue("lowerCamelCase".isLowerCamelCase)
        XCTAssertFalse("lowerCamelCase_with_underscore".isLowerCamelCase)
        XCTAssertFalse("UpperCamelCase".isLowerCamelCase)
        XCTAssertFalse("snake_case".isLowerCamelCase)

        XCTAssertEqual("lower".lowerCamelCased(), "lower")
        XCTAssertEqual("LowerCamelCased".lowerCamelCased(), "lowerCamelCased")
        XCTAssertEqual("lower_camel_cased".lowerCamelCased(), "lowerCamelCased")
        XCTAssertEqual("Lower Camel cased".lowerCamelCased(), "lowerCamelCased")
        XCTAssertEqual("_this is*  not-Very%difficult".lowerCamelCased(), "thisIsNotVeryDifficult")
    }

    func testPascalCase() throws {
        XCTAssertEqual("pascal".camelCased(), "Pascal")
        XCTAssertEqual("PascalCase".camelCased(), "PascalCase")
        XCTAssertEqual("pascal_case".camelCased(), "PascalCase")
        XCTAssertEqual("Pascal Case".camelCased(), "PascalCase")
        XCTAssertEqual("_this is*  not-Very%difficult".camelCased(), "ThisIsNotVeryDifficult")
    }

    func testKebabCase() throws {
        XCTAssertEqual("kebab".kebabCased(), "kebab")
        XCTAssertEqual("kebab-case".kebabCased(), "kebab-case")
        XCTAssertEqual("kebabCase".kebabCased(), "kebab-case")
        XCTAssertEqual("Kebab Case".kebabCased(), "kebab-case")
        XCTAssertEqual("kebab_case".kebabCased(), "kebab-case")
        XCTAssertEqual("_this is*  not-Very%difficult".kebabCased(), "this-is-not-very-difficult")
    }

    func testScreamingSnakeCase() throws {
        XCTAssertEqual("screaming".screamingSnakeCased(), "SCREAMING")
        XCTAssertEqual("SCREAMING_SNAKE".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("screamingSnake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("Screaming Snake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("screaming_snake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("_this is*  not-Very%difficult".screamingSnakeCased(), "THIS_IS_NOT_VERY_DIFFICULT")
    }

    func testNumbersInNames() throws {
        // snake_case - numbers should stay with preceding letters
        XCTAssertEqual("discount10".snakeCased(), "discount10")
        XCTAssertEqual("discount10Color".snakeCased(), "discount10_color")
        XCTAssertEqual("indrive-passenger-discount10-color".snakeCased(), "indrive_passenger_discount10_color")
        XCTAssertEqual("icon24px".snakeCased(), "icon24px")
        XCTAssertEqual("icon24pxBold".snakeCased(), "icon24px_bold")

        // kebab-case
        XCTAssertEqual("discount10Color".kebabCased(), "discount10-color")
        XCTAssertEqual("icon24pxBold".kebabCased(), "icon24px-bold")

        // SCREAMING_SNAKE_CASE
        XCTAssertEqual("discount10Color".screamingSnakeCased(), "DISCOUNT10_COLOR")
        XCTAssertEqual("icon24pxBold".screamingSnakeCased(), "ICON24PX_BOLD")

        // camelCase - numbers from snake_case input
        XCTAssertEqual("discount_10_color".lowerCamelCased(), "discount10Color")
        XCTAssertEqual("discount-10-color".lowerCamelCased(), "discount10Color")

        // PascalCase
        XCTAssertEqual("discount_10_color".camelCased(), "Discount10Color")
    }
}
