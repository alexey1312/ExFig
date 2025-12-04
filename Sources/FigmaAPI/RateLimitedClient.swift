import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

/// A client wrapper that applies rate limiting to all requests.
///
/// This client wraps another `Client` and uses a `SharedRateLimiter`
/// to coordinate request rates across multiple concurrent users.
public final class RateLimitedClient: Client, @unchecked Sendable {
    private let client: Client
    private let rateLimiter: SharedRateLimiter
    private let configID: ConfigID

    /// Create a rate-limited client.
    /// - Parameters:
    ///   - client: The underlying client to wrap.
    ///   - rateLimiter: Shared rate limiter for coordination.
    ///   - configID: Identifier for this client's config.
    public init(client: Client, rateLimiter: SharedRateLimiter, configID: ConfigID) {
        self.client = client
        self.rateLimiter = rateLimiter
        self.configID = configID
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        // Acquire rate limit token before making request
        await rateLimiter.acquire(for: configID)

        do {
            return try await client.request(endpoint)
        } catch let error as HTTPError where error.statusCode == 429 {
            // Rate limit hit - report and retry
            await rateLimiter.reportRateLimit(retryAfter: error.retryAfter)

            // Wait and retry once
            let retryAfter = error.retryAfter ?? 60.0
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            await rateLimiter.clearPause()

            // Acquire again and retry
            await rateLimiter.acquire(for: configID)
            return try await client.request(endpoint)
        }
    }
}
