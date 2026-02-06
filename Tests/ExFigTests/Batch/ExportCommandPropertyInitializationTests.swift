@testable import ExFigCLI
import XCTest

/// Tests that export commands can be manually instantiated with all @Argument/@Flag properties
/// properly initialized. This prevents swift-argument-parser "Can't read a value from a parsable
/// argument definition" crashes when batch mode creates commands without going through the parser.
///
/// Background: When ArgumentParser commands are created manually (not via `parse()`),
/// @Argument/@Flag property wrappers may not be properly initialized. Accessing uninitialized
/// properties causes a fatal error. Batch mode creates commands manually, so all properties
/// must be explicitly set.
final class ExportCommandPropertyInitializationTests: XCTestCase {
    private var tempFiles: [URL] = []

    override func setUp() {
        super.setUp()
        setenv("FIGMA_PERSONAL_TOKEN", "test_token", 1)
    }

    override func tearDown() {
        super.tearDown()
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }

    // MARK: - ExportColors

    func testExportColorsManualInstantiation() throws {
        // Given: manually create ExportColors like BatchConfigRunner does
        let options = try makeOptions()
        var cmd = ExFigCommand.ExportColors()
        cmd.globalOptions = GlobalOptions()
        cmd.options = options
        cmd.cacheOptions = CacheOptions()
        cmd.faultToleranceOptions = FaultToleranceOptions()
        cmd.filter = nil

        // Then: accessing @Argument properties should not crash
        XCTAssertNil(cmd.filter)
    }

    // MARK: - ExportIcons

    func testExportIconsManualInstantiation() throws {
        // Given: manually create ExportIcons like BatchConfigRunner does
        let options = try makeOptions()
        var cmd = ExFigCommand.ExportIcons()
        cmd.globalOptions = GlobalOptions()
        cmd.options = options
        cmd.cacheOptions = CacheOptions()
        cmd.faultToleranceOptions = HeavyFaultToleranceOptions()
        cmd.filter = nil
        cmd.strictPathValidation = false

        // Then: accessing @Argument/@Flag properties should not crash
        XCTAssertNil(cmd.filter)
        XCTAssertFalse(cmd.strictPathValidation)
    }

    func testExportIconsStrictPathValidationMustBeInitialized() throws {
        // This test documents the bug fix: strictPathValidation must be explicitly set
        // when creating ExportIcons manually, otherwise accessing it crashes with:
        // "Can't read a value from a parsable argument definition"
        let options = try makeOptions()
        var cmd = ExFigCommand.ExportIcons()
        cmd.globalOptions = GlobalOptions()
        cmd.options = options
        cmd.cacheOptions = CacheOptions()
        cmd.faultToleranceOptions = HeavyFaultToleranceOptions()
        cmd.filter = nil
        cmd.strictPathValidation = false // CRITICAL: must be set before accessing

        // Accessing strictPathValidation should not crash
        let value = cmd.strictPathValidation
        XCTAssertFalse(value)
    }

    // MARK: - ExportImages

    func testExportImagesManualInstantiation() throws {
        // Given: manually create ExportImages like BatchConfigRunner does
        let options = try makeOptions()
        var cmd = ExFigCommand.ExportImages()
        cmd.globalOptions = GlobalOptions()
        cmd.options = options
        cmd.cacheOptions = CacheOptions()
        cmd.faultToleranceOptions = HeavyFaultToleranceOptions()
        cmd.filter = nil

        // Then: accessing @Argument properties should not crash
        XCTAssertNil(cmd.filter)
    }

    // MARK: - ExportTypography

    func testExportTypographyManualInstantiation() throws {
        // Given: manually create ExportTypography like BatchConfigRunner does
        let options = try makeOptions()
        var cmd = ExFigCommand.ExportTypography()
        cmd.globalOptions = GlobalOptions()
        cmd.options = options
        cmd.cacheOptions = CacheOptions()
        cmd.faultToleranceOptions = FaultToleranceOptions()

        // Then: command should be usable (no @Argument/@Flag to test)
        XCTAssertNotNil(cmd.globalOptions)
    }

    // MARK: - Helpers

    private func makeOptions() throws -> ExFigOptions {
        let configURL = try makeConfigFile()
        var options = ExFigOptions()
        options.input = configURL.path
        try options.validate()
        return options
    }

    private func makeConfigFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".pkl")
        let content = """
        figma {
          lightFileId = "test123"
        }
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        tempFiles.append(url)
        return url
    }
}
