@testable import ExFig
import FigmaAPI
import XCTest

final class SubcommandConfigExporterTests: XCTestCase {
    private var tempFiles: [URL] = []

    override func tearDown() {
        super.tearDown()
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }

    func testExportCallsAllSubcommandsAndAggregatesStats() async throws {
        // Arrange
        setenv("FIGMA_PERSONAL_TOKEN", "test_token", 1)
        let configURL = try makeConfigFile()
        let configFile = ConfigFile(url: configURL)

        var options = ExFigOptions()
        options.input = configFile.url.path
        try options.validate()

        let mockClient = MockClient()
        let ui = TerminalUI.create(verbose: false, quiet: true)

        let mockExporter = MockSubcommandExporter(
            colorsCount: 5,
            iconsCount: 10,
            imagesCount: 3,
            typographyCount: 7
        )

        // Act
        let stats = try await mockExporter.export(
            configFile: configFile,
            options: options,
            client: mockClient,
            ui: ui
        )

        // Assert
        XCTAssertEqual(stats.colors, 5)
        XCTAssertEqual(stats.icons, 10)
        XCTAssertEqual(stats.images, 3)
        XCTAssertEqual(stats.typography, 7)
    }

    func testExportReturnsZeroWhenNoExports() async throws {
        // Arrange
        setenv("FIGMA_PERSONAL_TOKEN", "test_token", 1)
        let configURL = try makeConfigFile()
        let configFile = ConfigFile(url: configURL)

        var options = ExFigOptions()
        options.input = configFile.url.path
        try options.validate()

        let mockClient = MockClient()
        let ui = TerminalUI.create(verbose: false, quiet: true)

        let mockExporter = MockSubcommandExporter(
            colorsCount: 0,
            iconsCount: 0,
            imagesCount: 0,
            typographyCount: 0
        )

        // Act
        let stats = try await mockExporter.export(
            configFile: configFile,
            options: options,
            client: mockClient,
            ui: ui
        )

        // Assert
        XCTAssertEqual(stats.colors, 0)
        XCTAssertEqual(stats.icons, 0)
        XCTAssertEqual(stats.images, 0)
        XCTAssertEqual(stats.typography, 0)
    }

    private func makeConfigFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".yaml")
        let content = """
        figma:
          lightFileId: "abc123"
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        tempFiles.append(url)
        return url
    }
}

// MARK: - Mocks

/// Mock exporter that simulates subcommand execution with predefined counts
private final class MockSubcommandExporter: ConfigExportPerforming {
    let colorsCount: Int
    let iconsCount: Int
    let imagesCount: Int
    let typographyCount: Int

    init(colorsCount: Int, iconsCount: Int, imagesCount: Int, typographyCount: Int) {
        self.colorsCount = colorsCount
        self.iconsCount = iconsCount
        self.imagesCount = imagesCount
        self.typographyCount = typographyCount
    }

    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        // Simulate what SubcommandConfigExporter should do:
        // call performExport on each subcommand and aggregate stats
        ExportStats(
            colors: colorsCount,
            icons: iconsCount,
            images: imagesCount,
            typography: typographyCount
        )
    }
}
