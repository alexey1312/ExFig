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

        @Option(name: .long, help: "Figma frame name containing images (default: from config or 'Illustrations')")
        var frameName: String?

        @Argument(help: "Filter images by name pattern (e.g., 'hero/*')")
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)

            ui.info("Downloading images from Figma...")

            let outputPath = jsonOptions.output ?? "images.json"
            let outputURL = URL(fileURLWithPath: outputPath)

            let figmaParams = options.params.figma
            let effectiveFrameName = frameName
                ?? options.params.common?.images?.figmaFrameName
                ?? "Illustrations"

            let filterValue = filter
            let fileId = figmaParams.lightFileId
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

            ui.success("Exported images to \(outputPath)")
        }
    }
}
