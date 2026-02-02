@testable import ExFig
@testable import FigmaAPI
import XCTest

final class ComponentPreFetcherTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Context Preservation Tests

    func testPreFetchOutsideBatchModeCreatesLocalContext() async throws {
        // Given: No existing batch context
        XCTAssertNil(BatchContextStorage.context)

        let client = MockClient()
        let params = Params.make(lightFileId: "file123")

        // Mock components response
        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components outside batch mode
        var capturedContext: BatchContext?
        _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
            client: client,
            params: params
        ) {
            capturedContext = BatchContextStorage.context
            return "result"
        }

        // Then: Local context was created with components only
        XCTAssertNotNil(capturedContext)
        XCTAssertNotNil(capturedContext?.components)
        XCTAssertNil(capturedContext?.versions)
        XCTAssertNil(capturedContext?.granularCache)
        XCTAssertNil(capturedContext?.nodes)

        // And: Context is no longer available after closure
        XCTAssertNil(BatchContextStorage.context)
    }

    func testPreFetchPreservesExistingVersionsInBatchMode() async throws {
        // Given: Existing batch context with versions
        let existingVersions = PreFetchedFileVersions(versions: ["fileA": makeMetadata(version: "v1")])
        let existingContext = BatchContext(versions: existingVersions)

        let client = MockClient()
        let params = Params.make(lightFileId: "file123")

        // Mock components response
        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components inside batch mode with existing versions
        var capturedContext: BatchContext?
        await BatchContextStorage.$context.withValue(existingContext) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    capturedContext = BatchContextStorage.context
                    return "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: Both components and versions are available
        XCTAssertNotNil(capturedContext?.components)
        XCTAssertNotNil(capturedContext?.versions)
        XCTAssertEqual(capturedContext?.versions?.metadata(for: "fileA")?.version, "v1")
    }

    func testPreFetchPreservesAllExistingContextFields() async throws {
        // Given: Existing batch context with all fields populated
        let existingVersions = PreFetchedFileVersions(versions: ["fileA": makeMetadata(version: "v1")])
        let existingNodes = PreFetchedNodes(nodes: ["fileA": [:]])

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let existingGranularCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        let existingContext = BatchContext(
            versions: existingVersions,
            components: nil, // No components yet
            granularCache: existingGranularCache,
            nodes: existingNodes
        )

        let client = MockClient()
        let params = Params.make(lightFileId: "file123")

        // Mock components response
        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components inside batch mode with all context fields
        var capturedContext: BatchContext?
        await BatchContextStorage.$context.withValue(existingContext) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    capturedContext = BatchContextStorage.context
                    return "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: All context fields are preserved
        XCTAssertNotNil(capturedContext?.versions, "versions should be preserved")
        XCTAssertNotNil(capturedContext?.components, "components should be added")
        XCTAssertNotNil(capturedContext?.granularCache, "granularCache should be preserved")
        XCTAssertNotNil(capturedContext?.nodes, "nodes should be preserved")
    }

    func testPreFetchSkipsWhenComponentsAlreadyAvailable() async throws {
        // Given: Existing batch context already has components
        let existingComponents = PreFetchedComponents(components: ["fileA": [
            Component.make(nodeId: "1:1", name: "existing_icon", frameName: "Icons"),
        ]])
        let existingContext = BatchContext(components: existingComponents)

        let client = MockClient()
        let params = Params.make(lightFileId: "file123")

        // When: Pre-fetching components when they're already available
        var capturedContext: BatchContext?
        await BatchContextStorage.$context.withValue(existingContext) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    capturedContext = BatchContextStorage.context
                    return "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: Original components are preserved (no new fetch)
        XCTAssertEqual(client.requestCount, 0, "No API calls should be made")
        XCTAssertNotNil(capturedContext?.components)
        XCTAssertTrue(capturedContext?.components?.hasComponents(for: "fileA") ?? false)
    }

    // MARK: - Helpers

    private func makeMetadata(version: String) -> FileMetadata {
        let json = """
        {
            "version": "\(version)",
            "name": "Test File",
            "lastModified": "2024-01-01T00:00:00Z"
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(FileMetadata.self, from: Data(json.utf8))
    }
}
