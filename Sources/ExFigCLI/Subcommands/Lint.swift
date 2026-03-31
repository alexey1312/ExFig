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
            ExFigCommand.initializeTerminalUI(
                verbose: globalOptions.verbose, quiet: globalOptions.quiet
            )
            ExFigCommand.checkSchemaVersionIfNeeded()
            let ui = ExFigCommand.terminalUI!

            let outputFormat = LintOutputFormat(rawValue: format) ?? .text
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

            let context = LintContext(config: options.params, client: client, ui: ui)
            let engine = LintEngine.default

            let diagnostics = try await ui.withSpinner("Linting Figma file structure...") {
                try await engine.run(
                    context: context,
                    ruleFilter: ruleFilter,
                    minSeverity: minSeverity
                )
            }

            let reporter = LintReporter(
                format: outputFormat,
                useColors: ui.outputMode == .normal
            )
            try reporter.report(diagnostics: diagnostics, ui: ui)

            // Exit with code 1 if there are errors (for CI)
            if diagnostics.contains(where: { $0.severity == .error }) {
                throw ExitCode.failure
            }
        }
    }
}
