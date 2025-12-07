@testable import ExFig
import XCTest

final class ExFigWarningFormatterTests: XCTestCase {
    private var formatter: ExFigWarningFormatter!

    override func setUp() {
        super.setUp()
        formatter = ExFigWarningFormatter()
    }

    // MARK: - Config Missing

    func testConfigMissingFormatsAsCompactTOON() {
        let warning = ExFigWarning.configMissing(platform: "ios", assetType: "icons")

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Config missing: platform=ios, assetType=icons")
    }

    func testConfigMissingWithAndroidPlatform() {
        let warning = ExFigWarning.configMissing(platform: "android", assetType: "colors")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("platform=android"))
        XCTAssertTrue(result.contains("assetType=colors"))
    }

    func testConfigMissingWithFlutterPlatform() {
        let warning = ExFigWarning.configMissing(platform: "flutter", assetType: "images")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("platform=flutter"))
        XCTAssertTrue(result.contains("assetType=images"))
    }

    // MARK: - No Assets Found

    func testNoAssetsFoundFormatsAsMultilineTOON() {
        let warning = ExFigWarning.noAssetsFound(assetType: "icons", frameName: "Icons")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("No assets found:"))
        XCTAssertTrue(result.contains("type: icons"))
        XCTAssertTrue(result.contains("frame: Icons"))
    }

    func testNoAssetsFoundIsMultiline() {
        let warning = ExFigWarning.noAssetsFound(assetType: "images", frameName: "Illustrations")

        let result = formatter.format(warning)

        let lines = result.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 3, "Should be multi-line output")
    }

    func testNoAssetsFoundIndentation() {
        let warning = ExFigWarning.noAssetsFound(assetType: "icons", frameName: "My Icons")

        let result = formatter.format(warning)

        let lines = result.split(separator: "\n")
        let indentedLines = lines.filter { $0.hasPrefix("  ") }
        XCTAssertEqual(indentedLines.count, 2, "Should have 2 indented lines (type and frame)")
    }

    // MARK: - Xcode Project Update Failed

    func testXcodeProjectUpdateFailedFormatsAsCompact() {
        let warning = ExFigWarning.xcodeProjectUpdateFailed

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Xcode project update incomplete: some file references could not be added")
    }

    // MARK: - Compose Requirement Missing

    func testComposeRequirementMissingFormatsAsCompact() {
        let warning = ExFigWarning.composeRequirementMissing(requirement: "composePackageName")

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Compose export skipped: missing=composePackageName")
    }

    func testComposeRequirementMissingWithMainSrc() {
        let warning = ExFigWarning.composeRequirementMissing(requirement: "mainSrc")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("missing=mainSrc"))
    }

    // MARK: - Batch Warnings

    func testNoConfigsFoundFormatsAsCompact() {
        let warning = ExFigWarning.noConfigsFound

        let result = formatter.format(warning)

        XCTAssertEqual(result, "No config files found")
    }

    func testNoValidConfigsFormatsAsCompact() {
        let warning = ExFigWarning.noValidConfigs

        let result = formatter.format(warning)

        XCTAssertEqual(result, "No valid ExFig config files found")
    }

    func testInvalidConfigsSkippedSingular() {
        let warning = ExFigWarning.invalidConfigsSkipped(count: 1)

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("Invalid configs skipped:"))
        XCTAssertTrue(result.contains("count: 1 file"))
    }

    func testInvalidConfigsSkippedPlural() {
        let warning = ExFigWarning.invalidConfigsSkipped(count: 5)

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("count: 5 files"))
    }

    // MARK: - Checkpoint Warnings

    func testCheckpointExpiredFormatsAsCompact() {
        let warning = ExFigWarning.checkpointExpired

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Checkpoint expired: older than 24h, starting fresh")
    }

    func testCheckpointPathMismatchFormatsAsCompact() {
        let warning = ExFigWarning.checkpointPathMismatch

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Checkpoint invalid: paths don't match current request, starting fresh")
    }

    // MARK: - Retry Warning

    func testRetryingFormatsAsCompactTOON() {
        let warning = ExFigWarning.retrying(attempt: 2, maxAttempts: 4, error: "Rate limited", delay: "30s")

        let result = formatter.format(warning)

        XCTAssertEqual(result, "Retrying: attempt=2/4, error=Rate limited, delay=30s")
    }

    func testRetryingWithDifferentValues() {
        let warning = ExFigWarning.retrying(attempt: 1, maxAttempts: 6, error: "Timeout", delay: "5s")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("attempt=1/6"))
        XCTAssertTrue(result.contains("error=Timeout"))
        XCTAssertTrue(result.contains("delay=5s"))
    }

    func testRetryingWithMillisecondDelay() {
        let warning = ExFigWarning.retrying(attempt: 3, maxAttempts: 4, error: "Server error (500)", delay: "500ms")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("delay=500ms"))
    }

    // MARK: - Edge Cases

    func testConfigMissingWithEmptyPlatform() {
        let warning = ExFigWarning.configMissing(platform: "", assetType: "icons")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("platform=,"))
    }

    func testNoAssetsFoundWithSpecialCharactersInFrameName() {
        let warning = ExFigWarning.noAssetsFound(assetType: "icons", frameName: "Icons/Main (v2)")

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("frame: Icons/Main (v2)"))
    }

    func testRetryingWithLongErrorMessage() {
        let warning = ExFigWarning.retrying(
            attempt: 1,
            maxAttempts: 4,
            error: "Network connection lost during request",
            delay: "10s"
        )

        let result = formatter.format(warning)

        XCTAssertTrue(result.contains("error=Network connection lost during request"))
    }
}
