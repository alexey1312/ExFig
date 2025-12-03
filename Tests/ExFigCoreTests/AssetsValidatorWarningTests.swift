@testable import ExFigCore
import XCTest

final class AssetsValidatorWarningTests: XCTestCase {
    func testLightAssetsNotFoundInDarkPaletteWarning() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["color1", "color2", "color3"]
        )

        XCTAssertTrue(warning.errorDescription?.contains("color1, color2, color3") == true)
        XCTAssertTrue(warning.errorDescription?.contains("not found in the dark palette") == true)
        XCTAssertTrue(warning.errorDescription?.hasPrefix("⚠️") == true)
    }

    func testLightHCAssetsNotFoundInLightPaletteWarning() {
        let warning = AssetsValidatorWarning.lightHCAssetsNotFoundInLightPalette(
            assets: ["highContrastColor"]
        )

        XCTAssertTrue(warning.errorDescription?.contains("highContrastColor") == true)
        XCTAssertTrue(warning.errorDescription?.contains("not found in the light palette") == true)
    }

    func testDarkHCAssetsNotFoundInDarkPaletteWarning() {
        let warning = AssetsValidatorWarning.darkHCAssetsNotFoundInDarkPalette(
            assets: ["darkHC1", "darkHC2"]
        )

        XCTAssertTrue(warning.errorDescription?.contains("darkHC1, darkHC2") == true)
        XCTAssertTrue(warning.errorDescription?.contains("not found in the dark palette") == true)
    }
}
