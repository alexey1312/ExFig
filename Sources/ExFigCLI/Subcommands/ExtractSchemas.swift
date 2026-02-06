import ArgumentParser
import Foundation

extension ExFigCommand {
    struct ExtractSchemas: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "schemas",
            abstract: "Extracts PKL schemas to local directory",
            discussion: """
            Extracts PKL schema files used for config validation and IDE support.

            Schemas are extracted to .exfig/schemas/ by default. This enables
            `pkl eval exfig.pkl` to work without a published PKL package.

            Examples:
              exfig schemas                     Extract to .exfig/schemas/
              exfig schemas --output ./schemas  Extract to custom path
              exfig schemas --force             Overwrite existing files
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .shortAndLong, help: "Output directory for schemas.")
        var output: String = SchemaExtractor.defaultOutputDir

        @Flag(name: .shortAndLong, help: "Overwrite existing schema files.")
        var force: Bool = false

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let extracted = try SchemaExtractor.extract(to: output, force: force)

            if extracted.isEmpty {
                ui.info("Schemas already exist at \(output). Use --force to overwrite.")
            } else {
                ui.success("Extracted \(extracted.count) schema files to \(output)/")
                for file in extracted {
                    ui.info("  \(file)")
                }
            }
        }
    }
}
