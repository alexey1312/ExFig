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

    public init(baseURL: URL, config: URLSessionConfiguration) {
        self.baseURL = baseURL
        session = URLSession(configuration: config)
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        let request = endpoint.makeRequest(baseURL: baseURL)
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
