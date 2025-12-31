import Foundation
import Testing

@testable import FigmaAPI

@Suite("OAuth Client Tests")
struct OAuthClientTests {
    let testConfig = OAuthConfig(
        clientId: "test-client-id",
        clientSecret: "test-client-secret",
        redirectURI: "exfig://oauth/callback",
        scopes: [.fileContentRead]
    )

    @Test("authorizationURL generates valid URL with required parameters")
    func authorizationURLGeneratesValidURL() async throws {
        let client = OAuthClient(config: testConfig)
        let (url, state) = try await client.authorizationURL()

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        #expect(components?.host == "www.figma.com")
        #expect(components?.path == "/oauth")

        let queryItems = components?.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        #expect(queryDict["client_id"] == "test-client-id")
        #expect(queryDict["redirect_uri"] == "exfig://oauth/callback")
        #expect(queryDict["scope"] == "file_content:read")
        #expect(queryDict["response_type"] == "code")
        #expect(queryDict["state"] == state)
        #expect(queryDict["code_challenge"] != nil)
        #expect(queryDict["code_challenge_method"] == "S256")
    }

    @Test("authorizationURL generates unique state for each call")
    func authorizationURLGeneratesUniqueState() async throws {
        let client = OAuthClient(config: testConfig)
        let (_, state1) = try await client.authorizationURL()
        let (_, state2) = try await client.authorizationURL()

        #expect(state1 != state2)
    }

    @Test("handleCallback throws on missing code")
    func handleCallbackThrowsOnMissingCode() async throws {
        let client = OAuthClient(config: testConfig)
        _ = try await client.authorizationURL()

        let callbackURL = URL(string: "exfig://oauth/callback?state=test-state")!

        await #expect(throws: OAuthError.missingAuthorizationCode) {
            try await client.handleCallback(callbackURL)
        }
    }

    @Test("handleCallback throws on state mismatch")
    func handleCallbackThrowsOnStateMismatch() async throws {
        let client = OAuthClient(config: testConfig)
        _ = try await client.authorizationURL()

        let callbackURL = URL(string: "exfig://oauth/callback?code=test-code&state=wrong-state")!

        await #expect(throws: OAuthError.stateMismatch) {
            try await client.handleCallback(callbackURL)
        }
    }

    @Test("cancel clears pending state")
    func cancelClearsPendingState() async throws {
        let client = OAuthClient(config: testConfig)
        _ = try await client.authorizationURL()

        await client.cancel()

        // After cancel, handling callback should fail with missing code
        // (since no pending PKCE challenge exists)
        let callbackURL = URL(string: "exfig://oauth/callback?code=test-code")!

        await #expect(throws: OAuthError.missingAuthorizationCode) {
            try await client.handleCallback(callbackURL)
        }
    }

    @Test("multiple scopes are joined with space")
    func multipleScopesJoinedWithSpace() async throws {
        let configWithScopes = OAuthConfig(
            clientId: "test",
            clientSecret: "test",
            scopes: [.fileContentRead, .fileCommentsWrite, .openid]
        )
        let client = OAuthClient(config: configWithScopes)
        let (url, _) = try await client.authorizationURL()

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scope = components?.queryItems?.first { $0.name == "scope" }?.value

        #expect(scope == "file_content:read file_comments:write openid")
    }
}

@Suite("OAuth Config Tests")
struct OAuthConfigTests {
    @Test("default redirectURI is exfig://oauth/callback")
    func defaultRedirectURI() {
        let config = OAuthConfig(
            clientId: "test",
            clientSecret: "test"
        )

        #expect(config.redirectURI == "exfig://oauth/callback")
    }

    @Test("default scopes contain fileContentRead")
    func defaultScopes() {
        let config = OAuthConfig(
            clientId: "test",
            clientSecret: "test"
        )

        #expect(config.scopes == [.fileContentRead])
    }
}

@Suite("OAuth Scope Tests")
struct OAuthScopeTests {
    @Test("scope raw values match Figma API")
    func scopeRawValues() {
        #expect(OAuthScope.fileContentRead.rawValue == "file_content:read")
        #expect(OAuthScope.fileCommentsWrite.rawValue == "file_comments:write")
        #expect(OAuthScope.libraryAnalyticsRead.rawValue == "library_analytics:read")
        #expect(OAuthScope.webhooksWrite.rawValue == "webhooks:write")
        #expect(OAuthScope.openid.rawValue == "openid")
        #expect(OAuthScope.email.rawValue == "email")
        #expect(OAuthScope.profile.rawValue == "profile")
    }
}

@Suite("OAuth Error Tests")
struct OAuthErrorTests {
    @Test("errors have descriptive messages")
    func errorsHaveDescriptiveMessages() {
        #expect(OAuthError.invalidAuthorizationURL.errorDescription != nil)
        #expect(OAuthError.missingAuthorizationCode.errorDescription != nil)
        #expect(OAuthError.stateMismatch.errorDescription != nil)
        #expect(OAuthError.tokenRequestFailed(statusCode: 400, body: "error").errorDescription != nil)
        #expect(OAuthError.invalidTokenResponse.errorDescription != nil)
        #expect(OAuthError.refreshFailed(reason: "test").errorDescription != nil)
        #expect(OAuthError.cancelled.errorDescription != nil)
    }

    @Test("tokenRequestFailed includes status code and body")
    func tokenRequestFailedIncludesDetails() {
        let error = OAuthError.tokenRequestFailed(statusCode: 401, body: "Unauthorized")
        let description = error.errorDescription ?? ""

        #expect(description.contains("401"))
        #expect(description.contains("Unauthorized"))
    }
}
