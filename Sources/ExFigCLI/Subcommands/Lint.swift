import ArgumentParser
import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

extension ExFigCommand {
    struct Lint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "lint",
            abstract: "Lint Figma file structure against config",
            discussion: """
            Validates that the Figma file follows the conventions required by your ExFig config.
            Checks naming conventions, frame/page structure, variable bindings, dark mode setup, and more.

            Examples:
              exfig lint -i exfig.pkl                              # Lint one config
              exfig lint -i exfig.pkl --rules naming-convention    # Filter rules
              exfig lint -i exfig.pkl --format json                # JSON output for CI
              exfig lint -i exfig.pkl --severity error             # Only errors
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        @Option(name: .long, help: "Comma-separated list of rule IDs to run")
        var rules: String?

        @Option(name: .long, help: "Output format: text or json")
        var format: String = "text"

        @Option(name: .long, help: "Minimum severity: error, warning, or info")
        var severity: String = "info"

        func run() async throws {
            let outputFormat = LintOutputFormat(rawValue: format) ?? .text

            // JSON mode: force quiet to keep stdout clean for machine parsing
            let effectiveVerbose = globalOptions.verbose
            let effectiveQuiet = outputFormat == .json ? true : globalOptions.quiet

            ExFigCommand.initializeTerminalUI(
                verbose: effectiveVerbose, quiet: effectiveQuiet
            )
            ExFigCommand.checkSchemaVersionIfNeeded()
            let ui = ExFigCommand.terminalUI!

            let minSeverity = LintSeverity(rawValue: severity) ?? .info
            let ruleFilter: Set<String>? = rules.map {
                Set($0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) })
            }

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma?.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            let cache = LintDataCache()
            let context = LintContext(config: options.params, client: client, cache: cache, ui: ui)
            let engine = LintEngine.default

            let diagnostics = try await ui.withSpinnerMessage(
                "Linting..."
            ) { updateMessage in
                try await engine.run(
                    context: context,
                    ruleFilter: ruleFilter,
                    minSeverity: minSeverity
                ) { message in
                    updateMessage(message)
                }
            }

            let reporter = LintReporter(
                format: outputFormat,
                useColors: ui.outputMode == .normal
            )
            try reporter.report(diagnostics: diagnostics, ui: ui)

            if diagnostics.contains(where: { $0.severity == .error }) {
                throw ExitCode.failure
            }
        }
    }
}
