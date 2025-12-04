// swiftlint:disable file_length
@testable import FigmaAPI
import Foundation
import Testing

@Suite("RateLimitedClient")
struct RateLimitedClientTests {
    @Test("Request acquires rate limit token before making request")
    func requestAcquiresTokenBeforeMaking() async throws {
        let mockClient = MockRequestTrackingClient()
        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let configID = ConfigID("test-config")

        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: configID
        )

        let endpoint = MockEndpoint(response: "success")
        _ = try await client.request(endpoint)

        // Check that rate limiter tracked the request
        let status = await rateLimiter.status()
        #expect(status.configRequestCounts[configID] == 1)

        // Check that underlying client was called
        #expect(mockClient.requestCount == 1)
    }

    @Test("Multiple requests from same config tracked correctly")
    func multipleRequestsTrackedCorrectly() async throws {
        let mockClient = MockRequestTrackingClient()
        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let configID = ConfigID("test-config")

        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: configID
        )

        let endpoint = MockEndpoint(response: "success")
        _ = try await client.request(endpoint)
        _ = try await client.request(endpoint)
        _ = try await client.request(endpoint)

        let status = await rateLimiter.status()
        #expect(status.configRequestCounts[configID] == 3)
        #expect(mockClient.requestCount == 3)
    }
}

@Suite("RateLimitedClient Retry")
struct RateLimitedClientRetryTests {
    @Test("Retries on 500 server error and succeeds")
    func retriesOn500AndSucceeds() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 500, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 2)
    }

    @Test("Retries on 502 bad gateway and succeeds")
    func retriesOn502AndSucceeds() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 502, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 2)
    }

    @Test("Retries on 503 service unavailable and succeeds")
    func retriesOn503AndSucceeds() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 503, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 2)
    }

    @Test("Retries on 504 gateway timeout and succeeds")
    func retriesOn504AndSucceeds() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 504, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 2)
    }

    @Test("Fails after max retries exhausted")
    func failsAfterMaxRetriesExhausted() async throws {
        let mockClient = MockSequenceClient()
        // 5 failures = initial + 4 retries
        for _ in 0 ..< 5 {
            mockClient.addResponse(throwing: HTTPError(statusCode: 500, retryAfter: nil, body: Data()))
        }

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        await #expect(throws: FigmaAPIError.self) {
            _ = try await client.request(MockEndpoint(response: "ignored"))
        }
        // Initial request + 4 retries = 5 total
        #expect(mockClient.requestCount == 5)
    }

    @Test("Does not retry on 401 unauthorized")
    func doesNotRetryOn401() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 401, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "should-not-reach")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        await #expect(throws: FigmaAPIError.self) {
            _ = try await client.request(MockEndpoint(response: "ignored"))
        }
        #expect(mockClient.requestCount == 1)
    }

    @Test("Does not retry on 404 not found")
    func doesNotRetryOn404() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 404, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "should-not-reach")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        await #expect(throws: FigmaAPIError.self) {
            _ = try await client.request(MockEndpoint(response: "ignored"))
        }
        #expect(mockClient.requestCount == 1)
    }

    @Test("Retries multiple times before succeeding")
    func retriesMultipleTimesBeforeSucceeding() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 500, retryAfter: nil, body: Data()))
        mockClient.addResponse(throwing: HTTPError(statusCode: 502, retryAfter: nil, body: Data()))
        mockClient.addResponse(throwing: HTTPError(statusCode: 503, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 4)
    }

    @Test("Retries on URLError timeout")
    func retriesOnURLErrorTimeout() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: URLError(.timedOut))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let result = try await client.request(MockEndpoint(response: "ignored"))
        #expect(result == "success")
        #expect(mockClient.requestCount == 2)
    }

    @Test("Uses retry-after from 429 response")
    func usesRetryAfterFrom429Response() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 429, retryAfter: 0.01, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 1.0, jitterFactor: 0) // Long base delay
        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy
        )

        let start = Date()
        let result = try await client.request(MockEndpoint(response: "ignored"))
        let elapsed = Date().timeIntervalSince(start)

        #expect(result == "success")
        // Should use retryAfter (0.01s) not baseDelay (1.0s)
        #expect(elapsed < 0.5)
    }

    @Test("Calls onRetry callback for each retry attempt")
    func callsOnRetryCallbackForEachAttempt() async throws {
        let mockClient = MockSequenceClient()
        mockClient.addResponse(throwing: HTTPError(statusCode: 500, retryAfter: nil, body: Data()))
        mockClient.addResponse(throwing: HTTPError(statusCode: 502, retryAfter: nil, body: Data()))
        mockClient.addResponse(returning: "success")

        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let retryPolicy = RetryPolicy(maxRetries: 4, baseDelay: 0.01, jitterFactor: 0)

        let tracker = RetryAttemptTracker()
        let onRetry: @Sendable (Int, Error) async -> Void = { attempt, error in
            await tracker.record(attempt: attempt, error: error)
        }

        let client = RateLimitedClient(
            client: mockClient,
            rateLimiter: rateLimiter,
            configID: ConfigID("test"),
            retryPolicy: retryPolicy,
            onRetry: onRetry
        )

        _ = try await client.request(MockEndpoint(response: "ignored"))

        let attempts = await tracker.attempts
        #expect(attempts.count == 2)
        #expect(attempts[0].attempt == 1)
        #expect(attempts[1].attempt == 2)
    }
}

/// Thread-safe tracker for retry attempts.
actor RetryAttemptTracker {
    private(set) var attempts: [(attempt: Int, error: Error)] = []

    func record(attempt: Int, error: Error) {
        attempts.append((attempt, error))
    }
}

@Suite("HTTPError")
struct HTTPErrorTests {
    @Test("HTTPError stores status code")
    func storesStatusCode() {
        let error = HTTPError(statusCode: 429, retryAfter: 30.0, body: Data())

        #expect(error.statusCode == 429)
    }

    @Test("HTTPError stores retry-after")
    func storesRetryAfter() {
        let error = HTTPError(statusCode: 429, retryAfter: 60.0, body: Data())

        #expect(error.retryAfter == 60.0)
    }

    @Test("HTTPError description includes status code")
    func descriptionIncludesStatusCode() {
        let error = HTTPError(statusCode: 500, retryAfter: nil, body: Data())

        #expect(error.localizedDescription.contains("500"))
    }
}

// MARK: - Test Helpers

/// Mock client that tracks request counts.
final class MockRequestTrackingClient: Client, @unchecked Sendable {
    private(set) var requestCount = 0
    var shouldThrow: Error?

    func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        requestCount += 1
        if let error = shouldThrow {
            throw error
        }
        // The endpoint must be our MockEndpoint to cast correctly
        if let mockEndpoint = endpoint as? MockEndpoint {
            // swiftlint:disable:next force_cast
            return mockEndpoint.response as! T.Content
        }
        fatalError("MockRequestTrackingClient only supports MockEndpoint")
    }
}

/// Mock client that returns a sequence of responses/errors.
final class MockSequenceClient: Client, @unchecked Sendable {
    private let queue = DispatchQueue(label: "mock-sequence-client")
    private var responses: [Result<String, Error>] = []
    private var _requestCount = 0

    var requestCount: Int {
        queue.sync { _requestCount }
    }

    func addResponse(returning value: String) {
        queue.sync { responses.append(.success(value)) }
    }

    func addResponse(throwing error: Error) {
        queue.sync { responses.append(.failure(error)) }
    }

    func request<T: Endpoint>(_: T) async throws -> T.Content {
        let result: Result<String, Error> = queue.sync {
            _requestCount += 1
            guard !responses.isEmpty else {
                fatalError("MockSequenceClient: no more responses configured")
            }
            return responses.removeFirst()
        }

        switch result {
        case let .success(value):
            // swiftlint:disable:next force_cast
            return value as! T.Content
        case let .failure(error):
            throw error
        }
    }
}

/// Mock endpoint for testing.
struct MockEndpoint: Endpoint {
    typealias Content = String

    let response: String

    func makeRequest(baseURL: URL) -> URLRequest {
        URLRequest(url: baseURL)
    }

    func content(from _: URLResponse?, with _: Data) throws -> String {
        response
    }
}
