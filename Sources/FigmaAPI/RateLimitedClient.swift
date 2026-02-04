import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

/// Callback type for retry events.
public typealias RetryCallback = @Sendable (Int, Error) async -> Void

/// A client wrapper that applies rate limiting and retry logic to all requests.
///
/// This client wraps another `Client` and uses a `SharedRateLimiter`
/// to coordinate request rates across multiple concurrent users.
/// It also implements exponential backoff retry for transient errors.
public final class RateLimitedClient: Client, @unchecked Sendable {
    private let client: Client
    private let rateLimiter: SharedRateLimiter
    private let configID: ConfigID
    private let retryPolicy: RetryPolicy
    private let onRetry: RetryCallback?

    /// Create a rate-limited client with retry support.
    /// - Parameters:
    ///   - client: The underlying client to wrap.
    ///   - rateLimiter: Shared rate limiter for coordination.
    ///   - configID: Identifier for this client's config.
    ///   - retryPolicy: Policy for retry attempts (default: standard policy).
    ///   - onRetry: Optional callback invoked before each retry attempt.
    public init(
        client: Client,
        rateLimiter: SharedRateLimiter,
        configID: ConfigID,
        retryPolicy: RetryPolicy = RetryPolicy(),
        onRetry: RetryCallback? = nil
    ) {
        self.client = client
        self.rateLimiter = rateLimiter
        self.configID = configID
        self.retryPolicy = retryPolicy
        self.onRetry = onRetry
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        var lastError: Error?

        for attempt in 0 ... retryPolicy.maxRetries {
            // Acquire rate limit token before making request
            await rateLimiter.acquire(for: configID)

            do {
                return try await client.request(endpoint)
            } catch {
                lastError = error

                // Handle 429 rate limit specially - always report to rate limiter
                if let httpError = error as? HTTPError, httpError.statusCode == 429 {
                    await rateLimiter.reportRateLimit(retryAfter: httpError.retryAfter)
                }

                // Check if we should retry
                guard retryPolicy.shouldRetry(attempt: attempt, error: error) else {
                    throw convertToFigmaAPIError(error)
                }

                // Calculate delay
                let delay = retryPolicy.delay(for: attempt, error: error)

                // Notify retry callback
                if let onRetry {
                    await onRetry(attempt + 1, error)
                }

                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Clear rate limiter pause if it was a 429
                if let httpError = error as? HTTPError, httpError.statusCode == 429 {
                    await rateLimiter.clearPause()
                }
            }
        }

        // All retries exhausted
        throw convertToFigmaAPIError(
            lastError ?? HTTPError(statusCode: 500, retryAfter: nil, body: Data())
        )
    }

    // MARK: - Private

    private func convertToFigmaAPIError(_ error: Error) -> FigmaAPIError {
        if let httpError = error as? HTTPError {
            return FigmaAPIError.from(httpError)
        }
        if let urlError = error as? URLError {
            return FigmaAPIError.from(urlError)
        }
        // For other errors, preserve the original error message
        return FigmaAPIError(
            statusCode: 0,
            underlyingMessage: error.localizedDescription
        )
    }
}
