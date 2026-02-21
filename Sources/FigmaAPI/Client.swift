import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

public typealias APIResult<Value> = Swift.Result<Value, Error>

public protocol Client: Sendable {
    func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content
}

/// HTTP error with status code and headers for rate limit handling.
public struct HTTPError: Error, Sendable {
    public let statusCode: Int
    public let retryAfter: TimeInterval?
    public let body: Data

    public var localizedDescription: String {
        "HTTP \(statusCode)"
    }
}

public class BaseClient: Client, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let redirectGuard: RedirectGuardDelegate

    public init(baseURL: URL, config: URLSessionConfiguration) {
        self.baseURL = baseURL
        redirectGuard = RedirectGuardDelegate()
        session = URLSession(configuration: config, delegate: redirectGuard, delegateQueue: nil)
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        let request = try endpoint.makeRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)

        // Check for HTTP errors (especially 429 rate limit)
        if let httpResponse = response as? HTTPURLResponse,
           !(200 ..< 300).contains(httpResponse.statusCode)
        {
            let retryAfter = extractRetryAfter(from: httpResponse)
            throw HTTPError(
                statusCode: httpResponse.statusCode,
                retryAfter: retryAfter,
                body: data
            )
        }

        return try endpoint.content(from: response, with: data)
    }

    private func extractRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        guard let retryAfterString = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        // Try parsing as seconds
        if let seconds = Double(retryAfterString) {
            return seconds
        }
        // Try parsing as HTTP date
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: retryAfterString) {
            return date.timeIntervalSinceNow
        }
        return nil
    }
}

// MARK: - Redirect Guard

/// Strips sensitive authentication headers when a redirect changes the target host
/// or downgrades from HTTPS to HTTP.
/// Prevents token leakage if an API response redirects to an external domain.
///
/// Fail-closed: if either host is nil, headers are stripped (safe default).
final class RedirectGuardDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static let sensitiveHeaders = ["X-Figma-Token", "Authorization"]

    func urlSession(
        _: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection _: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        var redirectRequest = request

        let originalHost = task.originalRequest?.url?.host?.lowercased()
        let redirectHost = request.url?.host?.lowercased()
        let originalScheme = task.originalRequest?.url?.scheme?.lowercased()
        let redirectScheme = request.url?.scheme?.lowercased()

        let hostChanged = originalHost != redirectHost
        let schemeDowngraded = originalScheme == "https" && redirectScheme != "https"

        // Fail-closed: nil hosts, changed host, or downgraded scheme → strip sensitive headers
        if originalHost == nil || redirectHost == nil || hostChanged || schemeDowngraded {
            for header in Self.sensitiveHeaders {
                redirectRequest.setValue(nil, forHTTPHeaderField: header)
            }
        }

        completionHandler(redirectRequest)
    }
}
