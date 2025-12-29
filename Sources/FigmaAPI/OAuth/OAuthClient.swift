import Crypto
import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

// MARK: - OAuth Configuration

/// Configuration for Figma OAuth authentication.
public struct OAuthConfig: Sendable {
    public let clientId: String
    public let clientSecret: String
    public let redirectURI: String
    public let scopes: [OAuthScope]

    public init(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "exfig://oauth/callback",
        scopes: [OAuthScope] = [.filesRead]
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}

/// Available Figma OAuth scopes.
public enum OAuthScope: String, Sendable, CaseIterable {
    case filesRead = "files:read"
    case fileCommentsWrite = "file_comments:write"
    case libraryAnalyticsRead = "library_analytics:read"
    case webhooksWrite = "webhooks:write"
    case currentUserRead = "current_user:read"

    /// OpenID Connect scopes
    case openid
    case email
    case profile
}

// MARK: - OAuth Errors

/// Errors that can occur during OAuth authentication.
public enum OAuthError: Error, LocalizedError, Sendable, Equatable {
    case invalidAuthorizationURL
    case missingAuthorizationCode
    case stateMismatch
    case tokenRequestFailed(statusCode: Int, body: String)
    case invalidTokenResponse
    case refreshFailed(reason: String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidAuthorizationURL:
            "Failed to construct authorization URL"
        case .missingAuthorizationCode:
            "Authorization code missing from callback"
        case .stateMismatch:
            "State parameter mismatch - possible CSRF attack"
        case let .tokenRequestFailed(statusCode, body):
            "Token request failed with status \(statusCode): \(body)"
        case .invalidTokenResponse:
            "Invalid token response from Figma"
        case let .refreshFailed(reason):
            "Token refresh failed: \(reason)"
        case .cancelled:
            "OAuth flow was cancelled"
        }
    }
}

// MARK: - OAuth Token Response

/// Token response from Figma OAuth token endpoint.
public struct OAuthTokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - PKCE Support

/// PKCE (Proof Key for Code Exchange) helper for OAuth 2.0.
public struct PKCEChallenge: Sendable {
    public let verifier: String
    public let challenge: String
    public let method: String

    /// Generate a new PKCE challenge using S256 method.
    public static func generate() -> PKCEChallenge {
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        return PKCEChallenge(verifier: verifier, challenge: challenge, method: "S256")
    }

    private static func generateCodeVerifier() -> String {
        // Use SymmetricKey from swift-crypto which provides cryptographically secure random bytes
        // on all platforms (macOS, iOS, Linux) without fallback to insecure alternatives
        let key = SymmetricKey(size: .bits256) // 256 bits = 32 bytes
        let bytes = key.withUnsafeBytes { Data($0) }
        return base64URLEncode(bytes)
    }

    private static func generateCodeChallenge(from verifier: String) -> String {
        // Use Swift Crypto for cross-platform SHA-256 (works on macOS and Linux)
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return base64URLEncode(Data(digest))
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - OAuth Client

/// Client for Figma OAuth 2.0 authentication with PKCE support.
public actor OAuthClient {
    private let config: OAuthConfig
    private let session: URLSession
    private var pendingPKCE: PKCEChallenge?
    private var pendingState: String?

    private static let authorizationURL = "https://www.figma.com/oauth"
    private static let tokenURL = "https://api.figma.com/v1/oauth/token"

    public init(config: OAuthConfig) {
        self.config = config
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 30
        session = URLSession(configuration: sessionConfig)
    }

    /// Generate the authorization URL for starting OAuth flow.
    /// - Returns: URL to open in browser and the state parameter for validation.
    public func authorizationURL() throws -> (url: URL, state: String) {
        let pkce = PKCEChallenge.generate()
        let state = UUID().uuidString

        pendingPKCE = pkce
        pendingState = state

        var components = URLComponents(string: Self.authorizationURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "scope", value: config.scopes.map(\.rawValue).joined(separator: " ")),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.method),
        ]

        guard let url = components?.url else {
            throw OAuthError.invalidAuthorizationURL
        }

        return (url, state)
    }

    /// Handle the OAuth callback and exchange code for tokens.
    /// - Parameters:
    ///   - callbackURL: The callback URL received from Figma.
    /// - Returns: Token response containing access and refresh tokens.
    public func handleCallback(_ callbackURL: URL) async throws -> OAuthTokenResponse {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else {
            throw OAuthError.missingAuthorizationCode
        }

        // Extract code and state from callback
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingAuthorizationCode
        }

        // Validate state parameter (CSRF protection)
        let state = queryItems.first(where: { $0.name == "state" })?.value
        if let pendingState {
            // If we have a pending state, callback must include matching state
            guard let state, state == pendingState else {
                throw OAuthError.stateMismatch
            }
        }

        guard let pkce = pendingPKCE else {
            throw OAuthError.missingAuthorizationCode
        }

        // Clear pending state
        defer {
            pendingPKCE = nil
            pendingState = nil
        }

        return try await exchangeCodeForToken(code: code, codeVerifier: pkce.verifier)
    }

    /// Exchange authorization code for access and refresh tokens.
    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws -> OAuthTokenResponse {
        guard let url = URL(string: Self.tokenURL) else {
            throw OAuthError.invalidAuthorizationURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Use strict URL encoding for form data (avoid parameter injection)
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "-._~:/")
        let encodedRedirectURI = config.redirectURI
            .addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? config.redirectURI
        let body = [
            "grant_type=authorization_code",
            "client_id=\(config.clientId)",
            "client_secret=\(config.clientSecret)",
            "code=\(code)",
            "redirect_uri=\(encodedRedirectURI)",
            "code_verifier=\(codeVerifier)",
        ].joined(separator: "&")

        request.httpBody = Data(body.utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidTokenResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OAuthError.tokenRequestFailed(statusCode: httpResponse.statusCode, body: body)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(OAuthTokenResponse.self, from: data)
    }

    /// Refresh an expired access token.
    /// - Parameter refreshToken: The refresh token from previous authentication.
    /// - Returns: New token response with fresh access and refresh tokens.
    public func refreshToken(_ refreshToken: String) async throws -> OAuthTokenResponse {
        guard let url = URL(string: Self.tokenURL) else {
            throw OAuthError.invalidAuthorizationURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=refresh_token",
            "client_id=\(config.clientId)",
            "client_secret=\(config.clientSecret)",
            "refresh_token=\(refreshToken)",
        ].joined(separator: "&")

        request.httpBody = Data(body.utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidTokenResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OAuthError.refreshFailed(reason: "HTTP \(httpResponse.statusCode): \(body)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(OAuthTokenResponse.self, from: data)
    }

    /// Cancel any pending OAuth flow.
    public func cancel() {
        pendingPKCE = nil
        pendingState = nil
    }
}
