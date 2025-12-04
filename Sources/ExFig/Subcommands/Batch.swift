import ArgumentParser
import Foundation

extension ExFigCommand {
    struct Batch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "batch",
            abstract: "Process multiple config files in parallel",
            discussion: """
            Process multiple ExFig configuration files in a single command with shared rate limiting.

            Examples:
              exfig batch ./configs/              # Process all configs in directory
              exfig batch config1.yaml config2.yaml  # Process specific files
              exfig batch ./configs/ --parallel 5    # With custom parallelism
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .long, help: "Maximum number of configs to process in parallel (default: 3)")
        var parallel: Int = 3

        @Flag(name: .long, help: "Stop processing on first error")
        var failFast: Bool = false

        @Option(name: .long, help: "Path to write JSON report")
        var report: String?

        @Argument(help: "Config files or directory to process")
        var paths: [String]

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            // Discover configs
            let configURLs = try discoverConfigs(ui: ui)
            guard !configURLs.isEmpty else {
                ui.warning("No config files found")
                return
            }

            // Filter valid configs
            let discovery = ConfigDiscovery()
            let validConfigs = discovery.filterValidConfigs(configURLs)

            if validConfigs.count < configURLs.count {
                let skipped = configURLs.count - validConfigs.count
                ui.warning("Skipping \(skipped) invalid config file(s)")
            }

            guard !validConfigs.isEmpty else {
                ui.warning("No valid ExFig config files found")
                return
            }

            // Check for conflicts
            let conflicts = try discovery.detectOutputPathConflicts(validConfigs)
            for conflict in conflicts {
                let configNames = conflict.configs.map(\.lastPathComponent).joined(separator: ", ")
                ui.warning("Output path conflict: '\(conflict.path)' used by: \(configNames)")
            }

            // Create ConfigFile array
            let configs = validConfigs.map { ConfigFile(url: $0) }

            ui.info("Processing \(configs.count) config(s) with up to \(parallel) parallel workers...")

            // Execute batch
            let executor = BatchExecutor(maxParallel: parallel, failFast: failFast)
            let result = await executor.execute(configs: configs) { configFile in
                await processConfig(configFile, ui: ui)
            }

            // Display summary
            displaySummary(result: result, ui: ui)

            // Write report if requested
            if let reportPath = report {
                try writeReport(result: result, to: reportPath, ui: ui)
            }

            // Exit with error if any failures
            if result.failureCount > 0, !failFast {
                ui.error("Batch completed with \(result.failureCount) failure(s)")
            }
        }

        // MARK: - Private Methods

        private func discoverConfigs(ui: TerminalUI) throws -> [URL] {
            let discovery = ConfigDiscovery()
            var allConfigs: [URL] = []

            for path in paths {
                let url = URL(fileURLWithPath: path)
                var isDirectory: ObjCBool = false

                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let configs = try discovery.discoverConfigs(in: url)
                        allConfigs.append(contentsOf: configs)
                    } else {
                        allConfigs.append(url)
                    }
                } else {
                    throw ConfigDiscoveryError.fileNotFound(url)
                }
            }

            return allConfigs
        }

        private func processConfig(_ configFile: ConfigFile, ui: TerminalUI) async -> ConfigResult {
            ui.info("Processing: \(configFile.name)")

            do {
                // TODO: Implement actual config processing
                // For now, just validate that the config can be loaded
                let data = try Data(contentsOf: configFile.url)
                guard String(data: data, encoding: .utf8) != nil else {
                    throw ExFigError.custom(errorString: "Failed to read config file")
                }

                // Placeholder stats - actual implementation would run exports
                let stats = ExportStats(colors: 0, icons: 0, images: 0, typography: 0)
                ui.success("Completed: \(configFile.name)")
                return .success(config: configFile, stats: stats)

            } catch {
                ui.error("Failed: \(configFile.name) - \(error.localizedDescription)")
                return .failure(config: configFile, error: error)
            }
        }

        private func displaySummary(result: BatchResult, ui: TerminalUI) {
            ui.info("")
            ui.info("Batch complete: \(result.successCount) succeeded, \(result.failureCount) failed")
            ui.info("Duration: \(String(format: "%.2f", result.duration))s")
            ui.info("")

            for success in result.successes {
                let stats = success.stats
                var parts: [String] = []
                if stats.colors > 0 { parts.append("\(stats.colors) colors") }
                if stats.icons > 0 { parts.append("\(stats.icons) icons") }
                if stats.images > 0 { parts.append("\(stats.images) images") }
                if stats.typography > 0 { parts.append("\(stats.typography) typography") }

                let statsString = parts.isEmpty ? "validated" : parts.joined(separator: ", ")
                ui.success("✓ \(success.config.name) - \(statsString)")
            }

            for failure in result.failures {
                ui.error("✗ \(failure.config.name) - \(failure.error.localizedDescription)")
            }
        }

        private func writeReport(result: BatchResult, to path: String, ui: TerminalUI) throws {
            let report = BatchReport(
                startTime: ISO8601DateFormatter().string(from: result.startTime),
                endTime: ISO8601DateFormatter().string(from: result.endTime),
                duration: result.duration,
                totalConfigs: result.results.count,
                successCount: result.successCount,
                failureCount: result.failureCount,
                results: result.results.map { configResult in
                    BatchReport.ConfigReport(
                        name: configResult.config.name,
                        path: configResult.config.url.path,
                        success: configResult.isSuccess,
                        error: configResult.error?.localizedDescription,
                        stats: configResult.stats.map { stats in
                            BatchReport.Stats(
                                colors: stats.colors,
                                icons: stats.icons,
                                images: stats.images,
                                typography: stats.typography
                            )
                        }
                    )
                }
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)

            let url = URL(fileURLWithPath: path)
            try data.write(to: url)
            ui.info("Report written to: \(path)")
        }
    }
}

// MARK: - Report Models

private struct BatchReport: Encodable {
    let startTime: String
    let endTime: String
    let duration: TimeInterval
    let totalConfigs: Int
    let successCount: Int
    let failureCount: Int
    let results: [ConfigReport]

    struct ConfigReport: Encodable {
        let name: String
        let path: String
        let success: Bool
        let error: String?
        let stats: Stats?
    }

    struct Stats: Encodable {
        let colors: Int
        let icons: Int
        let images: Int
        let typography: Int
    }
}
