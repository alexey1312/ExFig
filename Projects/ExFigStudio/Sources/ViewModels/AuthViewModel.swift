import AppKit
import FigmaAPI
import Foundation
import SwiftUI

// MARK: - Authentication Method

/// Available authentication methods for Figma API.
enum AuthMethod: String, CaseIterable, Identifiable {
    case oauth = "OAuth (Recommended)"
    case personalToken = "Personal Access Token"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .oauth:
            "Sign in with your Figma account using OAuth. More secure and convenient."
        case .personalToken:
            "Use a Personal Access Token from Figma settings. Required for API access without OAuth."
        }
    }
}

// MARK: - Auth State

/// Authentication state for the app.
enum AuthState: Equatable {
    case notAuthenticated
    case authenticating
    case authenticated(email: String?)
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.authenticating, .authenticating):
            true
        case let (.authenticated(lhs), .authenticated(rhs)):
            lhs == rhs
        case let (.error(lhs), .error(rhs)):
            lhs == rhs
        default:
            false
        }
    }
}

// MARK: - Auth View Model

/// View model for authentication UI.
@MainActor
@Observable
final class AuthViewModel {
    // MARK: - State

    var selectedMethod: AuthMethod = .oauth
    var personalToken: String = ""
    var authState: AuthState = .notAuthenticated
    var isValidatingToken: Bool = false

    // OAuth specific
    private var oauthClient: OAuthClient?
    private var tokenManager: OAuthTokenManager?
    private var pendingState: String?

    // Personal token storage
    private let tokenStorage: SecureStorage

    // MARK: - Configuration

    /// OAuth client ID from Figma Developer settings.
    /// Users need to register their own app at https://www.figma.com/developers/apps
    private let oauthClientId: String
    private let oauthClientSecret: String

    // MARK: - Callbacks

    var onAuthenticationComplete: ((FigmaAuth) -> Void)?

    // MARK: - Init

    init(
        tokenStorage: SecureStorage = KeychainStorage(),
        oauthClientId: String = "",
        oauthClientSecret: String = ""
    ) {
        self.tokenStorage = tokenStorage
        self.oauthClientId = oauthClientId
        self.oauthClientSecret = oauthClientSecret
    }

    // MARK: - Personal Token Auth

    /// Validate and store the personal access token.
    func authenticateWithPersonalToken() async {
        guard !personalToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authState = .error("Please enter a valid token")
            return
        }

        isValidatingToken = true
        authState = .authenticating

        do {
            // Validate token by making a test API call
            let trimmedToken = personalToken.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = try await validateToken(trimmedToken)

            if isValid {
                // Store token securely
                try tokenStorage.save(Data(trimmedToken.utf8), forKey: "figma_personal_token")
                authState = .authenticated(email: nil)
                onAuthenticationComplete?(.personalToken(trimmedToken))
            } else {
                authState = .error("Invalid token - please check and try again")
            }
        } catch {
            authState = .error("Failed to validate token: \(error.localizedDescription)")
        }

        isValidatingToken = false
    }

    /// Validate a personal access token by making a test API call.
    private func validateToken(_ token: String) async throws -> Bool {
        // Create a simple GET request to /v1/me endpoint
        guard let url = URL(string: "https://api.figma.com/v1/me") else {
            return false
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    // MARK: - OAuth Auth

    /// Start the OAuth authentication flow.
    func startOAuthFlow() async {
        guard !oauthClientId.isEmpty, !oauthClientSecret.isEmpty else {
            authState = .error("OAuth not configured. Please use Personal Access Token instead.")
            return
        }

        authState = .authenticating

        let config = OAuthConfig(
            clientId: oauthClientId,
            clientSecret: oauthClientSecret,
            scopes: [.filesRead]
        )

        let client = OAuthClient(config: config)
        let manager = OAuthTokenManager(oauthClient: client)

        oauthClient = client
        tokenManager = manager

        do {
            let (url, state) = try await client.authorizationURL()
            pendingState = state

            // Open browser for authentication
            NSWorkspace.shared.open(url)
        } catch {
            authState = .error("Failed to start OAuth: \(error.localizedDescription)")
        }
    }

    /// Handle OAuth callback URL.
    func handleOAuthCallback(_ url: URL) async {
        guard let client = oauthClient, let manager = tokenManager else {
            authState = .error("OAuth client not initialized")
            return
        }

        do {
            let tokenResponse = try await client.handleCallback(url)
            try await manager.store(tokenResponse)

            authState = .authenticated(email: nil)
            onAuthenticationComplete?(.oauth(manager))
        } catch {
            authState = .error("OAuth failed: \(error.localizedDescription)")
        }

        // Clear pending state
        pendingState = nil
    }

    /// Cancel OAuth flow.
    func cancelOAuth() async {
        await oauthClient?.cancel()
        pendingState = nil
        authState = .notAuthenticated
    }

    // MARK: - Existing Auth Check

    /// Check if user is already authenticated.
    func checkExistingAuth() async {
        // Check for personal token first
        if tokenStorage.exists(forKey: "figma_personal_token") {
            do {
                let tokenData = try tokenStorage.load(forKey: "figma_personal_token")
                if let token = String(data: tokenData, encoding: .utf8) {
                    authState = .authenticated(email: nil)
                    onAuthenticationComplete?(.personalToken(token))
                    return
                }
            } catch {
                // Token not found or invalid, continue to check OAuth
            }
        }

        // Check for OAuth token
        if let manager = tokenManager, await manager.isAuthenticated() {
            authState = .authenticated(email: nil)
            onAuthenticationComplete?(.oauth(manager))
            return
        }

        authState = .notAuthenticated
    }

    // MARK: - Sign Out

    /// Sign out and clear stored credentials.
    func signOut() async {
        do {
            try tokenStorage.delete(forKey: "figma_personal_token")
        } catch {
            // Ignore errors when deleting
        }

        do {
            try await tokenManager?.signOut()
        } catch {
            // Ignore errors when signing out
        }

        authState = .notAuthenticated
        personalToken = ""
    }
}
