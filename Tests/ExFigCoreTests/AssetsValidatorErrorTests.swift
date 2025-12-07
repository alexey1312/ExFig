@testable import ExFigCore
import XCTest

final class AssetsValidatorErrorTests: XCTestCase {
    func testBadNameError() {
        let error = AssetsValidatorError.badName(name: "invalid name")

        XCTAssertEqual(error.errorDescription, "Invalid asset name: invalid name")
        XCTAssertEqual(error.recoverySuggestion, "Rename asset using valid characters")
    }

    func testCountMismatchError() {
        let error = AssetsValidatorError.countMismatch(light: 10, dark: 5)

        XCTAssertEqual(error.errorDescription, "Asset count mismatch: light=10, dark=5")
        XCTAssertEqual(error.recoverySuggestion, "Add missing assets to match theme counts")
    }

    func testCountMismatchLightHighContrastColorsError() {
        let error = AssetsValidatorError.countMismatchLightHighContrastColors(light: 8, lightHC: 6)

        XCTAssertEqual(error.errorDescription, "Asset count mismatch: light=8, lightHC=6")
        XCTAssertEqual(error.recoverySuggestion, "Add missing assets to match theme counts")
    }

    func testCountMismatchDarkHighContrastColorsError() {
        let error = AssetsValidatorError.countMismatchDarkHighContrastColors(dark: 7, darkHC: 4)

        XCTAssertEqual(error.errorDescription, "Asset count mismatch: dark=7, darkHC=4")
        XCTAssertEqual(error.recoverySuggestion, "Add missing assets to match theme counts")
    }

    func testFoundDuplicateError() {
        let error = AssetsValidatorError.foundDuplicate(assetName: "primaryColor")

        XCTAssertEqual(error.errorDescription, "Duplicate asset: primaryColor")
        XCTAssertEqual(error.recoverySuggestion, "Remove duplicate assets with the same name")
    }

    func testSecondAssetsNotFoundInFirstPaletteError() {
        let error = AssetsValidatorError.secondAssetsNotFoundInFirstPalette(
            assets: ["color1", "color2"],
            firstAssetsName: "Light",
            secondAssetsName: "Dark"
        )

        XCTAssertTrue(error.errorDescription?.contains("color1, color2") == true)
        XCTAssertTrue(error.errorDescription?.contains("Light") == true)
        XCTAssertEqual(error.recoverySuggestion, "Add missing assets and publish to Team Library")
    }

    func testDescriptionMismatchError() {
        let error = AssetsValidatorError.descriptionMismatch(
            assetName: "background",
            light: "Light background",
            dark: "Dark bg"
        )

        XCTAssertTrue(error.errorDescription?.contains("background") == true)
        XCTAssertTrue(error.errorDescription?.contains("Light background") == true)
        XCTAssertTrue(error.errorDescription?.contains("Dark bg") == true)
        XCTAssertEqual(error.recoverySuggestion, "Update descriptions to match in both themes")
    }
}
