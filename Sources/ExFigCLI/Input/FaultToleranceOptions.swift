// swiftlint:disable file_length
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

/// CLI options for fault tolerance configuration.
///
/// These options allow users to configure retry behavior and rate limiting
/// for Figma API requests in individual commands.
struct FaultToleranceOptions: ParsableArguments {
    @Option(
        name: .long,
        help: "Maximum retry attempts for failed API requests (overrides config, default: 4)"
    )
    var maxRetries: Int?

    @Option(
        name: .long,
        help: "Maximum API requests per minute (overrides config, default: 10)"
    )
    var rateLimit: Int?

    @Option(
        name: .long,
        help: "Figma API request timeout in seconds (overrides config, default: 30)"
    )
    var timeout: Int?

    mutating func validate() throws {
        try FaultToleranceValidator.validateTimeout(timeout)
        try FaultToleranceValidator.validateRateLimit(rateLimit)
        try FaultToleranceValidator.validateMaxRetries(maxRetries)
    }

    /// CLI value (if user passed --rate-limit) > config value > built-in default.
    /// Invalid config values (out of `FaultToleranceDefaults.rateLimitRange`) trigger a
    /// warning and fall back to the built-in default.
    func effectiveRateLimit(configValue: Int?, ui: TerminalUI? = nil) -> Int {
        if let rateLimit { return rateLimit }
        return FaultToleranceValidator.sanitizedRateLimit(configValue, ui: ui)
    }

    /// CLI value (if user passed --max-retries) > config value > built-in default.
    /// Invalid config values (out of `FaultToleranceDefaults.maxRetriesRange`) trigger a
    /// warning and fall back to the built-in default.
    func effectiveMaxRetries(configValue: Int?, ui: TerminalUI? = nil) -> Int {
        if let maxRetries { return maxRetries }
        return FaultToleranceValidator.sanitizedMaxRetries(configValue, ui: ui)
    }

    /// Create a retry policy from the options.
    /// - Parameter configValue: Config-supplied `figma.maxRetries`, or nil.
    /// - Returns: A configured `RetryPolicy`.
    func createRetryPolicy(configValue: Int? = nil) -> RetryPolicy {
        RetryPolicy(maxRetries: effectiveMaxRetries(configValue: configValue))
    }

    /// Create a shared rate limiter from the options.
    /// - Parameter configValue: Config-supplied `figma.rateLimit`, or nil.
    /// - Returns: A configured `SharedRateLimiter`.
    func createRateLimiter(configValue: Int? = nil) -> SharedRateLimiter {
        SharedRateLimiter(requestsPerMinute: Double(effectiveRateLimit(configValue: configValue)))
    }

    /// Create a rate-limited client wrapping the given client.
    /// - Parameters:
    ///   - client: The underlying client to wrap.
    ///   - rateLimiter: The shared rate limiter to use.
    ///   - configMaxRetries: Config-supplied `figma.maxRetries`, or nil.
    ///   - configID: Identifier for this client's config (default: "default").
    ///   - onRetry: Optional callback invoked before each retry attempt.
    /// - Returns: A `RateLimitedClient` instance.
    func createRateLimitedClient(
        wrapping client: Client,
        rateLimiter: SharedRateLimiter,
        configMaxRetries: Int? = nil,
        configID: ConfigID = ConfigID("default"),
        onRetry: RetryCallback? = nil
    ) -> Client {
        RateLimitedClient(
            client: client,
            rateLimiter: rateLimiter,
            configID: configID,
            retryPolicy: createRetryPolicy(configValue: configMaxRetries),
            onRetry: onRetry
        )
    }
}

// MARK: - Heavy Fault Tolerance Options

/// Extended fault tolerance options for commands that download many files.
///
/// In addition to basic retry and rate limiting, these options support:
/// - `--fail-fast`: Stop on first error without retrying
/// - `--resume`: Continue from checkpoint after interruption
/// - `--timeout`: Figma API request timeout in seconds
struct HeavyFaultToleranceOptions: ParsableArguments {
    @Option(
        name: .long,
        help: "Maximum retry attempts for failed API requests (overrides config, default: 4)"
    )
    var maxRetries: Int?

    @Option(
        name: .long,
        help: "Maximum API requests per minute (overrides config, default: 10)"
    )
    var rateLimit: Int?

    @Option(
        name: .long,
        help: "Figma API request timeout in seconds (overrides config, default: 30)"
    )
    var timeout: Int?

    @Flag(
        name: .long,
        help: "Stop on first error without retrying (overrides config)"
    )
    var failFast: Bool = false

    @Flag(
        name: .long,
        help: "Continue from checkpoint after interruption (overrides config)"
    )
    var resume: Bool = false

    @Option(
        name: .long,
        help: "Maximum concurrent CDN downloads (overrides config, default: 20)"
    )
    var concurrentDownloads: Int?

    mutating func validate() throws {
        try FaultToleranceValidator.validateTimeout(timeout)
        try FaultToleranceValidator.validateRateLimit(rateLimit)
        try FaultToleranceValidator.validateMaxRetries(maxRetries)
        try FaultToleranceValidator.validateConcurrentDownloads(concurrentDownloads)
    }

    /// CLI value (if user passed --rate-limit) > config value > built-in default.
    func effectiveRateLimit(configValue: Int?, ui: TerminalUI? = nil) -> Int {
        if let rateLimit { return rateLimit }
        return FaultToleranceValidator.sanitizedRateLimit(configValue, ui: ui)
    }

    /// CLI value (if user passed --max-retries) > config value > built-in default.
    func effectiveMaxRetries(configValue: Int?, ui: TerminalUI? = nil) -> Int {
        if let maxRetries { return maxRetries }
        return FaultToleranceValidator.sanitizedMaxRetries(configValue, ui: ui)
    }

    /// CLI value (if user passed --concurrent-downloads) > config value > built-in default.
    func effectiveConcurrentDownloads(configValue: Int?, ui: TerminalUI? = nil) -> Int {
        if let concurrentDownloads { return concurrentDownloads }
        return FaultToleranceValidator.sanitizedConcurrentDownloads(configValue, ui: ui)
    }

    /// Create a file downloader with configured concurrency.
    /// - Parameter configValue: Config-supplied `figma.concurrentDownloads`, or nil.
    /// - Returns: A configured `FileDownloader`.
    func createFileDownloader(configValue: Int? = nil) -> FileDownloader {
        FileDownloader(maxConcurrentDownloads: effectiveConcurrentDownloads(configValue: configValue))
    }

    /// Create a retry policy from the options.
    /// `--fail-fast` (CLI flag) forces 0 retries regardless of config.
    /// - Parameter configValue: Config-supplied `figma.maxRetries`, or nil.
    /// - Returns: A configured `RetryPolicy`.
    func createRetryPolicy(configValue: Int? = nil) -> RetryPolicy {
        if failFast {
            return RetryPolicy(maxRetries: 0)
        }
        return RetryPolicy(maxRetries: effectiveMaxRetries(configValue: configValue))
    }

    /// Create a shared rate limiter from the options.
    /// - Parameter configValue: Config-supplied `figma.rateLimit`, or nil.
    /// - Returns: A configured `SharedRateLimiter`.
    func createRateLimiter(configValue: Int? = nil) -> SharedRateLimiter {
        SharedRateLimiter(requestsPerMinute: Double(effectiveRateLimit(configValue: configValue)))
    }

    /// Create a rate-limited client wrapping the given client.
    /// - Parameters:
    ///   - client: The underlying client to wrap.
    ///   - rateLimiter: The shared rate limiter to use.
    ///   - configMaxRetries: Config-supplied `figma.maxRetries`, or nil.
    ///   - configID: Identifier for this client's config (default: "default").
    ///   - onRetry: Optional callback invoked before each retry attempt.
    /// - Returns: A `RateLimitedClient` instance.
    func createRateLimitedClient(
        wrapping client: Client,
        rateLimiter: SharedRateLimiter,
        configMaxRetries: Int? = nil,
        configID: ConfigID = ConfigID("default"),
        onRetry: RetryCallback? = nil
    ) -> Client {
        RateLimitedClient(
            client: client,
            rateLimiter: rateLimiter,
            configID: configID,
            retryPolicy: createRetryPolicy(configValue: configMaxRetries),
            onRetry: onRetry
        )
    }

    // MARK: - Checkpoint Management

    /// Load or create a checkpoint tracker for resumable downloads.
    /// - Parameters:
    ///   - configPath: Path to the config file.
    ///   - workingDirectory: Directory to save checkpoint file.
    ///   - assetType: Type of assets (icons or images).
    ///   - assetNames: Set of all asset names to track.
    ///   - ui: Terminal UI for progress messages.
    /// - Returns: Checkpoint tracker, or nil if resume is disabled.
    func loadOrCreateCheckpoint(
        configPath: String,
        workingDirectory: URL,
        assetType: CheckpointTracker.AssetType,
        assetNames: Set<String>,
        ui: TerminalUI
    ) async throws -> CheckpointTracker? {
        guard resume else { return nil }

        // Try to load existing checkpoint
        if let existing = try CheckpointTracker.loadIfValid(
            configPath: configPath,
            directory: workingDirectory,
            assetType: assetType
        ) {
            let completed = await existing.completedNames.count
            let pending = await existing.pendingNames.count
            ui.info("Resuming: \(completed) completed, \(pending) remaining")
            return existing
        }

        // Create new checkpoint
        return try CheckpointTracker(
            configPath: configPath,
            directory: workingDirectory,
            assetType: assetType,
            assetNames: assetNames
        )
    }

    /// Filter files to download based on checkpoint state.
    /// - Parameters:
    ///   - files: All files to potentially download.
    ///   - checkpoint: Optional checkpoint tracker.
    /// - Returns: Files that need to be downloaded (excluding completed ones).
    func filterFilesForDownload(
        _ files: [FileContents],
        checkpoint: CheckpointTracker?
    ) async -> [FileContents] {
        guard let checkpoint else { return files }
        return await checkpoint.filterPending(files)
    }

    /// Mark files as completed and save checkpoint.
    /// - Parameters:
    ///   - files: Downloaded files to mark as completed.
    ///   - checkpoint: Optional checkpoint tracker.
    func markFilesCompleted(
        _ files: [FileContents],
        checkpoint: CheckpointTracker?
    ) async {
        guard let checkpoint else { return }
        let names = files.map { $0.destination.file.deletingPathExtension().lastPathComponent }
        await checkpoint.markCompleted(names)
    }

    /// Finalize checkpoint after successful export.
    /// - Parameter checkpoint: Optional checkpoint tracker to clean up.
    func finalizeCheckpoint(_ checkpoint: CheckpointTracker?) async throws {
        guard let checkpoint else { return }
        if await checkpoint.isComplete {
            try await checkpoint.delete()
        } else {
            try await checkpoint.save()
        }
    }
}

// MARK: - Client Resolution

/// Common surface used by `resolveClient` to bridge the two CLI option types.
protocol RateLimitClientFactory {
    var timeout: Int? { get }
    func createRateLimiter(configValue: Int?) -> SharedRateLimiter
    func effectiveMaxRetries(configValue: Int?, ui: TerminalUI?) -> Int
    func createRateLimitedClient(
        wrapping client: Client,
        rateLimiter: SharedRateLimiter,
        configMaxRetries: Int?,
        configID: ConfigID,
        onRetry: RetryCallback?
    ) -> Client
}

extension FaultToleranceOptions: RateLimitClientFactory {}
extension HeavyFaultToleranceOptions: RateLimitClientFactory {}

/// Resolves a Figma API client, using injected client if available (batch mode)
/// or creating a new rate-limited client (standalone command mode).
///
/// When `accessToken` is nil (no `FIGMA_PERSONAL_TOKEN`), returns ``NoTokenFigmaClient`` —
/// a fail-fast client that throws on any request. Non-Figma sources (Penpot, tokens-file)
/// never call it, so pure-Penpot workflows work without Figma credentials.
///
/// - Parameters:
///   - accessToken: Figma personal access token (nil when using non-Figma sources only).
///   - timeout: Request timeout interval from config (optional, uses FigmaClient default if nil).
///   - rateLimit: Config-supplied `figma.rateLimit` (optional). CLI `--rate-limit` overrides.
///   - maxRetries: Config-supplied `figma.maxRetries` (optional). CLI `--max-retries` overrides.
///   - options: Fault tolerance options (may contain CLI overrides).
///   - ui: Terminal UI for retry warnings.
/// - Returns: A configured `Client` instance.
///
/// Precedence (per knob): CLI flag > config value > built-in default.
func resolveClient(
    accessToken: String?,
    timeout: TimeInterval?,
    rateLimit configRateLimit: Int? = nil,
    maxRetries configMaxRetries: Int? = nil,
    options: some RateLimitClientFactory,
    ui: TerminalUI
) -> Client {
    if let injectedClient = InjectedClientStorage.client {
        return injectedClient
    }
    guard let accessToken else {
        // No Figma token — return a client that throws on any call.
        // Non-Figma sources (Penpot, tokens-file) never call it.
        // SourceFactory also guards the .figma branch with accessTokenNotFound.
        return NoTokenFigmaClient()
    }
    // CLI timeout takes precedence over config timeout
    let effectiveTimeout: TimeInterval? = options.timeout.map { TimeInterval($0) } ?? timeout
    let baseClient = FigmaClient(accessToken: accessToken, timeout: effectiveTimeout)
    let rateLimiter = options.createRateLimiter(configValue: configRateLimit)
    let effectiveMaxRetries = options.effectiveMaxRetries(configValue: configMaxRetries, ui: ui)
    return options.createRateLimitedClient(
        wrapping: baseClient,
        rateLimiter: rateLimiter,
        configMaxRetries: configMaxRetries,
        configID: ConfigID("default"),
        onRetry: { attempt, error in
            let warning = ExFigWarning.retrying(
                attempt: attempt,
                maxAttempts: effectiveMaxRetries,
                error: error.localizedDescription,
                delay: "..."
            )
            ui.warning(warning)
        }
    )
}

// MARK: - No-Token Client

/// A Figma API client placeholder that throws `accessTokenNotFound` on any request.
///
/// Used when `FIGMA_PERSONAL_TOKEN` is not set. Non-Figma sources (Penpot, tokens-file)
/// never call this client. If accidentally invoked, the error message clearly tells the user
/// to set the token — instead of making real HTTP requests with an invalid token.
final class NoTokenFigmaClient: Client, @unchecked Sendable {
    func request<T: Endpoint>(_: T) async throws -> T.Content {
        throw ExFigError.accessTokenNotFound
    }
}
