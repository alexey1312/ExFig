@testable import ExFigCore
import XCTest

final class StringCaseTests: XCTestCase {
    func testSnakeCase() {
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

    func testLowerCamelCase() {
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

    func testPascalCase() {
        XCTAssertEqual("pascal".camelCased(), "Pascal")
        XCTAssertEqual("PascalCase".camelCased(), "PascalCase")
        XCTAssertEqual("pascal_case".camelCased(), "PascalCase")
        XCTAssertEqual("Pascal Case".camelCased(), "PascalCase")
        XCTAssertEqual("_this is*  not-Very%difficult".camelCased(), "ThisIsNotVeryDifficult")
    }

    func testKebabCase() {
        // isKebabCase checks
        XCTAssertTrue("kebab".isKebabCase)
        XCTAssertTrue("kebab-case".isKebabCase)
        XCTAssertTrue("kebab-case-example".isKebabCase)
        XCTAssertTrue("kebab-case-with-123".isKebabCase)
        XCTAssertFalse("NOTKEBABCASE".isKebabCase)
        XCTAssertFalse("not-a-KEBABCASE-String".isKebabCase)
        XCTAssertFalse("notKebabCase".isKebabCase)
        XCTAssertFalse("AlsoNotKebabCase".isKebabCase)

        // kebabCased() conversions
        XCTAssertEqual("kebab".kebabCased(), "kebab")
        XCTAssertEqual("kebab-case".kebabCased(), "kebab-case")
        XCTAssertEqual("kebabCase".kebabCased(), "kebab-case")
        XCTAssertEqual("Kebab Case".kebabCased(), "kebab-case")
        XCTAssertEqual("kebab_case".kebabCased(), "kebab-case")
        XCTAssertEqual("_this is*  not-Very%difficult".kebabCased(), "this-is-not-very-difficult")

        // snake_case to kebab-case - numbers stay attached
        XCTAssertEqual("motive_box04_color".kebabCased(), "motive-box04-color")
        XCTAssertEqual("icon_24px".kebabCased(), "icon-24px")
    }

    func testScreamingSnakeCase() {
        XCTAssertEqual("screaming".screamingSnakeCased(), "SCREAMING")
        XCTAssertEqual("SCREAMING_SNAKE".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("screamingSnake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("Screaming Snake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("screaming_snake".screamingSnakeCased(), "SCREAMING_SNAKE")
        XCTAssertEqual("_this is*  not-Very%difficult".screamingSnakeCased(), "THIS_IS_NOT_VERY_DIFFICULT")
    }

    func testNumbersInNames() {
        // snake_case from CamelCase - numbers are separated from preceding letters
        XCTAssertEqual("discount10".snakeCased(), "discount10") // already snake_case
        XCTAssertEqual("discount10Color".snakeCased(), "discount_10_color")
        XCTAssertEqual("icon24px".snakeCased(), "icon24px") // already snake_case
        XCTAssertEqual("icon24pxBold".snakeCased(), "icon_24px_bold")

        // kebab-case to snake_case - numbers stay attached (image naming)
        XCTAssertEqual("promo-banner-discount5-color".snakeCased(), "promo_banner_discount5_color")
        XCTAssertEqual("illustration-hero-v2-large".snakeCased(), "illustration_hero_v2_large")
        XCTAssertEqual("icon-24px".snakeCased(), "icon_24px")

        // kebab-case
        XCTAssertEqual("discount10Color".kebabCased(), "discount-10-color")
        XCTAssertEqual("icon24pxBold".kebabCased(), "icon-24px-bold")

        // SCREAMING_SNAKE_CASE
        XCTAssertEqual("discount10Color".screamingSnakeCased(), "DISCOUNT_10_COLOR")
        XCTAssertEqual("icon24pxBold".screamingSnakeCased(), "ICON_24PX_BOLD")

        // camelCase - numbers from snake_case input
        XCTAssertEqual("discount_10_color".lowerCamelCased(), "discount10Color")
        XCTAssertEqual("discount-10-color".lowerCamelCased(), "discount10Color")

        // PascalCase
        XCTAssertEqual("discount_10_color".camelCased(), "Discount10Color")

        // Regression tests for Figma Variables color naming (the actual bug case)
        // PascalCase input -> numbers separated
        XCTAssertEqual("Additional01".snakeCased(), "additional_01")
        XCTAssertEqual("Additional01Pressed".snakeCased(), "additional_01_pressed")
        XCTAssertEqual(
            "Statement_Background_Additional01Pressed".snakeCased(),
            "statement_background_additional_01_pressed"
        )

        // Already snake_case should return unchanged
        XCTAssertEqual("additional_01".snakeCased(), "additional_01")
        XCTAssertEqual("additional_background_additional_01".snakeCased(), "additional_background_additional_01")

        // Corner cases - numbers at boundaries
        XCTAssertEqual("123abc".snakeCased(), "123abc") // already snake_case (all lowercase + numbers)
        XCTAssertEqual("abc123".snakeCased(), "abc123") // already snake_case
        XCTAssertEqual("Abc123".snakeCased(), "abc_123") // PascalCase input
        XCTAssertEqual("ABC123".snakeCased(), "abc_123") // All caps input
        XCTAssertEqual("abc-123-def".snakeCased(), "abc_123_def") // kebab with standalone number

        // Corner cases - mixed separators
        XCTAssertEqual("hello_world-test".snakeCased(), "hello_world_test") // mixed -> kebab wins first, then snake
        XCTAssertEqual("hello-world_test".snakeCased(), "hello_world_test")
    }
}
