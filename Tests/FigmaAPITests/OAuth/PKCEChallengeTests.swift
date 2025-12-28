import Foundation
import Testing

@testable import FigmaAPI

@Suite("PKCE Challenge Tests")
struct PKCEChallengeTests {
    @Test("generate creates valid verifier")
    func generateCreatesValidVerifier() {
        let pkce = PKCEChallenge.generate()

        // Verifier should be base64url encoded (43 chars for 32 bytes)
        #expect(pkce.verifier.count >= 32)
        #expect(!pkce.verifier.contains("+"))
        #expect(!pkce.verifier.contains("/"))
        #expect(!pkce.verifier.contains("="))
    }

    @Test("generate creates valid challenge")
    func generateCreatesValidChallenge() {
        let pkce = PKCEChallenge.generate()

        // Challenge should be base64url encoded SHA-256 (43 chars)
        #expect(pkce.challenge.count >= 32)
        #expect(!pkce.challenge.contains("+"))
        #expect(!pkce.challenge.contains("/"))
        #expect(!pkce.challenge.contains("="))
    }

    @Test("generate uses S256 method")
    func generateUsesS256Method() {
        let pkce = PKCEChallenge.generate()

        #expect(pkce.method == "S256")
    }

    @Test("generate creates unique verifiers")
    func generateCreatesUniqueVerifiers() {
        let pkce1 = PKCEChallenge.generate()
        let pkce2 = PKCEChallenge.generate()

        #expect(pkce1.verifier != pkce2.verifier)
        #expect(pkce1.challenge != pkce2.challenge)
    }

    @Test("verifier and challenge are different")
    func verifierAndChallengeAreDifferent() {
        let pkce = PKCEChallenge.generate()

        #expect(pkce.verifier != pkce.challenge)
    }
}
