import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// User-friendly error for Figma API failures.
public struct FigmaAPIError: LocalizedError, Sendable {
    /// HTTP status code (or 0 for network errors).
    public let statusCode: Int

    /// Retry-After value from response headers.
    public let retryAfter: TimeInterval?

    /// Current retry attempt (1-based, nil if not retrying).
    public let attempt: Int?

    /// Maximum retry attempts.
    public let maxAttempts: Int?

    /// Underlying URL error (for network failures).
    public let urlErrorCode: URLError.Code?

    /// Underlying error message for unclassified errors.
    public let underlyingMessage: String?

    /// Create a Figma API error.
    /// - Parameters:
    ///   - statusCode: HTTP status code.
    ///   - retryAfter: Retry-After header value.
    ///   - attempt: Current retry attempt (1-based).
    ///   - maxAttempts: Maximum retry attempts.
    ///   - urlErrorCode: Underlying URL error code.
    ///   - underlyingMessage: Message from the original error (for unclassified errors).
    public init(
        statusCode: Int,
        retryAfter: TimeInterval? = nil,
        attempt: Int? = nil,
        maxAttempts: Int? = nil,
        urlErrorCode: URLError.Code? = nil,
        underlyingMessage: String? = nil
    ) {
        self.statusCode = statusCode
        self.retryAfter = retryAfter
        self.attempt = attempt
        self.maxAttempts = maxAttempts
        self.urlErrorCode = urlErrorCode
        self.underlyingMessage = underlyingMessage
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        // Handle network errors first
        if let urlCode = urlErrorCode {
            return networkErrorDescription(for: urlCode)
        }

        // Handle HTTP errors
        switch statusCode {
        case 401:
            return "Authentication failed. Check FIGMA_PERSONAL_TOKEN environment variable."
        case 403:
            return "Access denied. Verify you have access to this Figma file."
        case 404:
            return "File not found. Check the file ID in your configuration."
        case 429:
            let wait = retryAfter.map { String(format: "%.0f", $0) } ?? "60"
            return "Rate limited by Figma API. Waiting \(wait)s..."
        case 500 ... 504:
            return "Figma server error (\(statusCode)). This is usually temporary."
        case 0:
            // Unclassified error (not HTTP, not URLError)
            if let msg = underlyingMessage {
                return "Figma API error: \(msg)"
            }
            return "Unknown network error (no HTTP response received)"
        default:
            return "Figma API error: HTTP \(statusCode)"
        }
    }

    public var recoverySuggestion: String? {
        switch statusCode {
        case 401:
            "Run: export FIGMA_PERSONAL_TOKEN=your_token"
        case 403:
            "Ensure you have view access to the Figma file"
        case 404:
            "Double-check the file ID in your config file"
        case 429:
            "Try again later or reduce batch size with --rate-limit"
        case 500 ... 504:
            "Check https://status.figma.com or retry in a few minutes"
        default:
            nil
        }
    }

    /// Message for retry attempts (e.g., "Retrying in 2s... (attempt 2/4)").
    public var retryMessage: String? {
        guard let attempt, let maxAttempts else {
            return nil
        }
        if let delay = retryAfter {
            return "Retrying in \(Int(delay))s... (attempt \(attempt)/\(maxAttempts))"
        }
        return "Retrying... (attempt \(attempt)/\(maxAttempts))"
    }

    // MARK: - Factory Methods

    /// Create FigmaAPIError from HTTPError.
    /// - Parameters:
    ///   - httpError: The HTTP error to convert.
    ///   - attempt: Current retry attempt (1-based).
    ///   - maxAttempts: Maximum retry attempts.
    /// - Returns: A user-friendly FigmaAPIError.
    public static func from(
        _ httpError: HTTPError,
        attempt: Int? = nil,
        maxAttempts: Int? = nil
    ) -> FigmaAPIError {
        FigmaAPIError(
            statusCode: httpError.statusCode,
            retryAfter: httpError.retryAfter,
            attempt: attempt,
            maxAttempts: maxAttempts
        )
    }

    /// Create FigmaAPIError from URLError.
    /// - Parameters:
    ///   - urlError: The URL error to convert.
    ///   - attempt: Current retry attempt (1-based).
    ///   - maxAttempts: Maximum retry attempts.
    /// - Returns: A user-friendly FigmaAPIError.
    public static func from(
        _ urlError: URLError,
        attempt: Int? = nil,
        maxAttempts: Int? = nil
    ) -> FigmaAPIError {
        FigmaAPIError(
            statusCode: 0,
            retryAfter: nil,
            attempt: attempt,
            maxAttempts: maxAttempts,
            urlErrorCode: urlError.code
        )
    }

    // MARK: - Private

    private func networkErrorDescription(for code: URLError.Code) -> String {
        switch code {
        case .timedOut:
            "Request timeout. The Figma server took too long to respond."
        case .networkConnectionLost:
            "Network connection lost. Check your internet connection."
        case .notConnectedToInternet:
            "Not connected to internet. Please check your connection."
        case .dnsLookupFailed:
            "DNS lookup failed. Unable to resolve api.figma.com."
        case .cannotConnectToHost:
            "Cannot connect to Figma. The server may be down."
        case .cannotFindHost:
            "Cannot find Figma server. Check your network settings."
        default:
            "Network error: \(code.rawValue)"
        }
    }
}
