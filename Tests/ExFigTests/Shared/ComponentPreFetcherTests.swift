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

    // MARK: - Basic Functionality Tests

    func testPreFetchOutsideBatchModeFetchesComponents() async throws {
        // Given: No existing batch context
        XCTAssertNil(BatchSharedState.current)

        let client = MockClient()
        let params = PKLConfig.make(lightFileId: "file123")

        // Mock components response
        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components outside batch mode
        var processExecuted = false
        _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
            client: client,
            params: params
        ) {
            processExecuted = true
            return "result"
        }

        // Then: Process was executed and components were fetched
        XCTAssertTrue(processExecuted)
        XCTAssertEqual(client.requestCount, 1, "Should fetch components via API")
    }

    func testPreFetchInBatchModeFetchesAndStoresComponents() async {
        // Given: Existing batch context with versions but no components
        let existingVersions = PreFetchedFileVersions(versions: ["fileA": makeMetadata(version: "v1")])
        let existingContext = BatchContext(versions: existingVersions)
        let batchState = BatchSharedState(context: existingContext)

        let client = MockClient()
        let params = PKLConfig.make(lightFileId: "file123")

        // Mock components response
        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components inside batch mode
        await BatchSharedState.$current.withValue(batchState) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: Components were fetched and stored in actor
        XCTAssertEqual(client.requestCount, 1, "Should fetch components via API")
        let storedComponents = await batchState.getComponents()
        XCTAssertNotNil(storedComponents, "Components should be stored in BatchSharedState")
        XCTAssertTrue(storedComponents?.hasComponents(for: "file123") ?? false)
    }

    func testPreFetchSkipsWhenComponentsAlreadyAvailableInBatch() async {
        // Given: Existing batch context already has components for required file
        let existingComponents = PreFetchedComponents(components: ["file123": [
            Component.make(nodeId: "1:1", name: "existing_icon", frameName: "Icons"),
        ]])
        let existingContext = BatchContext(components: existingComponents)
        let batchState = BatchSharedState(context: existingContext)

        let client = MockClient()
        let params = PKLConfig.make(lightFileId: "file123")

        // When: Pre-fetching components when they're already available
        await BatchSharedState.$current.withValue(batchState) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: No API calls should be made - components already exist
        XCTAssertEqual(client.requestCount, 0, "No API calls should be made when components exist")
    }

    func testPreFetchFetchesOnlyMissingComponents() async {
        // Given: Existing batch context has components for some files but not all
        let existingComponents = PreFetchedComponents(components: ["fileA": [
            Component.make(nodeId: "1:1", name: "existing_icon", frameName: "Icons"),
        ]])
        let existingContext = BatchContext(components: existingComponents)
        let batchState = BatchSharedState(context: existingContext)

        let client = MockClient()
        // Request components for both fileA (exists) and fileB (missing)
        let params = PKLConfig.make(lightFileId: "fileA", darkFileId: "fileB")

        // Mock components response for fileB
        let mockComponents = [
            Component.make(nodeId: "2:1", name: "new_icon", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Pre-fetching components
        await BatchSharedState.$current.withValue(batchState) {
            do {
                _ = try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: params
                ) {
                    "result"
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: Only fileB should be fetched
        XCTAssertEqual(client.requestCount, 1, "Should only fetch missing fileB")
    }

    func testPreFetchComponentsDirectly() async throws {
        // Given: Client and params
        let client = MockClient()
        let params = PKLConfig.make(lightFileId: "file123")

        let mockComponents = [
            Component.make(nodeId: "1:1", name: "icon_test", frameName: "Icons"),
        ]
        client.setResponse(mockComponents, for: ComponentsEndpoint.self)

        // When: Using the direct preFetchComponents method
        let result = try await ComponentPreFetcher.preFetchComponents(
            client: client,
            params: params
        )

        // Then: Components were fetched and returned
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.hasComponents(for: "file123") ?? false)
        XCTAssertEqual(client.requestCount, 1)
    }

    func testPreFetchComponentsSkipsInBatchModeWhenExists() async {
        // Given: Batch mode with existing components
        let existingComponents = PreFetchedComponents(components: ["file123": [
            Component.make(nodeId: "1:1", name: "existing_icon", frameName: "Icons"),
        ]])
        let existingContext = BatchContext(components: existingComponents)
        let batchState = BatchSharedState(context: existingContext)

        let client = MockClient()
        let params = PKLConfig.make(lightFileId: "file123")

        // When: Using the direct preFetchComponents method inside batch mode
        var result: PreFetchedComponents?
        await BatchSharedState.$current.withValue(batchState) {
            result = try? await ComponentPreFetcher.preFetchComponents(
                client: client,
                params: params
            )
        }

        // Then: No fetch happened, nil returned
        XCTAssertNil(result, "Should return nil when all components already exist")
        XCTAssertEqual(client.requestCount, 0)
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
