@testable import ExFigCLI
import ExFigCore
import XCTest

final class WarningFormatterTests: XCTestCase {
    // MARK: - Light Assets Not Found In Dark Palette

    func testFormatSingleAsset() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-name"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("1 asset"), "Should use singular 'asset' for single item")
        XCTAssertTrue(result.contains("not found in dark palette"))
        XCTAssertTrue(result.contains("icon-name"))
    }

    func testFormatMultipleAssets() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-a", "icon-b", "icon-c"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("3 assets"), "Should use plural 'assets' for multiple items")
        XCTAssertTrue(result.contains("not found in dark palette"))
    }

    func testFormatLargeList() {
        let assets = (1 ... 100).map { "asset-\($0)" }
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("100 assets"))
        XCTAssertTrue(result.contains("asset-1"))
        XCTAssertTrue(result.contains("asset-100"))
    }

    // MARK: - Light HC Assets Not Found In Light Palette

    func testFormatLightHCWarningSingleAsset() {
        let warning = AssetsValidatorWarning.lightHCAssetsNotFoundInLightPalette(
            assets: ["hc-icon"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("1 asset"))
        XCTAssertTrue(result.contains("not found in light palette"))
        XCTAssertTrue(result.contains("hc-icon"))
    }

    func testFormatLightHCWarningMultipleAssets() {
        let warning = AssetsValidatorWarning.lightHCAssetsNotFoundInLightPalette(
            assets: ["hc-a", "hc-b"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("2 assets"))
        XCTAssertTrue(result.contains("not found in light palette"))
    }

    // MARK: - Dark HC Assets Not Found In Dark Palette

    func testFormatDarkHCWarningSingleAsset() {
        let warning = AssetsValidatorWarning.darkHCAssetsNotFoundInDarkPalette(
            assets: ["dark-hc-icon"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("1 asset"))
        XCTAssertTrue(result.contains("not found in dark palette"))
        XCTAssertTrue(result.contains("dark-hc-icon"))
    }

    func testFormatDarkHCWarningMultipleAssets() {
        let warning = AssetsValidatorWarning.darkHCAssetsNotFoundInDarkPalette(
            assets: ["dark-hc-a", "dark-hc-b", "dark-hc-c"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("3 assets"))
        XCTAssertTrue(result.contains("not found in dark palette"))
    }

    // MARK: - Output Format Tests

    func testOutputContainsTOONArraySyntax() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["a", "b", "c"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        // Should contain TOON array format: assets[count]:
        XCTAssertTrue(result.contains("assets[3]:"), "Should contain TOON array syntax")
    }

    func testOutputIsMultiline() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-a", "icon-b"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        // Should have header line and asset lines
        let lines = result.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 2, "Should be multi-line output")
    }

    func testEachAssetOnSeparateLine() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-a", "icon-b", "icon-c"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        let lines = result.split(separator: "\n")
        // Header + assets[N]: line + 3 asset lines = at least 4 lines
        // Or header with assets[N]: on same line + 3 asset lines = at least 4 lines
        XCTAssertTrue(
            lines.contains { $0.contains("icon-a") },
            "Should contain icon-a on its own line"
        )
        XCTAssertTrue(
            lines.contains { $0.contains("icon-b") },
            "Should contain icon-b on its own line"
        )
        XCTAssertTrue(
            lines.contains { $0.contains("icon-c") },
            "Should contain icon-c on its own line"
        )
    }

    func testAssetLinesAreIndented() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-a", "icon-b"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        // Asset lines should be indented (start with spaces)
        let assetLines = lines.filter { $0.contains("icon-") }
        for line in assetLines {
            XCTAssertTrue(
                line.hasPrefix("  ") || line.hasPrefix("\t"),
                "Asset lines should be indented: '\(line)'"
            )
        }
    }

    // MARK: - Edge Cases

    func testFormatEmptyAssets() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: []
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        // Should handle gracefully - either empty string or minimal message
        XCTAssertNotNil(result)
    }

    func testFormatAssetsWithSpecialCharacters() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-name_v2", "icon.variant", "icon-with-dash"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("icon-name_v2"))
        XCTAssertTrue(result.contains("icon.variant"))
        XCTAssertTrue(result.contains("icon-with-dash"))
    }

    func testFormatPreservesAssetOrder() {
        let assets = ["zebra-icon", "alpha-icon", "beta-icon"]
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        // Find positions of each asset
        guard let zebraRange = result.range(of: "zebra-icon"),
              let alphaRange = result.range(of: "alpha-icon"),
              let betaRange = result.range(of: "beta-icon")
        else {
            XCTFail("All assets should be in output")
            return
        }

        // Zebra should come before alpha (original order, not alphabetical)
        XCTAssertLessThan(zebraRange.lowerBound, alphaRange.lowerBound)
        XCTAssertLessThan(alphaRange.lowerBound, betaRange.lowerBound)
    }

    // MARK: - Compact Mode

    func testFormatCompactTruncatesLargeList() {
        let assets = (1 ... 50).map { "asset-\($0)" }
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning, compact: true)

        // Should show first 10 items
        XCTAssertTrue(result.contains("asset-1"))
        XCTAssertTrue(result.contains("asset-10"))
        // Should NOT show items beyond 10
        XCTAssertFalse(result.contains("asset-11"))
        XCTAssertFalse(result.contains("asset-50"))
        // Should show truncation message
        XCTAssertTrue(result.contains("... +40 more"), "Should show remaining count")
        // Header should still show total count
        XCTAssertTrue(result.contains("50 assets"))
    }

    func testFormatCompactFewItemsNoTruncation() {
        let assets = ["icon-a", "icon-b", "icon-c"]
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning, compact: true)

        // Should show all items when under threshold
        XCTAssertTrue(result.contains("icon-a"))
        XCTAssertTrue(result.contains("icon-b"))
        XCTAssertTrue(result.contains("icon-c"))
        // Should NOT have truncation message
        XCTAssertFalse(result.contains("more"))
    }

    func testFormatCompactExactlyMaxItems() {
        let assets = (1 ... 10).map { "asset-\($0)" }
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning, compact: true)

        // Exactly 10 items — should show all without truncation
        XCTAssertTrue(result.contains("asset-1"))
        XCTAssertTrue(result.contains("asset-10"))
        XCTAssertFalse(result.contains("more"))
    }

    func testFormatNonCompactDefaultShowsAll() {
        let assets = (1 ... 50).map { "asset-\($0)" }
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: assets
        )
        let formatter = WarningFormatter()

        // Default compact=false should show all items
        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("asset-1"))
        XCTAssertTrue(result.contains("asset-50"))
        XCTAssertFalse(result.contains("more"))
    }

    // MARK: - Universal Message

    func testContainsUniversalExplanation() {
        let warning = AssetsValidatorWarning.lightAssetsNotFoundInDarkPalette(
            assets: ["icon-a"]
        )
        let formatter = WarningFormatter()

        let result = formatter.format(warning)

        XCTAssertTrue(
            result.contains("universal") || result.contains("will be"),
            "Should explain that assets will be universal"
        )
    }
}
