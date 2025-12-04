import FigmaAPI
import Foundation

/// Type alias for config processing handler.
typealias ConfigHandler = @Sendable (ConfigFile) async -> ConfigResult

/// Type alias for config processing handler with rate-limited client.
typealias RateLimitedConfigHandler = @Sendable (ConfigFile, RateLimitedClient) async -> ConfigResult

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
    /// Cancellation flag.
    private var isCancelled = false

    /// Create a new batch executor.
    /// - Parameters:
    ///   - maxParallel: Maximum concurrent configs (default: 3).
    ///   - failFast: Stop on first error (default: false).
    ///   - rateLimiter: Optional shared rate limiter.
    ///   - baseClient: Optional base client for rate-limited wrapping.
    init(
        maxParallel: Int = 3,
        failFast: Bool = false,
        rateLimiter: SharedRateLimiter? = nil,
        baseClient: Client? = nil
    ) {
        self.maxParallel = max(1, maxParallel)
        self.failFast = failFast
        self.rateLimiter = rateLimiter
        self.baseClient = baseClient
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

            let configID = ConfigID(config.name)
            let rateLimitedClient = RateLimitedClient(
                client: baseClient,
                rateLimiter: rateLimiter,
                configID: configID
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
        await withTaskGroup(of: ConfigResult.self) { [maxParallel] group in
            var results: [ConfigResult] = []
            var running = 0
            var configIterator = configs.makeIterator()

            // Helper to create rate-limited client and process config
            func processConfig(_ config: ConfigFile) async -> ConfigResult {
                let configID = ConfigID(config.name)
                let rateLimitedClient = RateLimitedClient(
                    client: baseClient,
                    rateLimiter: rateLimiter,
                    configID: configID
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
}

// MARK: - Errors

enum BatchExecutorError: Error, LocalizedError {
    case rateLimiterNotConfigured

    var errorDescription: String? {
        switch self {
        case .rateLimiterNotConfigured:
            "Rate limiter not configured for batch execution"
        }
    }
}
