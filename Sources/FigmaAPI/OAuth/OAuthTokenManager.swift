import Foundation

// MARK: - Stored Token

/// Persisted OAuth token with expiration tracking.
public struct StoredToken: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let createdAt: Date

    public init(from response: OAuthTokenResponse) {
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        createdAt = Date()
    }

    public init(accessToken: String, refreshToken: String, expiresAt: Date, createdAt: Date = Date()) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    /// Whether the access token has expired (with 5-minute buffer).
    public var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-300) // 5-minute buffer
    }

    /// Whether the token needs refresh (expired or expiring soon).
    public var needsRefresh: Bool {
        isExpired
    }
}

// MARK: - Token Manager Errors

/// Errors that can occur during token management.
public enum TokenManagerError: Error, LocalizedError, Sendable {
    case notAuthenticated
    case storageError(Error)
    case refreshInProgress

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Not authenticated - please sign in"
        case let .storageError(error):
            "Token storage error: \(error.localizedDescription)"
        case .refreshInProgress:
            "Token refresh already in progress"
        }
    }
}

// MARK: - OAuth Token Manager

/// Manages OAuth token storage, retrieval, and automatic refresh.
public actor OAuthTokenManager {
    private let storage: SecureStorage
    private let oauthClient: OAuthClient
    private let storageKey: String

    private var cachedToken: StoredToken?
    private var refreshTask: Task<StoredToken, Error>?

    public init(
        storage: SecureStorage = KeychainStorage(),
        oauthClient: OAuthClient,
        storageKey: String = "figma_oauth_token"
    ) {
        self.storage = storage
        self.oauthClient = oauthClient
        self.storageKey = storageKey
    }

    /// Store a new token from OAuth response.
    public func store(_ response: OAuthTokenResponse) throws {
        let token = StoredToken(from: response)
        try storeToken(token)
        cachedToken = token
    }

    /// Get a valid access token, refreshing if necessary.
    /// - Returns: Valid access token string.
    public func getValidToken() async throws -> String {
        // Try cached token first
        if let cached = cachedToken, !cached.needsRefresh {
            return cached.accessToken
        }

        // Load from storage
        let token = try loadToken()

        // Check if refresh is needed
        if token.needsRefresh {
            let refreshed = try await refreshIfNeeded(token)
            return refreshed.accessToken
        }

        cachedToken = token
        return token.accessToken
    }

    /// Check if user is authenticated (has stored token).
    public func isAuthenticated() -> Bool {
        if cachedToken != nil { return true }
        return storage.exists(forKey: storageKey)
    }

    /// Get the current stored token without refresh.
    public func currentToken() throws -> StoredToken {
        if let cached = cachedToken {
            return cached
        }
        return try loadToken()
    }

    /// Sign out and delete stored tokens.
    public func signOut() throws {
        try storage.delete(forKey: storageKey)
        cachedToken = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Private Methods

    private func loadToken() throws -> StoredToken {
        do {
            let data = try storage.load(forKey: storageKey)
            let token = try JSONDecoder().decode(StoredToken.self, from: data)
            return token
        } catch let error as KeychainError where error == .itemNotFound {
            throw TokenManagerError.notAuthenticated
        } catch {
            throw TokenManagerError.storageError(error)
        }
    }

    private func storeToken(_ token: StoredToken) throws {
        do {
            let data = try JSONEncoder().encode(token)
            try storage.save(data, forKey: storageKey)
        } catch {
            throw TokenManagerError.storageError(error)
        }
    }

    private func refreshIfNeeded(_ token: StoredToken) async throws -> StoredToken {
        // Deduplicate concurrent refresh requests
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<StoredToken, Error> {
            let response = try await oauthClient.refreshToken(token.refreshToken)
            let newToken = StoredToken(from: response)
            try storeToken(newToken)
            cachedToken = newToken
            return newToken
        }

        refreshTask = task

        do {
            let result = try await task.value
            refreshTask = nil
            return result
        } catch {
            refreshTask = nil
            throw error
        }
    }
}

// MARK: - Extension for KeychainError Equatable

extension KeychainError: Equatable {
    public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.itemNotFound, .itemNotFound),
             (.duplicateItem, .duplicateItem),
             (.encodingFailed, .encodingFailed),
             (.decodingFailed, .decodingFailed),
             (.unsupportedPlatform, .unsupportedPlatform):
            true
        case let (.unexpectedStatus(lhsStatus), .unexpectedStatus(rhsStatus)):
            lhsStatus == rhsStatus
        default:
            false
        }
    }
}
