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
