import Foundation
import Testing

@testable import FigmaAPI

@Suite("Figma Auth Tests")
struct FigmaAuthTests {
    @Test("personalToken creates FigmaClient")
    func personalTokenCreatesFigmaClient() {
        let auth = FigmaAuth.personalToken("test-token")
        let client = auth.makeClient()

        #expect(client is FigmaClient)
    }

    @Test("oauth creates AuthenticatedFigmaClient")
    func oauthCreatesAuthenticatedFigmaClient() async {
        let config = OAuthConfig(
            clientId: "test",
            clientSecret: "test"
        )
        let oauthClient = OAuthClient(config: config)
        let tokenManager = OAuthTokenManager(
            storage: FigmaAuthTestStorage(),
            oauthClient: oauthClient
        )

        let auth = FigmaAuth.oauth(tokenManager)
        let client = auth.makeClient()

        #expect(client is AuthenticatedFigmaClient)
    }

    @Test("makeClient passes timeout to client")
    func makeClientPassesTimeout() {
        let auth = FigmaAuth.personalToken("test-token")
        let client = auth.makeClient(timeout: 60)

        // Client should be created successfully with timeout
        #expect(client is FigmaClient)
    }
}

// Helper for tests (unique name to avoid redeclaration)
private final class FigmaAuthTestStorage: SecureStorage, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func save(_ data: Data, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = data
    }

    func load(forKey key: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        guard let data = storage[key] else {
            throw KeychainError.itemNotFound
        }
        return data
    }

    func delete(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] != nil
    }
}
