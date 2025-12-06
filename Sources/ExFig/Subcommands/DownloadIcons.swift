import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Asset Export Options

/// Asset format for icon/image export.
public enum AssetExportFormat: String, ExpressibleByArgument, CaseIterable, Sendable {
    case svg
    case png
    case pdf
    case jpg
}

/// Common options for asset export commands.
public struct AssetExportOptions: ParsableArguments {
    @Option(name: .long, help: "Asset format: svg, png (default), pdf, jpg")
    public var assetFormat: AssetExportFormat = .png

    @Option(name: .long, help: "Scale for raster formats (1-4, default: 3)")
    public var scale: Int = 3

    public init() {}
}

// MARK: - Download Icons

extension ExFigCommand.Download {
    /// Downloads icons from Figma as JSON.
    struct DownloadIcons: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "icons",
            abstract: "Downloads icons from Figma as JSON"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var jsonOptions: JSONExportOptions

        @OptionGroup
        var assetOptions: AssetExportOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        @Option(name: .long, help: "Figma frame name containing icons (default: from config or 'Icons')")
        var frameName: String?

        @Argument(help: "Filter icons by name pattern (e.g., 'navigation/*')")
        var filter: String?

        // swiftlint:disable:next function_body_length
        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let baseClient = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)
            let rateLimiter = faultToleranceOptions.createRateLimiter()
            let client = faultToleranceOptions.createRateLimitedClient(
                wrapping: baseClient,
                rateLimiter: rateLimiter,
                onRetry: { attempt, error in
                    ui.warning("Retry \(attempt) after error: \(error.localizedDescription)")
                }
            )

            ui.info("Downloading icons from Figma...")

            let outputPath = jsonOptions.output ?? "icons.json"
            let outputURL = URL(fileURLWithPath: outputPath)

            let figmaParams = options.params.figma
            let effectiveFrameName = frameName
                ?? options.params.common?.icons?.figmaFrameName
                ?? "Icons"

            let filterValue = filter
            let fileId = figmaParams.lightFileId
            let formatString = assetOptions.assetFormat.rawValue
            let scaleValue = Double(assetOptions.scale)

            let components = try await ui.withSpinner("Fetching icon components...") {
                try await AssetExportHelper.fetchComponents(
                    client: client,
                    fileId: fileId,
                    frameName: effectiveFrameName,
                    filter: filterValue
                )
            }

            guard !components.isEmpty else {
                throw ExFigError.componentsNotFound
            }

            let nodeIds = Array(components.keys)

            let exportUrls = try await ui.withSpinner("Getting export URLs...") {
                try await AssetExportHelper.getExportUrls(
                    client: client,
                    fileId: fileId,
                    nodeIds: nodeIds,
                    format: formatString,
                    scale: scaleValue
                )
            }

            switch jsonOptions.format {
            case .w3c:
                try AssetExportHelper.exportW3C(
                    components: components,
                    exportUrls: exportUrls,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )

            case .raw:
                try AssetExportHelper.exportRaw(
                    components: components,
                    exportUrls: exportUrls,
                    fileId: fileId,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )
            }

            ui.success("Exported icons to \(outputPath)")
        }
    }
}
