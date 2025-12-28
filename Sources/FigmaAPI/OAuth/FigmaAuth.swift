import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

// MARK: - Figma Authentication

/// Authentication method for Figma API.
public enum FigmaAuth: Sendable {
    /// Personal Access Token (CLI usage).
    case personalToken(String)

    /// OAuth 2.0 with token manager (GUI usage).
    case oauth(OAuthTokenManager)
}

// MARK: - Token Cache Actor

/// Actor for caching OAuth tokens safely in async contexts.
private actor TokenCache {
    private var cachedToken: String?

    func get() -> String? {
        cachedToken
    }

    func set(_ token: String?) {
        cachedToken = token
    }

    func clear() {
        cachedToken = nil
    }
}

// MARK: - OAuth-Aware Figma Client

/// Figma API client that supports both Personal Token and OAuth authentication.
public final class AuthenticatedFigmaClient: Client, @unchecked Sendable {
    // swiftlint:disable:next force_unwrapping
    private static let figmaBaseURL = URL(string: "https://api.figma.com/v1/")!

    private let auth: FigmaAuth
    private let session: URLSession
    private let tokenCache = TokenCache()

    public init(auth: FigmaAuth, timeout: TimeInterval? = nil) {
        self.auth = auth

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout ?? 30
        session = URLSession(configuration: config)
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        // Get current valid token
        let token = try await getCurrentToken()

        // Create authenticated request
        var request = endpoint.makeRequest(baseURL: Self.figmaBaseURL)
        request.setValue(token, forHTTPHeaderField: "X-Figma-Token")

        let (data, response) = try await session.data(for: request)

        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse,
           !(200 ..< 300).contains(httpResponse.statusCode)
        {
            // If 401 and using OAuth, try refreshing token
            if httpResponse.statusCode == 401, case let .oauth(tokenManager) = auth {
                // Clear cached token and retry with fresh token
                await tokenCache.clear()

                let freshToken = try await tokenManager.getValidToken()
                var retryRequest = endpoint.makeRequest(baseURL: Self.figmaBaseURL)
                retryRequest.setValue(freshToken, forHTTPHeaderField: "X-Figma-Token")

                let (retryData, retryResponse) = try await session.data(for: retryRequest)

                if let retryHttpResponse = retryResponse as? HTTPURLResponse,
                   !(200 ..< 300).contains(retryHttpResponse.statusCode)
                {
                    throw HTTPError(
                        statusCode: retryHttpResponse.statusCode,
                        retryAfter: extractRetryAfter(from: retryHttpResponse),
                        body: retryData
                    )
                }

                return try endpoint.content(from: retryResponse, with: retryData)
            }

            throw HTTPError(
                statusCode: httpResponse.statusCode,
                retryAfter: extractRetryAfter(from: httpResponse),
                body: data
            )
        }

        return try endpoint.content(from: response, with: data)
    }

    private func getCurrentToken() async throws -> String {
        switch auth {
        case let .personalToken(token):
            return token
        case let .oauth(tokenManager):
            // Check cache first
            if let cached = await tokenCache.get() {
                return cached
            }

            // Get valid token from manager
            let token = try await tokenManager.getValidToken()
            await tokenCache.set(token)
            return token
        }
    }

    private func extractRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        guard let retryAfterString = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        if let seconds = Double(retryAfterString) {
            return seconds
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: retryAfterString) {
            return date.timeIntervalSinceNow
        }
        return nil
    }
}

// MARK: - Convenience Factory

public extension FigmaAuth {
    /// Create a Figma client with this authentication.
    func makeClient(timeout: TimeInterval? = nil) -> Client {
        switch self {
        case let .personalToken(token):
            FigmaClient(accessToken: token, timeout: timeout)
        case .oauth:
            AuthenticatedFigmaClient(auth: self, timeout: timeout)
        }
    }
}
