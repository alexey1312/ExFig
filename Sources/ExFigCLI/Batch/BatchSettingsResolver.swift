import ExFigConfig
import Foundation

/// Resolved batch settings after merging CLI flags with the first config's `batch:` block
/// and `figma:` rate-limiting fields.
///
/// Precedence (per knob):
/// - CLI flag (`--parallel`, `--rate-limit`, etc.) > config value > built-in default.
/// - For `failFast`/`resume` (presence flags), CLI || config (either source enables it).
///
/// Construction is restricted to ``BatchSettingsResolver/resolve(...)`` — the resolver guarantees
/// that values fall within the documented ranges (CLI is validated, PKL values are clamped with
/// a warning when out of range).
struct ResolvedBatchSettings {
    let parallel: Int
    let failFast: Bool
    let resume: Bool
    let rateLimit: Int
    let maxRetries: Int
    let concurrentDownloads: Int
    let timeout: Int?

    fileprivate init(
        parallel: Int,
        failFast: Bool,
        resume: Bool,
        rateLimit: Int,
        maxRetries: Int,
        concurrentDownloads: Int,
        timeout: Int?
    ) {
        self.parallel = parallel
        self.failFast = failFast
        self.resume = resume
        self.rateLimit = rateLimit
        self.maxRetries = maxRetries
        self.concurrentDownloads = concurrentDownloads
        self.timeout = timeout
    }
}

/// Loads the FIRST config in `exfig batch` argv and merges its `batch:` and `figma:` rate-limiting
/// fields with CLI flags. Per-target `batch:` blocks (and per-target `figma:*` rate-limiting fields)
/// in subsequent configs are ignored — under `--verbose` they emit a warning.
enum BatchSettingsResolver {
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
    ///   - verbose: When true, emit a warning for ignored per-target `batch:` blocks.
    ///   - ui: Terminal UI for debug/warn output.
    ///   - moduleCache: Optional cache to populate with the first-config evaluation result so
    ///     downstream consumers (`BatchConfigRunner`) can skip a redundant PKL eval.
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
        ui: TerminalUI,
        moduleCache: PKLModuleCache? = nil
    ) async -> ResolvedBatchSettings {
        let firstConfig: ExFig.ModuleImpl? = await loadFirstConfig(
            allConfigs: allConfigs,
            ui: ui,
            moduleCache: moduleCache
        )
        let batch = firstConfig?.batch
        let figma = firstConfig?.figma

        if verbose, allConfigs.count > 1 {
            await logIgnoredPerTargetSettings(
                otherConfigs: Array(allConfigs.dropFirst()),
                ui: ui,
                moduleCache: moduleCache
            )
        }

        return ResolvedBatchSettings(
            parallel: cliParallel
                ?? FaultToleranceValidator.sanitizedParallel(batch?.parallel, ui: ui),
            failFast: cliFailFast || (batch?.failFast ?? false),
            resume: cliResume || (batch?.resume ?? false),
            rateLimit: cliRateLimit
                ?? FaultToleranceValidator.sanitizedRateLimit(figma?.rateLimit, ui: ui),
            maxRetries: cliMaxRetries
                ?? FaultToleranceValidator.sanitizedMaxRetries(figma?.maxRetries, ui: ui),
            concurrentDownloads: cliConcurrentDownloads
                ?? FaultToleranceValidator.sanitizedConcurrentDownloads(figma?.concurrentDownloads, ui: ui),
            timeout: cliTimeout
                ?? FaultToleranceValidator.sanitizedTimeout(figma?.timeout.map { Int($0) }, ui: ui)
        )
    }

    // swiftlint:enable function_parameter_count

    // MARK: - Internals

    private static func loadFirstConfig(
        allConfigs: [URL],
        ui: TerminalUI,
        moduleCache: PKLModuleCache?
    ) async -> ExFig.ModuleImpl? {
        guard let firstURL = allConfigs.first else { return nil }
        do {
            let module = try await PKLEvaluator.evaluate(configPath: firstURL)
            await moduleCache?.set(module, for: firstURL)
            return module
        } catch {
            // File-not-found will surface again in BatchConfigRunner with a clearer message;
            // for that case we keep the message under -v. For real PKL/syntax/network errors,
            // batch settings from the user are silently dropped — promote to a visible warning
            // so the user knows defaults are in effect.
            if isFileNotFound(error: error, url: firstURL) {
                ui.debug(
                    "Pre-load skipped: \(firstURL.lastPathComponent) not found. " +
                        "BatchConfigRunner will surface the error per-config."
                )
            } else {
                ui.warning(.batchSettingsPreloadFailed(
                    file: firstURL.lastPathComponent,
                    error: error.localizedDescription
                ))
            }
            return nil
        }
    }

    private static func logIgnoredPerTargetSettings(
        otherConfigs: [URL],
        ui: TerminalUI,
        moduleCache: PKLModuleCache?
    ) async {
        for url in otherConfigs {
            let module: ExFig.ModuleImpl?
            do {
                module = try await PKLEvaluator.evaluate(configPath: url)
                await moduleCache?.set(module, for: url)
            } catch {
                ui.debug(
                    "Could not pre-check \(url.lastPathComponent) for ignored batch settings: " +
                        "\(error.localizedDescription)"
                )
                continue
            }
            if module?.batch != nil {
                ui.warning(.ignoredPerTargetBatchBlock(file: url.lastPathComponent))
            }
            if let figma = module?.figma,
               figma.rateLimit != nil
               || figma.maxRetries != nil
               || figma.concurrentDownloads != nil
               || figma.timeout != nil
            {
                ui.warning(.ignoredPerTargetFigmaRateLimiting(file: url.lastPathComponent))
            }
        }
    }

    private static func isFileNotFound(error: Error, url: URL) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileReadNoSuchFileError {
            return true
        }
        if nsError.domain == NSPOSIXErrorDomain, nsError.code == Int(ENOENT) {
            return true
        }
        // PklSwift surfaces missing files via PklError text — a textual match is brittle but
        // acceptable as a fallback (better than over-warning the user).
        let message = error.localizedDescription.lowercased()
        if message.contains("no such file") || message.contains("not found") {
            return true
        }
        return !FileManager.default.fileExists(atPath: url.path)
    }
}
