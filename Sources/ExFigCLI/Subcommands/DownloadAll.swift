import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Download All

extension ExFigCommand.Download {
    /// Downloads all design tokens from Figma as JSON files.
    struct DownloadAll: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "all",
            abstract: "Downloads all design tokens from Figma as JSON"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var jsonOptions: JSONExportOptions

        @OptionGroup
        var assetOptions: AssetExportOptions

        @Option(name: .long, help: "Figma frame name for icons (default: from config or 'Icons')")
        var iconsFrameName: String?

        @Option(name: .long, help: "Figma frame name for images (default: from config or 'Illustrations')")
        var imagesFrameName: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            ui.info("Downloading all design tokens from Figma...")

            let outputDir = jsonOptions.output ?? "."
            let outputURL = URL(fileURLWithPath: outputDir)

            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

            ui.info("Exporting colors...")
            try await exportColors(outputDir: outputURL, ui: ui)

            ui.info("Exporting typography...")
            try await exportTypography(outputDir: outputURL, ui: ui)

            ui.info("Exporting icons...")
            try await exportIcons(outputDir: outputURL, ui: ui)

            ui.info("Exporting images...")
            try await exportImages(outputDir: outputURL, ui: ui)

            ui.success("Exported all design tokens to \(outputDir)")
        }

        // MARK: - Export Methods

        private func exportColors(outputDir: URL, ui: TerminalUI) async throws {
            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma?.timeout)
            let figmaParams = options.params.figma
            let commonParams = options.params.common

            let colorsResult = try await ui.withSpinner("Fetching colors...") {
                if let variableParams = commonParams?.variablesColors {
                    let loader = ColorsVariablesLoader(
                        client: client,
                        variableParams: variableParams,
                        filter: nil
                    )
                    return try await loader.load()
                } else {
                    guard let figmaParams else {
                        throw ExFigError.custom(errorString:
                            "figma section is required for legacy Styles API colors export. " +
                                "Use common.variablesColors for Variables API instead."
                        )
                    }
                    let loader = ColorsLoader(
                        client: client,
                        figmaParams: figmaParams,
                        colorParams: commonParams?.colors,
                        filter: nil
                    )
                    let output = try await loader.load()
                    return ColorsVariablesLoader.LoadResult(output: output, warnings: [])
                }
            }

            for warning in colorsResult.warnings {
                ui.warning(warning)
            }

            let colors = colorsResult.output
            let outputURL = outputDir.appendingPathComponent("colors.json")

            switch jsonOptions.format {
            case .w3c:
                try ColorExportHelper.exportW3C(
                    colors: colors,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )

            case .raw:
                guard let fileId = figmaParams?.lightFileId else {
                    throw ExFigError.custom(errorString:
                        "figma.lightFileId is required for raw colors export."
                    )
                }
                try ColorExportHelper.exportRaw(
                    colors: colors,
                    fileId: fileId,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )
            }
        }

        private func exportTypography(outputDir: URL, ui: TerminalUI) async throws {
            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma?.timeout)
            guard let figmaParams = options.params.figma else {
                throw ExFigError.custom(errorString: "figma section is required for typography export.")
            }

            let textStyles = try await ui.withSpinner("Fetching text styles...") {
                let loader = TextStylesLoader(client: client, params: figmaParams)
                return try await loader.load()
            }

            let outputURL = outputDir.appendingPathComponent("typography.json")

            switch jsonOptions.format {
            case .w3c:
                try TypographyExportHelper.exportW3C(
                    textStyles: textStyles,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )

            case .raw:
                guard let fileId = figmaParams.lightFileId else {
                    throw ExFigError.custom(errorString:
                        "figma.lightFileId is required for raw typography export."
                    )
                }
                try TypographyExportHelper.exportRaw(
                    textStyles: textStyles,
                    fileId: fileId,
                    outputURL: outputURL,
                    compact: jsonOptions.compact
                )
            }
        }

        private func exportIcons(outputDir: URL, ui: TerminalUI) async throws {
            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma?.timeout)
            guard let figmaParams = options.params.figma else {
                throw ExFigError.custom(errorString: "figma section is required for icons export.")
            }
            let effectiveFrameName = iconsFrameName
                ?? options.params.common?.icons?.figmaFrameName
                ?? "Icons"
            let effectivePageName = options.params.common?.icons?.figmaPageName
            guard let fileId = figmaParams.lightFileId else {
                throw ExFigError.custom(errorString: "figma.lightFileId is required for icons download.")
            }
            let formatString = assetOptions.assetFormat.rawValue
            let scaleValue = Double(assetOptions.scale)

            let components = try await ui.withSpinner("Fetching icon components...") {
                try await AssetExportHelper.fetchComponents(
                    client: client,
                    fileId: fileId,
                    frameName: effectiveFrameName,
                    pageName: effectivePageName,
                    filter: nil
                )
            }

            guard !components.isEmpty else {
                ui.warning(.noAssetsFound(
                    assetType: "icons",
                    frameName: effectiveFrameName,
                    pageName: effectivePageName
                ))
                return
            }

            let nodeIds = Array(components.keys)

            let exportUrls = try await ui.withSpinner("Getting icon export URLs...") {
                try await AssetExportHelper.getExportUrls(
                    client: client,
                    fileId: fileId,
                    nodeIds: nodeIds,
                    format: formatString,
                    scale: scaleValue
                )
            }

            let outputURL = outputDir.appendingPathComponent("icons.json")

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
        }

        private func exportImages(outputDir: URL, ui: TerminalUI) async throws {
            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma?.timeout)
            guard let figmaParams = options.params.figma else {
                throw ExFigError.custom(errorString: "figma section is required for images export.")
            }
            let effectiveFrameName = imagesFrameName
                ?? options.params.common?.images?.figmaFrameName
                ?? "Illustrations"
            let effectivePageName = options.params.common?.images?.figmaPageName
            guard let fileId = figmaParams.lightFileId else {
                throw ExFigError.custom(errorString: "figma.lightFileId is required for images download.")
            }
            let formatString = assetOptions.assetFormat.rawValue
            let scaleValue = Double(assetOptions.scale)

            let components = try await ui.withSpinner("Fetching image components...") {
                try await AssetExportHelper.fetchComponents(
                    client: client,
                    fileId: fileId,
                    frameName: effectiveFrameName,
                    pageName: effectivePageName,
                    filter: nil
                )
            }

            guard !components.isEmpty else {
                ui.warning(.noAssetsFound(
                    assetType: "images",
                    frameName: effectiveFrameName,
                    pageName: effectivePageName
                ))
                return
            }

            let nodeIds = Array(components.keys)

            let exportUrls = try await ui.withSpinner("Getting image export URLs...") {
                try await AssetExportHelper.getExportUrls(
                    client: client,
                    fileId: fileId,
                    nodeIds: nodeIds,
                    format: formatString,
                    scale: scaleValue
                )
            }

            let outputURL = outputDir.appendingPathComponent("images.json")

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
        }
    }
}
