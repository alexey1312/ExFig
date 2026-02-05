@testable import FigmaAPI
import Foundation
import Testing

@Suite("FigmaAPIError")
struct FigmaAPIErrorTests {
    // MARK: - Error Descriptions

    @Test("401 error has authentication message")
    func authenticationErrorMessage() {
        let error = FigmaAPIError(statusCode: 401)

        #expect(error.errorDescription?.contains("Authentication failed") == true)
        #expect(error.errorDescription?.contains("FIGMA_PERSONAL_TOKEN") == true)
    }

    @Test("403 error has access denied message")
    func accessDeniedErrorMessage() {
        let error = FigmaAPIError(statusCode: 403)

        #expect(error.errorDescription?.contains("Access denied") == true)
        #expect(error.errorDescription?.contains("access") == true)
    }

    @Test("404 error has not found message")
    func notFoundErrorMessage() {
        let error = FigmaAPIError(statusCode: 404)

        #expect(error.errorDescription?.contains("not found") == true)
        #expect(error.errorDescription?.contains("file ID") == true)
    }

    @Test("429 error includes retry-after in message")
    func rateLimitErrorIncludesRetryAfter() {
        let error = FigmaAPIError(statusCode: 429, retryAfter: 45.0)

        #expect(error.errorDescription?.contains("Rate limited") == true)
        #expect(error.errorDescription?.contains("45") == true)
    }

    @Test("429 error without retry-after uses default")
    func rateLimitErrorUsesDefault() {
        let error = FigmaAPIError(statusCode: 429)

        #expect(error.errorDescription?.contains("Rate limited") == true)
        #expect(error.errorDescription?.contains("60") == true)
    }

    @Test("500 error indicates server error")
    func internalServerErrorMessage() {
        let error = FigmaAPIError(statusCode: 500)

        #expect(error.errorDescription?.contains("server error") == true)
        #expect(error.errorDescription?.contains("500") == true)
    }

    @Test("502 error indicates server error")
    func badGatewayErrorMessage() {
        let error = FigmaAPIError(statusCode: 502)

        #expect(error.errorDescription?.contains("server error") == true)
        #expect(error.errorDescription?.contains("502") == true)
    }

    @Test("503 error indicates server error")
    func serviceUnavailableErrorMessage() {
        let error = FigmaAPIError(statusCode: 503)

        #expect(error.errorDescription?.contains("server error") == true)
        #expect(error.errorDescription?.contains("503") == true)
    }

    @Test("504 error indicates server error")
    func gatewayTimeoutErrorMessage() {
        let error = FigmaAPIError(statusCode: 504)

        #expect(error.errorDescription?.contains("server error") == true)
        #expect(error.errorDescription?.contains("504") == true)
    }

    @Test("Unknown status code shows generic message")
    func unknownStatusCodeGenericMessage() {
        let error = FigmaAPIError(statusCode: 418)

        #expect(error.errorDescription?.contains("418") == true)
        #expect(error.errorDescription?.contains("HTTP") == true)
    }

    // MARK: - Recovery Suggestions

    @Test("401 error suggests setting token")
    func authenticationRecoverySuggestion() {
        let error = FigmaAPIError(statusCode: 401)

        #expect(error.recoverySuggestion?.contains("export FIGMA_PERSONAL_TOKEN") == true)
    }

    @Test("429 error suggests trying later")
    func rateLimitRecoverySuggestion() {
        let error = FigmaAPIError(statusCode: 429)

        #expect(error.recoverySuggestion?.contains("later") == true)
    }

    @Test("500-504 errors suggest checking status page")
    func serverErrorRecoverySuggestion() {
        for statusCode in [500, 501, 502, 503, 504] {
            let error = FigmaAPIError(statusCode: statusCode)
            #expect(error.recoverySuggestion?.contains("status.figma.com") == true)
        }
    }

    @Test("400 error has nil recovery suggestion")
    func badRequestNoRecoverySuggestion() {
        let error = FigmaAPIError(statusCode: 400)

        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - Retry Attempt Info

    @Test("Error includes attempt info when provided")
    func errorIncludesAttemptInfo() {
        let error = FigmaAPIError(statusCode: 500, attempt: 2, maxAttempts: 4)

        #expect(error.attempt == 2)
        #expect(error.maxAttempts == 4)
    }

    @Test("Retry message formatted correctly")
    func retryMessageFormatted() {
        let error = FigmaAPIError(statusCode: 502, retryAfter: 4.0, attempt: 2, maxAttempts: 4)

        let message = error.retryMessage
        #expect(message?.contains("attempt 2/4") == true || message?.contains("2/4") == true)
    }

    @Test("Retry message nil when no attempt info")
    func retryMessageNilWithoutAttemptInfo() {
        let error = FigmaAPIError(statusCode: 500)

        #expect(error.retryMessage == nil)
    }

    // MARK: - LocalizedError Conformance

    @Test("Conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: LocalizedError = FigmaAPIError(statusCode: 500)

        #expect(error.errorDescription != nil)
    }

    // MARK: - Factory Methods

    @Test("fromHTTPError creates FigmaAPIError")
    func fromHTTPErrorCreatesAPIError() {
        let httpError = HTTPError(statusCode: 429, retryAfter: 30.0, body: Data())
        let apiError = FigmaAPIError.from(httpError)

        #expect(apiError.statusCode == 429)
        #expect(apiError.retryAfter == 30.0)
    }

    @Test("fromHTTPError with attempt info")
    func fromHTTPErrorWithAttemptInfo() {
        let httpError = HTTPError(statusCode: 500, retryAfter: nil, body: Data())
        let apiError = FigmaAPIError.from(httpError, attempt: 3, maxAttempts: 4)

        #expect(apiError.statusCode == 500)
        #expect(apiError.attempt == 3)
        #expect(apiError.maxAttempts == 4)
    }

    // MARK: - Network Error Handling

    @Test("fromURLError creates appropriate error")
    func fromURLErrorCreatesError() {
        let urlError = URLError(.timedOut)
        let apiError = FigmaAPIError.from(urlError)

        #expect(apiError.errorDescription?.lowercased().contains("timeout") == true)
    }

    @Test("Network connection lost message")
    func networkConnectionLostMessage() {
        let urlError = URLError(.networkConnectionLost)
        let apiError = FigmaAPIError.from(urlError)

        #expect(apiError.errorDescription?.lowercased().contains("network") == true)
    }

    @Test("Not connected to internet message")
    func notConnectedToInternetMessage() {
        let urlError = URLError(.notConnectedToInternet)
        let apiError = FigmaAPIError.from(urlError)

        #expect(apiError.errorDescription?.lowercased().contains("internet") == true)
    }

    // MARK: - Unclassified Errors (HTTP 0)

    @Test("HTTP 0 without underlying message shows generic message")
    func unclassifiedErrorWithoutMessage() {
        let error = FigmaAPIError(statusCode: 0)

        #expect(error.errorDescription?.contains("Unknown network error") == true)
    }

    @Test("HTTP 0 with underlying message shows that message")
    func unclassifiedErrorWithMessage() {
        let error = FigmaAPIError(statusCode: 0, underlyingMessage: "File not found")

        #expect(error.errorDescription == "Figma API error: File not found")
    }

    @Test("HTTP 0 preserves detailed error context")
    func unclassifiedErrorPreservesContext() {
        let error = FigmaAPIError(
            statusCode: 0,
            underlyingMessage: "JSON decoding failed: key 'nodes' not found"
        )

        #expect(error.errorDescription?.contains("JSON decoding failed") == true)
        #expect(error.errorDescription?.contains("nodes") == true)
    }
}
