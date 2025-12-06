@testable import FigmaAPI
import Foundation
import Testing

@Suite("RetryPolicy")
struct RetryPolicyTests {
    // MARK: - Delay Calculation

    @Test("First retry delay is approximately base delay")
    func firstRetryDelayIsApproximatelyBaseDelay() {
        let policy = RetryPolicy()

        // Attempt 0 means first retry
        let delay = policy.delay(for: 0)

        // Base delay is 1.0, with 20% jitter: 0.8 to 1.2
        #expect(delay >= 0.8)
        #expect(delay <= 1.2)
    }

    @Test("Delay increases exponentially with attempt number")
    func delayIncreasesExponentially() {
        let policy = RetryPolicy(jitterFactor: 0) // No jitter for predictable test

        let delay0 = policy.delay(for: 0) // 1 * 2^0 = 1
        let delay1 = policy.delay(for: 1) // 1 * 2^1 = 2
        let delay2 = policy.delay(for: 2) // 1 * 2^2 = 4
        let delay3 = policy.delay(for: 3) // 1 * 2^3 = 8

        #expect(delay0 == 1.0)
        #expect(delay1 == 2.0)
        #expect(delay2 == 4.0)
        #expect(delay3 == 8.0)
    }

    @Test("Delay is capped at maxDelay")
    func delayIsCappedAtMaxDelay() {
        let policy = RetryPolicy(maxDelay: 10.0, jitterFactor: 0)

        // Attempt 5 would be 2^5 = 32, but capped at 10
        let delay = policy.delay(for: 5)

        #expect(delay == 10.0)
    }

    @Test("Jitter varies delay within expected range")
    func jitterVariesDelayWithinRange() {
        let policy = RetryPolicy(jitterFactor: 0.5)

        // Run multiple times to check jitter produces variation
        var delays: Set<Double> = []
        for _ in 0 ..< 20 {
            delays.insert(policy.delay(for: 0))
        }

        // With 50% jitter on base delay of 1.0: range is 0.5 to 1.5
        // Should have some variation
        #expect(delays.count > 1, "Jitter should produce variation")
        for delay in delays {
            #expect(delay >= 0.5)
            #expect(delay <= 1.5)
        }
    }

    @Test("Custom policy uses provided values")
    func customPolicyUsesProvidedValues() {
        let policy = RetryPolicy(
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 60.0,
            jitterFactor: 0.1
        )

        #expect(policy.maxRetries == 5)
        #expect(policy.baseDelay == 2.0)
        #expect(policy.maxDelay == 60.0)
        #expect(policy.jitterFactor == 0.1)
    }

    // MARK: - Error Classification

    @Test("429 is retryable")
    func rateLimitIsRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 429, retryAfter: 30.0, body: Data())

        #expect(policy.isRetryable(error) == true)
    }

    @Test("500 is retryable")
    func internalServerErrorIsRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 500, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == true)
    }

    @Test("502 is retryable")
    func badGatewayIsRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 502, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == true)
    }

    @Test("503 is retryable")
    func serviceUnavailableIsRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 503, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == true)
    }

    @Test("504 is retryable")
    func gatewayTimeoutIsRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 504, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == true)
    }

    @Test("400 is not retryable")
    func badRequestIsNotRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 400, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == false)
    }

    @Test("401 is not retryable")
    func unauthorizedIsNotRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 401, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == false)
    }

    @Test("403 is not retryable")
    func forbiddenIsNotRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 403, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == false)
    }

    @Test("404 is not retryable")
    func notFoundIsNotRetryable() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 404, retryAfter: nil, body: Data())

        #expect(policy.isRetryable(error) == false)
    }

    @Test("URLError is retryable")
    func urlErrorIsRetryable() {
        let policy = RetryPolicy()
        let error = URLError(.timedOut)

        #expect(policy.isRetryable(error) == true)
    }

    @Test("URLError connection lost is retryable")
    func connectionLostIsRetryable() {
        let policy = RetryPolicy()
        let error = URLError(.networkConnectionLost)

        #expect(policy.isRetryable(error) == true)
    }

    @Test("URLError not connected is retryable")
    func notConnectedIsRetryable() {
        let policy = RetryPolicy()
        let error = URLError(.notConnectedToInternet)

        #expect(policy.isRetryable(error) == true)
    }

    @Test("URLError cancelled is not retryable")
    func cancelledIsNotRetryable() {
        let policy = RetryPolicy()
        let error = URLError(.cancelled)

        #expect(policy.isRetryable(error) == false)
    }

    @Test("Unknown error is not retryable")
    func unknownErrorIsNotRetryable() {
        struct UnknownError: Error {}
        let policy = RetryPolicy()

        #expect(policy.isRetryable(UnknownError()) == false)
    }

    // MARK: - shouldRetry

    @Test("shouldRetry returns true when within max retries")
    func shouldRetryWithinMaxRetries() {
        let policy = RetryPolicy(maxRetries: 4)
        let error = HTTPError(statusCode: 500, retryAfter: nil, body: Data())

        #expect(policy.shouldRetry(attempt: 0, error: error) == true)
        #expect(policy.shouldRetry(attempt: 1, error: error) == true)
        #expect(policy.shouldRetry(attempt: 2, error: error) == true)
        #expect(policy.shouldRetry(attempt: 3, error: error) == true)
    }

    @Test("shouldRetry returns false when max retries exceeded")
    func shouldRetryExceedsMaxRetries() {
        let policy = RetryPolicy(maxRetries: 4)
        let error = HTTPError(statusCode: 500, retryAfter: nil, body: Data())

        #expect(policy.shouldRetry(attempt: 4, error: error) == false)
        #expect(policy.shouldRetry(attempt: 5, error: error) == false)
    }

    @Test("shouldRetry returns false for non-retryable error")
    func shouldRetryNonRetryableError() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 401, retryAfter: nil, body: Data())

        #expect(policy.shouldRetry(attempt: 0, error: error) == false)
    }

    // MARK: - delay with retryAfter

    @Test("delay uses retryAfter when provided for 429")
    func delayUsesRetryAfterFor429() {
        let policy = RetryPolicy()
        let error = HTTPError(statusCode: 429, retryAfter: 45.0, body: Data())

        let delay = policy.delay(for: 0, error: error)

        #expect(delay == 45.0)
    }

    @Test("delay uses exponential backoff when no retryAfter")
    func delayUsesExponentialBackoffWhenNoRetryAfter() {
        let policy = RetryPolicy(jitterFactor: 0)
        let error = HTTPError(statusCode: 500, retryAfter: nil, body: Data())

        let delay = policy.delay(for: 1, error: error)

        #expect(delay == 2.0) // 1 * 2^1
    }

    @Test("delay respects retryAfter over maxDelay")
    func delayRespectsRetryAfterOverMaxDelay() {
        let policy = RetryPolicy(maxDelay: 30.0)
        let error = HTTPError(statusCode: 429, retryAfter: 60.0, body: Data())

        let delay = policy.delay(for: 0, error: error)

        // retryAfter should be respected even if > maxDelay
        #expect(delay == 60.0)
    }
}
