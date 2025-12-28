import FigmaAPI
import Foundation
import Testing

@testable import ExFigStudio

@Suite("AuthViewModel Tests")
@MainActor
struct AuthViewModelTests {
    // MARK: - Mock Storage

    final class MockSecureStorage: SecureStorage, @unchecked Sendable {
        var storedData: [String: Data] = [:]

        func save(_ data: Data, forKey key: String) throws {
            storedData[key] = data
        }

        func load(forKey key: String) throws -> Data {
            guard let data = storedData[key] else {
                throw KeychainError.itemNotFound
            }
            return data
        }

        func delete(forKey key: String) throws {
            storedData.removeValue(forKey: key)
        }

        func exists(forKey key: String) -> Bool {
            storedData[key] != nil
        }
    }

    // MARK: - Initialization Tests

    @Test("Initial state is not authenticated")
    func initialState() {
        let viewModel = AuthViewModel(tokenStorage: MockSecureStorage())

        #expect(viewModel.authState == .notAuthenticated)
        #expect(viewModel.selectedMethod == .oauth)
        #expect(viewModel.personalToken.isEmpty)
        #expect(!viewModel.isValidatingToken)
    }

    // MARK: - Personal Token Validation Tests

    @Test("Empty token shows error")
    func emptyToken() async {
        let viewModel = AuthViewModel(tokenStorage: MockSecureStorage())
        viewModel.personalToken = ""

        await viewModel.authenticateWithPersonalToken()

        #expect(viewModel.authState == .error("Please enter a valid token"))
    }

    @Test("Whitespace-only token shows error")
    func whitespaceToken() async {
        let viewModel = AuthViewModel(tokenStorage: MockSecureStorage())
        viewModel.personalToken = "   "

        await viewModel.authenticateWithPersonalToken()

        #expect(viewModel.authState == .error("Please enter a valid token"))
    }

    // MARK: - Sign Out Tests

    @Test("Sign out clears state")
    func signOut() async {
        let storage = MockSecureStorage()
        let viewModel = AuthViewModel(tokenStorage: storage)

        // Simulate stored token
        try? storage.save(Data("test-token".utf8), forKey: "figma_personal_token")
        viewModel.personalToken = "test-token"

        await viewModel.signOut()

        #expect(viewModel.authState == .notAuthenticated)
        #expect(viewModel.personalToken.isEmpty)
        #expect(!storage.exists(forKey: "figma_personal_token"))
    }

    // MARK: - OAuth Configuration Tests

    @Test("OAuth without client ID shows error")
    func oauthWithoutClientId() async {
        let viewModel = AuthViewModel(
            tokenStorage: MockSecureStorage(),
            oauthClientId: "",
            oauthClientSecret: ""
        )

        await viewModel.startOAuthFlow()

        if case let .error(message) = viewModel.authState {
            #expect(message.contains("OAuth not configured"))
        } else {
            Issue.record("Expected error state for unconfigured OAuth")
        }
    }

    // MARK: - Existing Auth Check Tests

    @Test("Check existing auth finds stored personal token")
    func checkExistingPersonalToken() async {
        let storage = MockSecureStorage()
        try? storage.save(Data("existing-token".utf8), forKey: "figma_personal_token")

        let viewModel = AuthViewModel(tokenStorage: storage)
        var receivedAuth = false
        viewModel.onAuthenticationComplete = { _ in
            receivedAuth = true
        }

        await viewModel.checkExistingAuth()

        if case .authenticated = viewModel.authState {
            #expect(receivedAuth)
        } else {
            Issue.record("Expected authenticated state when token exists")
        }
    }

    @Test("Check existing auth with no stored token stays unauthenticated")
    func checkExistingNoToken() async {
        let storage = MockSecureStorage()
        let viewModel = AuthViewModel(tokenStorage: storage)

        await viewModel.checkExistingAuth()

        #expect(viewModel.authState == .notAuthenticated)
    }
}

// MARK: - AuthMethod Tests

@Suite("AuthMethod Tests")
struct AuthMethodTests {
    @Test("OAuth is recommended")
    func oauthIsRecommended() {
        #expect(AuthMethod.oauth.rawValue.contains("Recommended"))
    }

    @Test("All cases have descriptions")
    func allCasesHaveDescriptions() {
        for method in AuthMethod.allCases {
            #expect(!method.description.isEmpty)
        }
    }
}

// MARK: - AuthState Tests

@Suite("AuthState Tests")
struct AuthStateTests {
    @Test("AuthState equality works correctly")
    func equalityWorks() {
        #expect(AuthState.notAuthenticated == AuthState.notAuthenticated)
        #expect(AuthState.authenticating == AuthState.authenticating)
        #expect(AuthState.authenticated(email: "test@example.com") == AuthState
            .authenticated(email: "test@example.com"))
        #expect(AuthState.authenticated(email: nil) == AuthState.authenticated(email: nil))
        #expect(AuthState.error("Error 1") == AuthState.error("Error 1"))

        #expect(AuthState.notAuthenticated != AuthState.authenticating)
        #expect(AuthState.authenticated(email: "a") != AuthState.authenticated(email: "b"))
        #expect(AuthState.error("Error 1") != AuthState.error("Error 2"))
    }
}
