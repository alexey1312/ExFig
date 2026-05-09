import ExFigConfig
import Foundation

/// Resolved batch settings after merging CLI flags with the first config's `batch:` block
/// and `figma:` rate-limiting fields.
///
/// Precedence (per knob):
/// - CLI flag (`--parallel`, `--rate-limit`, etc.) > config value > built-in default.
/// - For `failFast`/`resume` (presence flags), CLI || config (either source enables it).
struct ResolvedBatchSettings {
    let parallel: Int
    let failFast: Bool
    let resume: Bool
    let rateLimit: Int
    let maxRetries: Int
    let concurrentDownloads: Int
    let timeout: Int?
}

/// Loads the FIRST config in `exfig batch` argv and merges its `batch:` and `figma:` rate-limiting
/// fields with CLI flags. Per-target `batch:` blocks in subsequent configs are ignored — under
/// `--verbose` they emit a debug log line.
enum BatchSettingsResolver {
    /// Built-in defaults — kept in lockstep with `FaultToleranceOptions` and `Batch` field defaults.
    private enum Defaults {
        static let parallel = 3
        static let rateLimit = 10
        static let maxRetries = 4
    }

    // swiftlint:disable function_parameter_count

    /// - Parameters:
    ///   - cliParallel: `--parallel` value, or nil if user didn't pass.
    ///   - cliFailFast: `--fail-fast` flag (false = not set).
    ///   - cliResume: `--resume` flag (false = not set).
    ///   - cliRateLimit: `--rate-limit` value, or nil if user didn't pass.
    ///   - cliMaxRetries: `--max-retries` value, or nil if user didn't pass.
    ///   - cliConcurrentDownloads: `--concurrent-downloads` value, or nil if user didn't pass.
    ///   - cliTimeout: `--timeout` value (seconds), or nil if user didn't pass.
    ///   - allConfigs: Discovered config URLs in argv order. First wins for batch settings.
    ///   - verbose: When true, emit debug log for ignored per-target `batch:` blocks.
    ///   - ui: Terminal UI for debug/warn output.
    /// - Returns: Resolved settings to drive the batch run.
    static func resolve(
        cliParallel: Int?,
        cliFailFast: Bool,
        cliResume: Bool,
        cliRateLimit: Int?,
        cliMaxRetries: Int?,
        cliConcurrentDownloads: Int?,
        cliTimeout: Int?,
        allConfigs: [URL],
        verbose: Bool,
        ui: TerminalUI
    ) async -> ResolvedBatchSettings {
        let firstConfig: ExFig.ModuleImpl? = await loadFirstConfig(allConfigs: allConfigs, ui: ui)
        let batch = firstConfig?.batch
        let figma = firstConfig?.figma

        if verbose, allConfigs.count > 1 {
            await logIgnoredPerTargetBatchBlocks(otherConfigs: Array(allConfigs.dropFirst()), ui: ui)
        }

        return ResolvedBatchSettings(
            parallel: cliParallel ?? batch?.parallel ?? Defaults.parallel,
            failFast: cliFailFast || (batch?.failFast ?? false),
            resume: cliResume || (batch?.resume ?? false),
            rateLimit: cliRateLimit ?? figma?.rateLimit ?? Defaults.rateLimit,
            maxRetries: cliMaxRetries ?? figma?.maxRetries ?? Defaults.maxRetries,
            concurrentDownloads: cliConcurrentDownloads
                ?? figma?.concurrentDownloads
                ?? FileDownloader.defaultMaxConcurrentDownloads,
            timeout: cliTimeout ?? figma?.timeout.map { Int($0) }
        )
    }

    // swiftlint:enable function_parameter_count

    // MARK: - Internals

    private static func loadFirstConfig(allConfigs: [URL], ui: TerminalUI) async -> ExFig.ModuleImpl? {
        guard let firstURL = allConfigs.first else { return nil }
        do {
            return try await PKLEvaluator.evaluate(configPath: firstURL)
        } catch {
            // Falling back to defaults is safe — the config will be re-evaluated by BatchConfigRunner
            // and any real syntax/validation error will surface there with a per-config error.
            ui.debug(
                "Could not pre-load batch settings from \(firstURL.lastPathComponent): " +
                    "\(error.localizedDescription). Using CLI flags / built-in defaults."
            )
            return nil
        }
    }

    private static func logIgnoredPerTargetBatchBlocks(otherConfigs: [URL], ui: TerminalUI) async {
        for url in otherConfigs {
            let module = try? await PKLEvaluator.evaluate(configPath: url)
            if module?.batch != nil {
                ui.debug(
                    "Ignoring batch: in \(url.lastPathComponent) — only the first config's " +
                        "batch settings apply."
                )
            }
        }
    }
}
