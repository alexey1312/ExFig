@testable import ExFigCore
import XCTest

final class AssetsValidatorErrorTests: XCTestCase {
    func testBadNameError() {
        let error = AssetsValidatorError.badName(name: "invalid name")

        XCTAssertEqual(error.errorDescription, "❌ Bad asset name «invalid name»")
    }

    func testCountMismatchError() {
        let error = AssetsValidatorError.countMismatch(light: 10, dark: 5)

        XCTAssertEqual(
            error.errorDescription,
            "❌ The number of assets doesn't match. Light theme contains 10, and dark 5."
        )
    }

    func testCountMismatchLightHighContrastColorsError() {
        let error = AssetsValidatorError.countMismatchLightHighContrastColors(light: 8, lightHC: 6)

        let expected = "❌ The number of assets doesn't match. " +
            "Light color palette contains 8, and light high contrast color palette 6."
        XCTAssertEqual(error.errorDescription, expected)
    }

    func testCountMismatchDarkHighContrastColorsError() {
        let error = AssetsValidatorError.countMismatchDarkHighContrastColors(dark: 7, darkHC: 4)

        let expected = "❌ The number of assets doesn't match. " +
            "Dark color palette contains 7, and dark high contrast color palette 4."
        XCTAssertEqual(error.errorDescription, expected)
    }

    func testFoundDuplicateError() {
        let error = AssetsValidatorError.foundDuplicate(assetName: "primaryColor")

        XCTAssertEqual(
            error.errorDescription,
            "❌ Found duplicates of asset with name primaryColor. Remove duplicates."
        )
    }

    func testSecondAssetsNotFoundInFirstPaletteError() {
        let error = AssetsValidatorError.secondAssetsNotFoundInFirstPalette(
            assets: ["color1", "color2"],
            firstAssetsName: "Light",
            secondAssetsName: "Dark"
        )

        XCTAssertTrue(error.errorDescription?.contains("color1, color2") == true)
        XCTAssertTrue(error.errorDescription?.contains("Light theme doesn't contains") == true)
    }

    func testDescriptionMismatchError() {
        let error = AssetsValidatorError.descriptionMismatch(
            assetName: "background",
            light: "Light background",
            dark: "Dark bg"
        )

        let expected = "❌ Asset with name background have different description. " +
            "In dark theme «Dark bg», in light theme «Light background»"
        XCTAssertEqual(error.errorDescription, expected)
    }
}
