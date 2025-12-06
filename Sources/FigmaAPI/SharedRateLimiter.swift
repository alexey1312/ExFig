import Foundation

/// Identifier for a config in batch processing.
public struct ConfigID: Hashable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }
}

/// Shared rate limiter for coordinating API requests across multiple configs.
///
/// Uses a token bucket algorithm with fair round-robin queuing to ensure
/// all configs get equal access to the rate limit budget.
///
/// Figma API rate limits (per token):
/// - Tier 1: 10-20 req/min (Starter→Enterprise)
/// - Tier 2: 25-100 req/min
/// - Tier 3: 50-150 req/min
///
/// See: https://developers.figma.com/docs/rest-api/rate-limits/
public actor SharedRateLimiter {
    // MARK: - Configuration

    /// Default rate limit: 10 requests per minute (conservative Tier 1 for Starter plans)
    public static let defaultRequestsPerMinute: Double = 10.0

    /// Minimum time between requests in seconds.
    private let minInterval: TimeInterval

    /// Maximum tokens in bucket (burst capacity).
    private let maxTokens: Double

    // MARK: - State

    /// Current available tokens.
    private var tokens: Double

    /// Last time tokens were replenished.
    private var lastRefillTime: Date

    /// Pending requests queue for fair scheduling.
    private var pendingRequests: [ConfigID] = []

    /// Per-config request tracking for fairness.
    private var requestCounts: [ConfigID: Int] = [:]

    /// Whether a global pause is in effect (429 received).
    private var pauseUntil: Date?

    /// Current retry-after value if rate limited.
    private var currentRetryAfter: TimeInterval?

    // MARK: - Initialization

    /// Create a new rate limiter.
    /// - Parameters:
    ///   - requestsPerMinute: Maximum requests per minute (default: 10).
    ///   - burstCapacity: Maximum burst tokens (default: 3).
    public init(requestsPerMinute: Double = defaultRequestsPerMinute, burstCapacity: Double = 3.0) {
        minInterval = 60.0 / requestsPerMinute
        maxTokens = burstCapacity
        tokens = burstCapacity
        lastRefillTime = Date()
    }

    // MARK: - Public API

    /// Acquire permission to make a request.
    ///
    /// This method blocks until a token is available and it's the caller's turn
    /// in the fair queue.
    ///
    /// - Parameter configID: Identifier for the requesting config.
    public func acquire(for configID: ConfigID) async {
        // Wait if globally paused (429 response)
        if let pauseTime = pauseUntil, Date() < pauseTime {
            let delay = pauseTime.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Add to fair queue
        pendingRequests.append(configID)

        // Wait for our turn (fair round-robin)
        while !canProceed(configID) {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms polling
        }

        // Wait for token availability
        await waitForToken()

        // Dequeue and track
        if let index = pendingRequests.firstIndex(of: configID) {
            pendingRequests.remove(at: index)
        }
        requestCounts[configID, default: 0] += 1
    }

    /// Report a rate limit error (429 response).
    ///
    /// - Parameter retryAfter: Retry-After value from response header.
    public func reportRateLimit(retryAfter: TimeInterval?) {
        let pauseDuration = retryAfter ?? 60.0 // Default 60s if no header
        pauseUntil = Date().addingTimeInterval(pauseDuration)
        currentRetryAfter = pauseDuration
        // Drain tokens on rate limit
        tokens = 0
    }

    /// Clear any global pause.
    public func clearPause() {
        pauseUntil = nil
        currentRetryAfter = nil
    }

    /// Get current rate limiter status.
    /// - Returns: Status snapshot.
    public func status() -> RateLimiterStatus {
        refillTokens()
        return RateLimiterStatus(
            availableTokens: tokens,
            maxTokens: maxTokens,
            requestsPerMinute: 60.0 / minInterval,
            isPaused: pauseUntil != nil && Date() < (pauseUntil ?? .distantPast),
            retryAfter: currentRetryAfter,
            pendingRequestCount: pendingRequests.count,
            configRequestCounts: requestCounts
        )
    }

    /// Reset statistics for a config (when batch starts).
    /// - Parameter configID: Config to reset.
    public func resetStats(for configID: ConfigID) {
        requestCounts[configID] = nil
    }

    /// Reset all statistics.
    public func resetAllStats() {
        requestCounts.removeAll()
        pendingRequests.removeAll()
        pauseUntil = nil
        currentRetryAfter = nil
    }

    // MARK: - Private Methods

    /// Check if a config can proceed (fair scheduling).
    private func canProceed(_ configID: ConfigID) -> Bool {
        guard let firstInQueue = pendingRequests.first else {
            return false
        }

        // Direct match - it's our turn
        if firstInQueue == configID {
            return true
        }

        // Fair round-robin: if we have fewer requests than others, we can proceed
        let ourCount = requestCounts[configID, default: 0]
        let minCount = requestCounts.values.min() ?? 0

        // Allow if we're at or below the minimum count and first in our "tier"
        if ourCount <= minCount {
            // Find first request at our count level
            for pending in pendingRequests {
                let pendingCount = requestCounts[pending, default: 0]
                if pendingCount <= minCount {
                    return pending == configID
                }
            }
        }

        return false
    }

    /// Wait until a token is available.
    private func waitForToken() async {
        while true {
            refillTokens()

            if tokens >= 1.0 {
                tokens -= 1.0
                return
            }

            // Calculate wait time for next token
            let tokensNeeded = 1.0 - tokens
            let waitTime = tokensNeeded * minInterval
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }

    /// Refill tokens based on elapsed time.
    private func refillTokens() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefillTime)
        let tokensToAdd = elapsed / minInterval

        tokens = min(maxTokens, tokens + tokensToAdd)
        lastRefillTime = now
    }
}

// MARK: - Status Model

/// Snapshot of rate limiter status.
public struct RateLimiterStatus: Sendable {
    /// Currently available tokens.
    public let availableTokens: Double

    /// Maximum token capacity.
    public let maxTokens: Double

    /// Configured requests per minute.
    public let requestsPerMinute: Double

    /// Whether requests are paused due to 429.
    public let isPaused: Bool

    /// Current retry-after value if paused.
    public let retryAfter: TimeInterval?

    /// Number of pending requests in queue.
    public let pendingRequestCount: Int

    /// Per-config request counts.
    public let configRequestCounts: [ConfigID: Int]

    /// Current effective request rate (requests/second).
    public var currentRate: Double {
        requestsPerMinute / 60.0
    }

    /// Human-readable status.
    public var description: String {
        if isPaused {
            let retryStr = retryAfter.map { String(format: "%.0fs", $0) } ?? "unknown"
            return "Paused (retry after \(retryStr))"
        }
        return String(format: "%.1f/%.1f tokens, %.1f req/min", availableTokens, maxTokens, requestsPerMinute)
    }
}
