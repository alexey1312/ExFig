import CustomDump
@testable import FigmaAPI
import XCTest

final class MockClientTests: XCTestCase {
    var client: MockClient!

    override func setUp() {
        super.setUp()
        client = MockClient()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    // MARK: - Response Configuration

    func testSetResponseReturnsConfiguredValue() async throws {
        let expectedStyles = [
            Style(styleType: .fill, nodeId: "1:1", name: "test", description: ""),
        ]
        client.setResponse(expectedStyles, for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "test")
        let result = try await client.request(endpoint)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "test")
    }

    func testSetResponseOverridesPreviousResponse() async throws {
        let first = [Style(styleType: .fill, nodeId: "1:1", name: "first", description: "")]
        let second = [Style(styleType: .fill, nodeId: "2:2", name: "second", description: "")]

        client.setResponse(first, for: StylesEndpoint.self)
        client.setResponse(second, for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "test")
        let result = try await client.request(endpoint)

        XCTAssertEqual(result[0].name, "second")
    }

    // MARK: - Error Configuration

    func testSetErrorThrowsConfiguredError() async {
        let expectedError = MockClientError.noResponseConfigured(endpoint: "test")
        client.setError(expectedError, for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "test")

        do {
            _ = try await client.request(endpoint)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockClientError)
        }
    }

    func testSetResponseClearsError() async throws {
        client.setError(MockClientError.noResponseConfigured(endpoint: ""), for: StylesEndpoint.self)
        client.setResponse([Style](), for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "test")
        let result = try await client.request(endpoint)

        XCTAssertEqual(result.count, 0)
    }

    func testSetErrorClearsResponse() async {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setError(MockClientError.noResponseConfigured(endpoint: "cleared"), for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "test")

        do {
            _ = try await client.request(endpoint)
            XCTFail("Expected error")
        } catch {
            // Success
        }
    }

    // MARK: - Request Logging

    func testRequestLogRecordsRequests() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)

        let endpoint = StylesEndpoint(fileId: "myfile")
        _ = try await client.request(endpoint)

        XCTAssertEqual(client.requestCount, 1)
        XCTAssertTrue(client.lastRequest?.url?.absoluteString.contains("myfile") ?? false)
    }

    func testRequestLogRecordsMultipleRequests() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)

        let endpoint1 = StylesEndpoint(fileId: "file1")
        let endpoint2 = StylesEndpoint(fileId: "file2")

        _ = try await client.request(endpoint1)
        _ = try await client.request(endpoint2)

        XCTAssertEqual(client.requestCount, 2)
    }

    func testRequestsContainingPath() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setResponse([Component](), for: ComponentsEndpoint.self)

        _ = try await client.request(StylesEndpoint(fileId: "test"))
        _ = try await client.request(ComponentsEndpoint(fileId: "test"))

        let styleRequests = client.requests(containing: "styles")
        let componentRequests = client.requests(containing: "components")

        XCTAssertEqual(styleRequests.count, 1)
        XCTAssertEqual(componentRequests.count, 1)
    }

    // MARK: - Reset

    func testResetClearsEverything() async {
        client.setResponse([Style](), for: StylesEndpoint.self)

        // Make a request to populate the log
        _ = try? await client.request(StylesEndpoint(fileId: "test"))

        client.reset()

        XCTAssertEqual(client.requestCount, 0)

        // Should now throw because response was cleared
        do {
            _ = try await client.request(StylesEndpoint(fileId: "test"))
            XCTFail("Expected error after reset")
        } catch {
            // Success
        }
    }

    // MARK: - No Response Configured

    func testThrowsWhenNoResponseConfigured() async {
        let endpoint = StylesEndpoint(fileId: "test")

        do {
            _ = try await client.request(endpoint)
            XCTFail("Expected MockClientError.noResponseConfigured")
        } catch let error as MockClientError {
            if case let .noResponseConfigured(endpointName) = error {
                XCTAssertTrue(endpointName.contains("StylesEndpoint"))
            } else {
                XCTFail("Unexpected error type")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Thread Safety

    func testConcurrentAccess() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        let localClient = try XCTUnwrap(client)

        // Make many concurrent requests
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 100 {
                group.addTask {
                    _ = try? await localClient.request(StylesEndpoint(fileId: "test"))
                }
            }
        }

        XCTAssertEqual(client.requestCount, 100)
    }

    // MARK: - Timestamp Tracking

    func testRequestTimestampsAreCaptured() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)

        _ = try await client.request(StylesEndpoint(fileId: "test"))

        XCTAssertEqual(client.requestTimestamps.count, 1)
        XCTAssertNotNil(client.requestTimestamps.first)
    }

    func testRequestTimestampsAreInChronologicalOrder() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)

        _ = try await client.request(StylesEndpoint(fileId: "test1"))
        _ = try await client.request(StylesEndpoint(fileId: "test2"))

        XCTAssertEqual(client.requestTimestamps.count, 2)
        XCTAssertLessThanOrEqual(
            client.requestTimestamps[0],
            client.requestTimestamps[1]
        )
    }

    // MARK: - Request Delay

    func testRequestDelaySlowsDownRequests() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setRequestDelay(0.1) // 100ms

        let startTime = Date()
        _ = try await client.request(StylesEndpoint(fileId: "test"))
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertGreaterThanOrEqual(duration, 0.09) // Allow small margin
    }

    func testConcurrentRequestsCompleteInParallelTime() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setRequestDelay(0.15) // 150ms per request
        let localClient = try XCTUnwrap(client)

        let startTime = Date()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { _ = try? await localClient.request(StylesEndpoint(fileId: "a")) }
            group.addTask { _ = try? await localClient.request(StylesEndpoint(fileId: "b")) }
        }
        let duration = Date().timeIntervalSince(startTime)

        // If parallel: ~150ms, If sequential: ~300ms
        // Threshold 0.28s gives CI headroom while still proving parallelism
        XCTAssertLessThan(duration, 0.28, "Concurrent requests should complete in parallel")
        XCTAssertEqual(client.requestCount, 2)
    }

    func testRequestsStartedWithinTimeWindow() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setRequestDelay(0.05)
        let localClient = try XCTUnwrap(client)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { _ = try? await localClient.request(StylesEndpoint(fileId: "a")) }
            group.addTask { _ = try? await localClient.request(StylesEndpoint(fileId: "b")) }
            group.addTask { _ = try? await localClient.request(StylesEndpoint(fileId: "c")) }
        }

        // All 3 requests should have started within 20ms of each other
        XCTAssertTrue(client.requestsStartedWithin(seconds: 0.02))
    }

    func testResetClearsTimestampsAndDelay() async throws {
        client.setResponse([Style](), for: StylesEndpoint.self)
        client.setRequestDelay(0.1)
        _ = try await client.request(StylesEndpoint(fileId: "test"))

        client.reset()

        XCTAssertEqual(client.requestTimestamps.count, 0)

        // After reset, delay should be 0, so request should be fast
        client.setResponse([Style](), for: StylesEndpoint.self)
        let startTime = Date()
        _ = try await client.request(StylesEndpoint(fileId: "test"))
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 0.05)
    }
}
