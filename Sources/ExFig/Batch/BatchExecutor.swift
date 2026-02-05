import FigmaAPI
import Foundation
import Rainbow

/// Type alias for config processing handler.
typealias ConfigHandler = @Sendable (ConfigFile) async -> ConfigResult

/// Type alias for config processing handler with rate-limited client.
typealias RateLimitedConfigHandler = @Sendable (ConfigFile, RateLimitedClient) async -> ConfigResult

/// Type alias for retry event handler.
typealias RetryEventHandler = @Sendable (String, Int, Error, TimeInterval) -> Void

/// Executes batch processing of multiple configs with controlled parallelism.
actor BatchExecutor {
    /// Maximum number of configs to process in parallel.
    private let maxParallel: Int
    /// Whether to stop on first error.
    private let failFast: Bool
    /// Shared rate limiter for coordinating API requests.
    private let rateLimiter: SharedRateLimiter?
    /// Base Figma client (shared across all configs).
    private let baseClient: Client?
    /// Retry policy for API requests.
    private let retryPolicy: RetryPolicy
    /// Handler for retry events (for logging).
    private let onRetryEvent: RetryEventHandler?
    /// Cancellation flag.
    private var isCancelled = false

    /// Create a new batch executor.
    /// - Parameters:
    ///   - maxParallel: Maximum concurrent configs (default: 3).
    ///   - failFast: Stop on first error (default: false).
    ///   - rateLimiter: Optional shared rate limiter.
    ///   - baseClient: Optional base client for rate-limited wrapping.
    ///   - retryPolicy: Retry policy for API requests (default: standard policy).
    ///   - onRetryEvent: Optional handler for retry events (for logging).
    init(
        maxParallel: Int = 3,
        failFast: Bool = false,
        rateLimiter: SharedRateLimiter? = nil,
        baseClient: Client? = nil,
        retryPolicy: RetryPolicy = RetryPolicy(),
        onRetryEvent: RetryEventHandler? = nil
    ) {
        self.maxParallel = max(1, maxParallel)
        self.failFast = failFast
        self.rateLimiter = rateLimiter
        self.baseClient = baseClient
        self.retryPolicy = retryPolicy
        self.onRetryEvent = onRetryEvent
    }

    /// Execute batch processing of configs.
    /// - Parameters:
    ///   - configs: Configs to process.
    ///   - handler: Handler to process each config.
    /// - Returns: Batch result with all config results.
    func execute(
        configs: [ConfigFile],
        handler: @escaping ConfigHandler
    ) async -> BatchResult {
        let startTime = Date()
        var results: [ConfigResult] = []

        if failFast {
            results = await executeSequentialWithFailFast(configs: configs, handler: handler)
        } else {
            results = await executeParallel(configs: configs, handler: handler)
        }

        let endTime = Date()
        return BatchResult(
            results: results,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }

    /// Execute batch processing with rate-limited clients.
    /// - Parameters:
    ///   - configs: Configs to process.
    ///   - handler: Handler that receives config and rate-limited client.
    /// - Returns: Batch result with all config results.
    func executeWithRateLimiting(
        configs: [ConfigFile],
        handler: @escaping RateLimitedConfigHandler
    ) async -> BatchResult {
        guard let rateLimiter, let baseClient else {
            // Fall back to non-rate-limited execution
            return await execute(configs: configs) { config in
                // Create a dummy result for configs without rate limiting
                .failure(config: config, error: BatchExecutorError.rateLimiterNotConfigured)
            }
        }

        // Reset stats for clean tracking
        await rateLimiter.resetAllStats()

        let startTime = Date()
        var results: [ConfigResult] = []

        if failFast {
            results = await executeSequentialWithRateLimiting(
                configs: configs,
                rateLimiter: rateLimiter,
                baseClient: baseClient,
                handler: handler
            )
        } else {
            results = await executeParallelWithRateLimiting(
                configs: configs,
                rateLimiter: rateLimiter,
                baseClient: baseClient,
                handler: handler
            )
        }

        let endTime = Date()
        return BatchResult(
            results: results,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }

    /// Get current rate limiter status.
    func rateLimiterStatus() async -> RateLimiterStatus? {
        await rateLimiter?.status()
    }

    /// Cancel ongoing batch execution.
    func cancel() {
        isCancelled = true
    }

    // MARK: - Private Methods

    private func executeSequentialWithFailFast(
        configs: [ConfigFile],
        handler: @escaping ConfigHandler
    ) async -> [ConfigResult] {
        var results: [ConfigResult] = []

        for config in configs {
            if isCancelled { break }

            let result = await handler(config)
            results.append(result)

            if case .failure = result {
                break // Stop on first failure
            }
        }

        return results
    }

    private func executeParallel(
        configs: [ConfigFile],
        handler: @escaping ConfigHandler
    ) async -> [ConfigResult] {
        await withTaskGroup(of: ConfigResult.self) { [maxParallel] group in
            var results: [ConfigResult] = []
            var running = 0
            var configIterator = configs.makeIterator()

            // Start initial batch up to maxParallel
            while running < maxParallel, let config = configIterator.next() {
                group.addTask {
                    await handler(config)
                }
                running += 1
            }

            // Process remaining configs as others complete
            for await result in group {
                results.append(result)
                running -= 1

                // Start next config if available
                if let config = configIterator.next() {
                    group.addTask {
                        await handler(config)
                    }
                    running += 1
                }
            }

            return results
        }
    }

    private func executeSequentialWithRateLimiting(
        configs: [ConfigFile],
        rateLimiter: SharedRateLimiter,
        baseClient: Client,
        handler: @escaping RateLimitedConfigHandler
    ) async -> [ConfigResult] {
        var results: [ConfigResult] = []

        for config in configs {
            if isCancelled { break }

            let rateLimitedClient = createRateLimitedClient(
                for: config,
                rateLimiter: rateLimiter,
                baseClient: baseClient
            )

            let result = await handler(config, rateLimitedClient)
            results.append(result)

            if case .failure = result {
                break // Stop on first failure
            }
        }

        return results
    }

    private func executeParallelWithRateLimiting(
        configs: [ConfigFile],
        rateLimiter: SharedRateLimiter,
        baseClient: Client,
        handler: @escaping RateLimitedConfigHandler
    ) async -> [ConfigResult] {
        // Capture self properties for use in task group
        let retryPolicy = retryPolicy
        let onRetryEvent = onRetryEvent

        return await withTaskGroup(of: ConfigResult.self) { [maxParallel] group in
            var results: [ConfigResult] = []
            var running = 0
            var configIterator = configs.makeIterator()

            /// Helper to create rate-limited client and process config
            func processConfig(_ config: ConfigFile) async -> ConfigResult {
                let rateLimitedClient = Self.makeRateLimitedClient(
                    for: config,
                    rateLimiter: rateLimiter,
                    baseClient: baseClient,
                    retryPolicy: retryPolicy,
                    onRetryEvent: onRetryEvent
                )
                return await handler(config, rateLimitedClient)
            }

            // Start initial batch up to maxParallel
            while running < maxParallel, let config = configIterator.next() {
                group.addTask {
                    await processConfig(config)
                }
                running += 1
            }

            // Process remaining configs as others complete
            for await result in group {
                results.append(result)
                running -= 1

                // Start next config if available
                if let config = configIterator.next() {
                    group.addTask {
                        await processConfig(config)
                    }
                    running += 1
                }
            }

            return results
        }
    }

    // MARK: - Helpers

    private func createRateLimitedClient(
        for config: ConfigFile,
        rateLimiter: SharedRateLimiter,
        baseClient: Client
    ) -> RateLimitedClient {
        Self.makeRateLimitedClient(
            for: config,
            rateLimiter: rateLimiter,
            baseClient: baseClient,
            retryPolicy: retryPolicy,
            onRetryEvent: onRetryEvent
        )
    }

    private static func makeRateLimitedClient(
        for config: ConfigFile,
        rateLimiter: SharedRateLimiter,
        baseClient: Client,
        retryPolicy: RetryPolicy,
        onRetryEvent: RetryEventHandler?
    ) -> RateLimitedClient {
        let configID = ConfigID(config.name)
        let configName = config.name

        let onRetry: RetryCallback? = if let handler = onRetryEvent {
            { @Sendable attempt, error in
                let delay = retryPolicy.delay(for: attempt - 1, error: error)
                handler(configName, attempt, error, delay)
            }
        } else {
            nil
        }

        return RateLimitedClient(
            client: baseClient,
            rateLimiter: rateLimiter,
            configID: configID,
            retryPolicy: retryPolicy,
            onRetry: onRetry
        )
    }
}

// MARK: - Errors

enum BatchExecutorError: Error, LocalizedError {
    case rateLimiterNotConfigured

    var errorDescription: String? {
        switch self {
        case .rateLimiterNotConfigured:
            "Rate limiter not configured"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .rateLimiterNotConfigured:
            "Use --rate-limit option to configure rate limiting"
        }
    }
}
