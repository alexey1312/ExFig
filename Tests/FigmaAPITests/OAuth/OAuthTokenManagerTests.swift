import Foundation
import Testing

@testable import FigmaAPI

// MARK: - Mock Storage

final class MockSecureStorage: SecureStorage, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    var saveCallCount = 0
    var loadCallCount = 0
    var deleteCallCount = 0

    func save(_ data: Data, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        saveCallCount += 1
        storage[key] = data
    }

    func load(forKey key: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        loadCallCount += 1
        guard let data = storage[key] else {
            throw KeychainError.itemNotFound
        }
        return data
    }

    func delete(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        deleteCallCount += 1
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] != nil
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
        saveCallCount = 0
        loadCallCount = 0
        deleteCallCount = 0
    }
}

@Suite("Stored Token Tests")
struct StoredTokenTests {
    @Test("init from response sets correct expiration")
    func initFromResponseSetsExpiration() {
        let response = OAuthTokenResponse(
            accessToken: "access",
            refreshToken: "refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        let token = StoredToken(from: response)

        #expect(token.accessToken == "access")
        #expect(token.refreshToken == "refresh")

        // Expiration should be ~1 hour from now
        let expectedExpiration = Date().addingTimeInterval(3600)
        let delta = abs(token.expiresAt.timeIntervalSince(expectedExpiration))
        #expect(delta < 1.0) // Within 1 second
    }

    @Test("isExpired returns false for fresh token")
    func isExpiredReturnsFalseForFreshToken() {
        let token = StoredToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )

        #expect(token.isExpired == false)
    }

    @Test("isExpired returns true for expired token")
    func isExpiredReturnsTrueForExpiredToken() {
        let token = StoredToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-1)
        )

        #expect(token.isExpired == true)
    }

    @Test("isExpired returns true within 5 minute buffer")
    func isExpiredReturnsTrueWithinBuffer() {
        // Token expires in 4 minutes (less than 5 minute buffer)
        let token = StoredToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(240)
        )

        #expect(token.isExpired == true)
    }

    @Test("needsRefresh matches isExpired")
    func needsRefreshMatchesIsExpired() {
        let freshToken = StoredToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(freshToken.needsRefresh == false)

        let expiredToken = StoredToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-1)
        )
        #expect(expiredToken.needsRefresh == true)
    }
}

@Suite("OAuth Token Manager Tests")
struct OAuthTokenManagerTests {
    let testConfig = OAuthConfig(
        clientId: "test-client",
        clientSecret: "test-secret"
    )

    @Test("store saves token to storage")
    func storeSavesToken() async throws {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let response = OAuthTokenResponse(
            accessToken: "test-access",
            refreshToken: "test-refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        try await manager.store(response)

        #expect(mockStorage.saveCallCount == 1)
    }

    @Test("isAuthenticated returns false when not authenticated")
    func isAuthenticatedReturnsFalseWhenNotAuthenticated() async {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let isAuth = await manager.isAuthenticated()
        #expect(isAuth == false)
    }

    @Test("isAuthenticated returns true after storing token")
    func isAuthenticatedReturnsTrueAfterStoring() async throws {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let response = OAuthTokenResponse(
            accessToken: "test-access",
            refreshToken: "test-refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        try await manager.store(response)

        let isAuth = await manager.isAuthenticated()
        #expect(isAuth == true)
    }

    @Test("signOut removes token")
    func signOutRemovesToken() async throws {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let response = OAuthTokenResponse(
            accessToken: "test-access",
            refreshToken: "test-refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        try await manager.store(response)
        try await manager.signOut()

        #expect(mockStorage.deleteCallCount == 1)
        let isAuth = await manager.isAuthenticated()
        #expect(isAuth == false)
    }

    @Test("getValidToken returns stored token when not expired")
    func getValidTokenReturnsStoredToken() async throws {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let response = OAuthTokenResponse(
            accessToken: "valid-access-token",
            refreshToken: "test-refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        try await manager.store(response)

        let token = try await manager.getValidToken()
        #expect(token == "valid-access-token")
    }

    @Test("currentToken returns stored token")
    func currentTokenReturnsStoredToken() async throws {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        let response = OAuthTokenResponse(
            accessToken: "current-access",
            refreshToken: "current-refresh",
            expiresIn: 3600,
            tokenType: "bearer"
        )

        try await manager.store(response)

        let storedToken = try await manager.currentToken()
        #expect(storedToken.accessToken == "current-access")
        #expect(storedToken.refreshToken == "current-refresh")
    }

    @Test("currentToken throws when not authenticated")
    func currentTokenThrowsWhenNotAuthenticated() async {
        let mockStorage = MockSecureStorage()
        let oauthClient = OAuthClient(config: testConfig)
        let manager = OAuthTokenManager(
            storage: mockStorage,
            oauthClient: oauthClient
        )

        do {
            _ = try await manager.currentToken()
            Issue.record("Expected TokenManagerError.notAuthenticated")
        } catch let error as TokenManagerError {
            if case .notAuthenticated = error {
                // Expected
            } else {
                Issue.record("Expected notAuthenticated, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@Suite("Token Manager Error Tests")
struct TokenManagerErrorTests {
    @Test("errors have descriptive messages")
    func errorsHaveDescriptiveMessages() {
        #expect(TokenManagerError.notAuthenticated.errorDescription != nil)
        #expect(TokenManagerError.refreshInProgress.errorDescription != nil)

        let storageError = TokenManagerError.storageError(KeychainError.itemNotFound)
        #expect(storageError.errorDescription != nil)
    }
}
