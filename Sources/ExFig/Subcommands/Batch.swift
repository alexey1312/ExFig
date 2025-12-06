import ArgumentParser
import FigmaAPI
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
              exfig batch ./configs/ --rate-limit 20 # Custom rate limit
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .long, help: "Maximum number of configs to process in parallel (default: 3)")
        var parallel: Int = 3

        @Flag(name: .long, help: "Stop processing on first error")
        var failFast: Bool = false

        @Option(name: .long, help: "Figma API requests per minute (default: 10)")
        var rateLimit: Int = 10

        @Option(name: .long, help: "Maximum retry attempts for failed requests (default: 4)")
        var maxRetries: Int = 4

        @Flag(name: .long, help: "Resume from previous checkpoint if available")
        var resume: Bool = false

        @Option(name: .long, help: "Path to write JSON report")
        var report: String?

        @Argument(help: "Config files or directory to process")
        var paths: [String]

        // swiftlint:disable:next function_body_length
        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            // Discover and validate configs
            let validConfigs = try discoverAndValidateConfigs(ui: ui)
            guard !validConfigs.isEmpty else { return }

            // Prepare configs with checkpoint handling
            let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let (configs, checkpoint) = prepareConfigsWithCheckpoint(
                validConfigs: validConfigs,
                workingDirectory: workingDirectory,
                ui: ui
            )

            guard !configs.isEmpty else {
                ui.success("All configs already completed!")
                try? BatchCheckpoint.delete(from: workingDirectory)
                return
            }

            // Execute batch
            let (result, rateLimiter) = await executeBatch(
                configs: configs,
                checkpoint: checkpoint,
                workingDirectory: workingDirectory,
                ui: ui
            )

            // Handle results
            handleResults(
                result: result,
                rateLimiter: rateLimiter,
                workingDirectory: workingDirectory,
                ui: ui
            )
        }

        // MARK: - Run Helpers

        private func discoverAndValidateConfigs(ui: TerminalUI) throws -> [URL] {
            let configURLs = try discoverConfigs(ui: ui)
            guard !configURLs.isEmpty else {
                ui.warning("No config files found")
                return []
            }

            let discovery = ConfigDiscovery()
            let validConfigs = discovery.filterValidConfigs(configURLs)

            if validConfigs.count < configURLs.count {
                let skipped = configURLs.count - validConfigs.count
                ui.warning("Skipping \(skipped) invalid config file(s)")
            }

            guard !validConfigs.isEmpty else {
                ui.warning("No valid ExFig config files found")
                return []
            }

            // Check for conflicts
            let conflicts = try discovery.detectOutputPathConflicts(validConfigs)
            for conflict in conflicts {
                let configNames = conflict.configs.map(\.lastPathComponent).joined(separator: ", ")
                ui.warning("Output path conflict: '\(conflict.path)' used by: \(configNames)")
            }

            return validConfigs
        }

        private func prepareConfigsWithCheckpoint(
            validConfigs: [URL],
            workingDirectory: URL,
            ui: TerminalUI
        ) -> ([ConfigFile], BatchCheckpoint) {
            var configs = validConfigs.map { ConfigFile(url: $0) }
            var checkpoint = loadCheckpointIfResuming(workingDirectory: workingDirectory, ui: ui)

            if let existing = checkpoint {
                let skipped = existing.completedConfigs.count
                configs = configs.filter { !existing.isCompleted($0.url.path) }
                ui.info("Resuming: \(skipped) config(s) already completed, \(configs.count) remaining")
            } else {
                checkpoint = BatchCheckpoint(requestedPaths: paths)
            }

            return (configs, checkpoint!)
        }

        private func loadCheckpointIfResuming(workingDirectory: URL, ui: TerminalUI) -> BatchCheckpoint? {
            guard resume else { return nil }

            guard let existing = try? BatchCheckpoint.load(from: workingDirectory) else {
                return nil
            }

            if existing.isExpired() {
                ui.warning("Checkpoint expired (older than 24h), starting fresh")
                try? BatchCheckpoint.delete(from: workingDirectory)
                return nil
            }

            if !existing.matchesPaths(paths) {
                ui.warning("Checkpoint paths don't match current request, starting fresh")
                try? BatchCheckpoint.delete(from: workingDirectory)
                return nil
            }

            return existing
        }

        private func executeBatch(
            configs: [ConfigFile],
            checkpoint: BatchCheckpoint,
            workingDirectory: URL,
            ui: TerminalUI
        ) async -> (BatchResult, SharedRateLimiter) {
            let rateLimiter = SharedRateLimiter(requestsPerMinute: Double(rateLimit))
            let retryPolicy = RetryPolicy(maxRetries: maxRetries)
            let runner = BatchConfigRunner(
                rateLimiter: rateLimiter,
                retryPolicy: retryPolicy,
                globalOptions: globalOptions,
                maxRetries: maxRetries,
                resume: resume
            )

            ui.info("Processing \(configs.count) config(s) with up to \(parallel) parallel workers...")
            if globalOptions.verbose {
                ui.info("Rate limit: \(rateLimit) req/min, max retries: \(maxRetries)")
            }

            let executor = BatchExecutor(
                maxParallel: parallel,
                failFast: failFast
            )

            let checkpointManager = CheckpointManager(checkpoint: checkpoint, directory: workingDirectory)

            let result = await executor.execute(configs: configs) { configFile in
                let configResult = await runner.process(configFile: configFile, ui: ui)
                await checkpointManager.update(for: configFile, result: configResult)
                return configResult
            }

            return (result, rateLimiter)
        }

        private func handleResults(
            result: BatchResult,
            rateLimiter: SharedRateLimiter,
            workingDirectory: URL,
            ui: TerminalUI
        ) {
            displaySummary(result: result, ui: ui)

            if globalOptions.verbose {
                Task {
                    let status = await rateLimiter.status()
                    displayRateLimitStatus(status: status, ui: ui)
                }
            }

            if let reportPath = report {
                try? writeReport(result: result, to: reportPath, ui: ui)
            }

            if result.failureCount == 0 {
                try? BatchCheckpoint.delete(from: workingDirectory)
                if globalOptions.verbose {
                    ui.info("Checkpoint cleared (all configs completed successfully)")
                }
            } else if !failFast {
                ui.error("Batch completed with \(result.failureCount) failure(s)")
                ui.info("Run with --resume to retry failed configs")
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

        private func displayRateLimitStatus(status: RateLimiterStatus, ui: TerminalUI) {
            ui.info("")
            ui.info("Rate Limiter Stats:")
            ui.info("  Configured: \(Int(status.requestsPerMinute)) req/min")

            let available = String(format: "%.1f", status.availableTokens)
            let max = String(format: "%.0f", status.maxTokens)
            ui.info("  Tokens: \(available)/\(max)")

            if !status.configRequestCounts.isEmpty {
                let totalRequests = status.configRequestCounts.values.reduce(0, +)
                ui.info("  Total requests: \(totalRequests)")
            }

            if status.isPaused, let retryAfter = status.retryAfter {
                ui.warning("  Status: Paused (retry after \(Int(retryAfter))s)")
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

// MARK: - Checkpoint Manager

/// Actor for safely updating batch checkpoint from concurrent tasks.
private actor CheckpointManager {
    private var checkpoint: BatchCheckpoint
    private let directory: URL

    init(checkpoint: BatchCheckpoint, directory: URL) {
        self.checkpoint = checkpoint
        self.directory = directory
    }

    func update(for config: ConfigFile, result: ConfigResult) {
        switch result {
        case .success:
            checkpoint.markCompleted(config.url.path)
        case .failure:
            checkpoint.markFailed(config.url.path)
        }

        // Save checkpoint after each update
        try? checkpoint.save(to: directory)
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
