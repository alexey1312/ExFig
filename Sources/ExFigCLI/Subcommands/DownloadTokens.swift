import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Download Tokens

extension ExFigCommand.Download {
    /// Downloads all design tokens (colors, typography, dimensions, numbers) as a unified W3C JSON file.
    struct DownloadTokens: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "tokens",
            abstract: "Downloads unified design tokens from Figma as W3C JSON"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var jsonOptions: JSONExportOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

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

            ui.info("Downloading unified design tokens from Figma...")

            let outputPath = jsonOptions.output ?? "tokens.json"
            let outputURL = URL(fileURLWithPath: outputPath)
            let exporter = W3CTokensExporter(version: jsonOptions.w3cVersion)

            var allTokens: [String: Any] = [:]

            if options.params.common?.variablesColors != nil {
                try await exportColors(client: client, exporter: exporter, into: &allTokens, ui: ui)
            } else {
                ui.warning(.downloadTokensSectionSkipped(section: "colors"))
            }

            if options.params.figma != nil {
                try await exportTypography(client: client, exporter: exporter, into: &allTokens, ui: ui)
            } else {
                ui.warning(.downloadTokensSectionSkipped(section: "typography"))
            }

            if options.params.common?.variablesColors != nil {
                try await exportNumbers(client: client, exporter: exporter, into: &allTokens, ui: ui)
            } else {
                ui.warning(.downloadTokensSectionSkipped(section: "numbers"))
            }

            if allTokens.isEmpty {
                throw ExFigError.custom(errorString: "No token sections configured for export. Check your config file.")
            }

            let jsonData = try exporter.serializeToJSON(allTokens, compact: jsonOptions.compact)
            try jsonData.write(to: outputURL)

            ui.success("Exported unified tokens to \(outputPath)")
        }

        private func exportColors(
            client: Client, exporter: W3CTokensExporter,
            into allTokens: inout [String: Any], ui: TerminalUI
        ) async throws {
            guard let variableParams = options.params.common?.variablesColors else {
                return
            }

            let colorsResult = try await ui.withSpinner("Fetching colors...") {
                let loader = ColorsVariablesLoader(client: client, variableParams: variableParams, filter: nil)
                return try await loader.load()
            }

            for warning in colorsResult.warnings {
                ui.warning(warning)
            }

            let colorsByMode = ColorExportHelper.buildColorsByMode(from: colorsResult.output)
            let colorTokens = exporter.exportColors(
                colorsByMode: colorsByMode,
                descriptions: colorsResult.descriptions,
                metadata: colorsResult.metadata,
                aliases: colorsResult.aliases,
                modeKeyToName: ColorExportHelper.modeKeyToName
            )
            Self.mergeTokens(from: colorTokens, into: &allTokens)
        }

        private func exportTypography(
            client: Client, exporter: W3CTokensExporter,
            into allTokens: inout [String: Any], ui: TerminalUI
        ) async throws {
            guard let figmaParams = options.params.figma else {
                return
            }

            let textStyles = try await ui.withSpinner("Fetching text styles...") {
                let loader = TextStylesLoader(client: client, params: figmaParams)
                return try await loader.load()
            }

            Self.mergeTokens(from: exporter.exportTypography(textStyles: textStyles), into: &allTokens)
        }

        private func exportNumbers(
            client: Client, exporter: W3CTokensExporter,
            into allTokens: inout [String: Any], ui: TerminalUI
        ) async throws {
            guard let variableParams = options.params.common?.variablesColors else {
                return
            }

            let result = try await ui.withSpinner("Fetching number variables...") {
                let loader = NumberVariablesLoader(
                    client: client,
                    tokensFileId: variableParams.tokensFileId,
                    tokensCollectionName: variableParams.tokensCollectionName
                )
                return try await loader.load()
            }

            for warning in result.warnings {
                ui.warning(warning)
            }

            if !result.dimensions.isEmpty {
                Self.mergeTokens(from: exporter.exportDimensions(tokens: result.dimensions), into: &allTokens)
            }
            if !result.numbers.isEmpty {
                Self.mergeTokens(from: exporter.exportNumbers(tokens: result.numbers), into: &allTokens)
            }
        }

        /// Deep-merges source dictionary into target, preserving existing keys.
        static func mergeTokens(from source: [String: Any], into target: inout [String: Any]) {
            for (key, value) in source {
                if let sourceDict = value as? [String: Any],
                   let targetDict = target[key] as? [String: Any]
                {
                    var merged = targetDict
                    mergeTokens(from: sourceDict, into: &merged)
                    target[key] = merged
                } else {
                    target[key] = value
                }
            }
        }
    }
}
