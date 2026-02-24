import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Policy for retrying failed HTTP requests with exponential backoff.
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts.
    public let maxRetries: Int

    /// Base delay for exponential backoff (in seconds).
    public let baseDelay: TimeInterval

    /// Maximum delay between retries (in seconds).
    public let maxDelay: TimeInterval

    /// Jitter factor (0.0-1.0) to randomize delays.
    public let jitterFactor: Double

    /// HTTP status codes that are considered retryable.
    private static let retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]

    /// URL error codes that are considered retryable (transient network issues).
    private static let retryableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .networkConnectionLost,
        .notConnectedToInternet,
        .dnsLookupFailed,
        .cannotConnectToHost,
        .cannotFindHost,
        .internationalRoamingOff,
        .dataNotAllowed,
    ]

    /// Create a retry policy with default values.
    /// - Parameters:
    ///   - maxRetries: Maximum retry attempts (default: 4).
    ///   - baseDelay: Base delay in seconds (default: 3.0).
    ///   - maxDelay: Maximum delay in seconds (default: 30.0).
    ///   - jitterFactor: Jitter factor 0.0-1.0 (default: 0.2).
    public init(
        maxRetries: Int = 4,
        baseDelay: TimeInterval = 3.0,
        maxDelay: TimeInterval = 30.0,
        jitterFactor: Double = 0.2
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterFactor = jitterFactor
    }

    /// Calculate delay for a given retry attempt using exponential backoff.
    /// - Parameter attempt: The retry attempt number (0-based).
    /// - Returns: Delay in seconds.
    public func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let capped = min(exponential, maxDelay)
        let jitter = capped * jitterFactor * Double.random(in: -1 ... 1)
        return capped + jitter
    }

    /// Calculate delay for a given retry attempt, optionally using retryAfter from error.
    /// - Parameters:
    ///   - attempt: The retry attempt number (0-based).
    ///   - error: The error that caused the retry (optional).
    /// - Returns: Delay in seconds.
    public func delay(for attempt: Int, error: Error?) -> TimeInterval {
        // For 429 errors, prefer Retry-After header if available
        if let httpError = error as? HTTPError,
           httpError.statusCode == 429,
           let retryAfter = httpError.retryAfter
        {
            return retryAfter
        }
        return delay(for: attempt)
    }

    /// Check if an error is retryable.
    /// - Parameter error: The error to check.
    /// - Returns: True if the error is considered retryable.
    public func isRetryable(_ error: Error) -> Bool {
        if let httpError = error as? HTTPError {
            return Self.retryableStatusCodes.contains(httpError.statusCode)
        }
        if let urlError = error as? URLError {
            return Self.retryableURLErrorCodes.contains(urlError.code)
        }
        return false
    }

    /// Check if a retry should be attempted.
    /// - Parameters:
    ///   - attempt: The current attempt number (0-based).
    ///   - error: The error that occurred.
    /// - Returns: True if a retry should be attempted.
    public func shouldRetry(attempt: Int, error: Error) -> Bool {
        guard attempt < maxRetries else {
            return false
        }
        return isRetryable(error)
    }
}
