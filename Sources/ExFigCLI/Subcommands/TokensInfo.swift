import ArgumentParser
import ExFigCore
import Foundation

extension ExFigCommand.Tokens {
    /// Inspects a local .tokens.json file and prints a summary.
    struct TokensInfo: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "info",
            abstract: "Inspect a .tokens.json file (types, groups, warnings)"
        )

        @Argument(help: "Path to the .tokens.json file")
        var file: String

        @OptionGroup
        var globalOptions: GlobalOptions

        @Flag(name: .long, help: "Output machine-readable JSON")
        var json: Bool = false

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            var source = try TokensFileSource.parse(fileAt: file)
            try source.resolveAliases()

            if json {
                try printJSON(source: source)
            } else {
                printHuman(source: source, ui: ui)
            }
        }

        // MARK: - Human-Readable Output

        private func printHuman(source: TokensFileSource, ui: TerminalUI) {
            let totalCount = source.tokens.count
            let countsByType = source.tokenCountsByType()
            let groups = source.topLevelGroups()

            ui.info("Token file: \(file)")
            ui.info("Tokens: \(totalCount) total")

            if !countsByType.isEmpty {
                let maxTypeLen = countsByType.map(\.type.count).max() ?? 0
                for entry in countsByType {
                    let pct = totalCount > 0
                        ? String(format: "%.1f%%", Double(entry.count) / Double(totalCount) * 100)
                        : "0%"
                    let padded = entry.type.padding(toLength: maxTypeLen + 1, withPad: " ", startingAt: 0)
                    ui.info("  \(padded) \(entry.count) (\(pct))")
                }
            }

            if !groups.isEmpty {
                ui.info("")
                ui.info("Groups:")
                for group in groups {
                    let suffix = group.count == 1 ? "token" : "tokens"
                    ui.info("  \(group.name) (\(group.count) \(suffix))")
                }
            }

            if source.aliasCount > 0 {
                ui.info("")
                ui.info("Aliases: \(source.aliasCount) resolved")
            }

            if !source.warnings.isEmpty {
                ui.info("Warnings: \(source.warnings.count)")
                for warning in source.warnings {
                    ui.warning(warning)
                }
            }
        }

        // MARK: - JSON Output

        private func printJSON(source: TokensFileSource) throws {
            let report = TokensInfoReport(
                file: file,
                totalTokens: source.tokens.count,
                aliases: source.aliasCount,
                types: Dictionary(
                    uniqueKeysWithValues: source.tokenCountsByType().map { ($0.type, $0.count) }
                ),
                groups: Dictionary(
                    uniqueKeysWithValues: source.topLevelGroups().map { ($0.name, $0.count) }
                ),
                warnings: source.warnings
            )
            let jsonData = try JSONCodec.encodePrettySorted(report)
            FileHandle.standardOutput.write(jsonData)
            FileHandle.standardOutput.write(Data("\n".utf8))
        }
    }
}

private struct TokensInfoReport: Codable {
    let file: String
    let totalTokens: Int
    let aliases: Int
    let types: [String: Int]
    let groups: [String: Int]
    let warnings: [String]
}
