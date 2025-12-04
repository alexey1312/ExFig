import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - JSON Export Format

/// Output format for JSON export.
public enum JSONExportFormat: String, ExpressibleByArgument, CaseIterable, Sendable {
    /// W3C Design Tokens format (default).
    case w3c

    /// Raw Figma API response.
    case raw
}

// MARK: - JSON Export Options

/// Common options for JSON export commands.
public struct JSONExportOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: "Output file path")
    public var output: String?

    @Option(name: .shortAndLong, help: "Output format: w3c (default) or raw")
    public var format: JSONExportFormat = .w3c

    @Flag(name: .long, help: "Output minified JSON")
    public var compact: Bool = false

    public init() {}
}

// MARK: - Download Command

extension ExFigCommand {
    /// Downloads Figma data as JSON in W3C Design Tokens or raw format.
    struct Download: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "download",
            abstract: "Downloads Figma data as JSON",
            discussion: """
            Downloads design data from Figma and exports it as JSON.
            Supports W3C Design Tokens format (default) or raw Figma API responses.

            Examples:
              # Download colors as W3C tokens
              exfig download colors -o tokens.json

              # Download raw Figma API response
              exfig download colors -o raw.json --format raw

              # Download with compact output
              exfig download colors -o tokens.json --compact
            """,
            subcommands: [
                DownloadColors.self,
                DownloadTypography.self,
                DownloadIcons.self,
                DownloadImages.self,
                DownloadAll.self,
            ]
        )
    }
}

// MARK: - Download Colors

extension ExFigCommand.Download {
    /// Downloads colors from Figma as JSON.
    struct DownloadColors: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Downloads colors from Figma as JSON"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var jsonOptions: JSONExportOptions

        @Argument(help: "Filter colors by name pattern (e.g., 'background/*')")
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)

            ui.info("Downloading colors from Figma...")

            let outputPath = jsonOptions.output ?? "colors.json"
            let outputURL = URL(fileURLWithPath: outputPath)

            let commonParams = options.params.common

            if commonParams?.colors != nil, commonParams?.variablesColors != nil {
                throw ExFigError.custom(
                    errorString: "Cannot use both common/colors and common/variablesColors"
                )
            }

            let figmaParams = options.params.figma

            switch jsonOptions.format {
            case .w3c:
                try await exportW3C(
                    client: client,
                    figmaParams: figmaParams,
                    commonParams: commonParams,
                    outputURL: outputURL,
                    ui: ui
                )

            case .raw:
                try await exportRaw(
                    client: client,
                    figmaParams: figmaParams,
                    commonParams: commonParams,
                    outputURL: outputURL,
                    ui: ui
                )
            }

            ui.success("Exported colors to \(outputPath)")
        }

        // MARK: - W3C Export

        private func exportW3C(
            client: FigmaClient,
            figmaParams: Params.Figma,
            commonParams: Params.Common?,
            outputURL: URL,
            ui: TerminalUI
        ) async throws {
            let filterValue = filter

            let colors = try await ui.withSpinner("Fetching colors...") {
                if let variableParams = commonParams?.variablesColors {
                    let loader = ColorsVariablesLoader(
                        client: client,
                        figmaParams: figmaParams,
                        variableParams: variableParams,
                        filter: filterValue
                    )
                    return try await loader.load()
                } else {
                    let loader = ColorsLoader(
                        client: client,
                        figmaParams: figmaParams,
                        colorParams: commonParams?.colors,
                        filter: filterValue
                    )
                    return try await loader.load()
                }
            }

            try ColorExportHelper.exportW3C(
                colors: colors,
                outputURL: outputURL,
                compact: jsonOptions.compact
            )
        }

        // MARK: - Raw Export

        private func exportRaw(
            client: FigmaClient,
            figmaParams: Params.Figma,
            commonParams: Params.Common?,
            outputURL: URL,
            ui: TerminalUI
        ) async throws {
            if let variableParams = commonParams?.variablesColors {
                try await exportRawVariables(
                    client: client,
                    variableParams: variableParams,
                    outputURL: outputURL
                )
            } else {
                try await exportRawStyles(
                    client: client,
                    figmaParams: figmaParams,
                    commonParams: commonParams,
                    outputURL: outputURL,
                    ui: ui
                )
            }
        }

        private func exportRawVariables(
            client: FigmaClient,
            variableParams: Params.Common.VariablesColors,
            outputURL: URL
        ) async throws {
            let fileId = variableParams.tokensFileId
            let endpoint = VariablesEndpoint(fileId: fileId)
            let variablesMeta = try await client.request(endpoint)

            let metadata = RawExportMetadata(
                name: options.params.figma.lightFileId,
                fileId: fileId,
                exfigVersion: ExFigCommand.version
            )

            let output = RawExportOutput(source: metadata, data: variablesMeta)
            let exporter = RawExporter()
            let jsonData = try exporter.serialize(output, compact: jsonOptions.compact)

            try jsonData.write(to: outputURL)
        }

        private func exportRawStyles(
            client: FigmaClient,
            figmaParams: Params.Figma,
            commonParams: Params.Common?,
            outputURL: URL,
            ui: TerminalUI
        ) async throws {
            let filterValue = filter

            let colors = try await ui.withSpinner("Fetching colors...") {
                let loader = ColorsLoader(
                    client: client,
                    figmaParams: figmaParams,
                    colorParams: commonParams?.colors,
                    filter: filterValue
                )
                return try await loader.load()
            }

            try ColorExportHelper.exportRaw(
                colors: colors,
                fileId: figmaParams.lightFileId,
                outputURL: outputURL,
                compact: jsonOptions.compact
            )
        }
    }
}

// MARK: - Raw Colors Data Structure

/// Simple structure for raw color export when using styles (not variables).
struct RawColorsData: Encodable, Sendable {
    let light: [RawColorEntry]
    let dark: [RawColorEntry]?
    let lightHC: [RawColorEntry]?
    let darkHC: [RawColorEntry]?
}

struct RawColorEntry: Encodable, Sendable {
    let name: String
    // swiftlint:disable:next identifier_name
    let r, g, b, a: Double

    init(from color: ExFigCore.Color) {
        name = color.name
        r = color.red
        g = color.green
        b = color.blue
        a = color.alpha
    }
}
