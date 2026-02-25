import ArgumentParser
import ExFigCore
import Foundation

extension ExFigCommand.Tokens {
    /// Filters and re-exports a .tokens.json file in W3C Design Tokens format.
    struct TokensConvert: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "convert",
            abstract: "Filter and re-export a .tokens.json file as W3C JSON"
        )

        @Argument(help: "Path to the .tokens.json file")
        var file: String

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .shortAndLong, help: "Output file path (default: stdout)")
        var output: String?

        @Option(name: .long, help: "Filter by group path prefix (e.g., \"Brand.Colors\")")
        var group: String?

        @Option(
            name: .long,
            parsing: .upToNextOption,
            help: "Filter by token type(s): color, dimension, number, typography"
        )
        var type: [String] = []

        @Option(name: .long, help: "W3C spec version: v2025 (default) or v1 (legacy hex format)")
        var w3cVersion: W3CVersion = .v2025

        @Flag(name: .long, help: "Output minified JSON")
        var compact: Bool = false

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            // Parse and resolve
            var source = try TokensFileSource.parse(fileAt: file)
            try source.resolveAliases()

            // Apply filters
            if let group {
                source = source.filteredByGroup(group)
            }
            if !type.isEmpty {
                source = source.filteredByTypes(Set(type))
            }

            if source.tokens.isEmpty {
                ui.warning("No tokens match the given filters")
                return
            }

            // Export
            let exporter = W3CTokensExporter(version: w3cVersion)
            let allTokens = exporter.exportAll(from: source)
            let jsonData = try exporter.serializeToJSON(allTokens, compact: compact)

            if let outputPath = output {
                let outputURL = URL(fileURLWithPath: outputPath)
                try jsonData.write(to: outputURL)
                ui.success("Exported \(source.tokens.count) tokens to \(outputPath)")
            } else {
                FileHandle.standardOutput.write(jsonData)
                FileHandle.standardOutput.write(Data("\n".utf8))
            }
        }
    }
}
