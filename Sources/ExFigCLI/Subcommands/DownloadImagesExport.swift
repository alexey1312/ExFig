import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Download Images (JSON Export)

extension ExFigCommand.Download {
    /// Downloads images/illustrations from Figma as JSON.
    struct DownloadImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "images",
            abstract: "Downloads images from Figma as JSON"
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

        @Option(name: .long, help: "Figma frame name containing images (default: from config or 'Illustrations')")
        var frameName: String?

        @Argument(help: "Filter images by name pattern (e.g., 'hero/*')")
        var filter: String?

        // swiftlint:disable:next function_body_length
        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let baseClient = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma?.timeout)
            let rateLimiter = faultToleranceOptions.createRateLimiter()
            let client = faultToleranceOptions.createRateLimitedClient(
                wrapping: baseClient,
                rateLimiter: rateLimiter,
                onRetry: { attempt, error in
                    ui.warning("Retry \(attempt) after error: \(error.localizedDescription)")
                }
            )

            ui.info("Downloading images from Figma...")

            let outputPath = jsonOptions.output ?? "images.json"
            let outputURL = URL(fileURLWithPath: outputPath)

            let effectiveFrameName = frameName
                ?? options.params.common?.images?.figmaFrameName
                ?? "Illustrations"

            let filterValue = filter
            guard let fileId = options.params.figma?.lightFileId else {
                throw ExFigError.custom(errorString: "figma.lightFileId is required for images download.")
            }
            let formatString = assetOptions.assetFormat.rawValue
            let scaleValue = Double(assetOptions.scale)

            let components = try await ui.withSpinner("Fetching image components...") {
                try await AssetExportHelper.fetchComponents(
                    client: client,
                    fileId: fileId,
                    frameName: effectiveFrameName,
                    filter: filterValue
                )
            }

            guard !components.isEmpty else {
                throw ExFigError.componentsNotFound(frameName: effectiveFrameName, pageName: nil)
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
                    fileId: fileId,
                    outputURL: outputURL,
                    compact: jsonOptions.compact,
                    w3cVersion: jsonOptions.w3cVersion
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

            ui.success("Exported images to \(outputPath)")
        }
    }
}
