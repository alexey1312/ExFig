@testable import ExFigCLI
@testable import FigmaAPI
import XCTest

/// Tests for GranularCacheManager which handles per-node hash tracking.
final class GranularCacheManagerTests: XCTestCase {
    var mockClient: MockClient!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        mockClient = MockClient()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        mockClient = nil
        super.tearDown()
    }

    // MARK: - First Run (No Cached Hashes)

    func testFirstRunReturnsAllComponents() async throws {
        // Setup: Create components and mock node responses
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
            Component.make(nodeId: "1:3", name: "icon_profile", frameName: "Icons"),
        ]
        let nodes = makeNodeResponse(for: components)
        mockClient.setResponse(nodes, for: NodesEndpoint.self)

        // Empty cache (first run)
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        let result = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // All components should be returned on first run
        XCTAssertEqual(result.changedComponents.count, 3)
        XCTAssertEqual(result.computedHashes.count, 3)
    }

    // MARK: - Cache Hit (All Hashes Match)

    func testCacheHitReturnsNoComponents() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
        ]
        let nodes = makeNodeResponse(for: components)
        mockClient.setResponse(nodes, for: NodesEndpoint.self)

        // Pre-compute hashes and populate cache
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        // First call to get hashes
        let firstResult = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // Update cache with computed hashes
        cache.updateNodeHashes(fileId: "file123", hashes: firstResult.computedHashes)

        // Second call with same data - should return empty
        let managerWithCache = GranularCacheManager(client: mockClient, cache: cache)
        let secondResult = try await managerWithCache.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        XCTAssertEqual(secondResult.changedComponents.count, 0)
    }

    // MARK: - Partial Change Detection

    func testPartialChangeReturnsOnlyChangedComponents() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
            Component.make(nodeId: "1:3", name: "icon_profile", frameName: "Icons"),
        ]

        // Initial nodes
        let initialNodes = makeNodeResponse(for: components)
        mockClient.setResponse(initialNodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)
        let firstResult = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // Update cache
        cache.updateNodeHashes(fileId: "file123", hashes: firstResult.computedHashes)

        // Now change one node (1:2) by giving it different fill
        var modifiedNodes = initialNodes
        if modifiedNodes["1:2"] != nil {
            // Create a new node with different fills (red instead of gray)
            modifiedNodes["1:2"] = Node.makeWithFill(
                id: "1:2",
                name: "icon_settings",
                fillColor: PaintColor(r: 1.0, g: 0.0, b: 0.0, a: 1.0)
            )
        }
        mockClient.setResponse(modifiedNodes, for: NodesEndpoint.self)

        // Second call should only return the changed component
        let managerWithCache = GranularCacheManager(client: mockClient, cache: cache)
        let secondResult = try await managerWithCache.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        XCTAssertEqual(secondResult.changedComponents.count, 1)
        XCTAssertNotNil(secondResult.changedComponents["1:2"])
    }

    // MARK: - New Node Detection

    func testNewNodeIsIncludedInChanges() async throws {
        let initialComponents = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
        ]
        let initialNodes = makeNodeResponse(for: initialComponents)
        mockClient.setResponse(initialNodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)
        let firstResult = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: initialComponents.map { ($0.nodeId, $0) })
        )
        cache.updateNodeHashes(fileId: "file123", hashes: firstResult.computedHashes)

        // Add a new component
        let updatedComponents = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_new", frameName: "Icons"),
        ]
        let updatedNodes = makeNodeResponse(for: updatedComponents)
        mockClient.setResponse(updatedNodes, for: NodesEndpoint.self)

        let managerWithCache = GranularCacheManager(client: mockClient, cache: cache)
        let secondResult = try await managerWithCache.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: updatedComponents.map { ($0.nodeId, $0) })
        )

        // Only the new node should be in changes
        XCTAssertEqual(secondResult.changedComponents.count, 1)
        XCTAssertNotNil(secondResult.changedComponents["1:2"])
    }

    // MARK: - Deleted Node Cleanup

    func testDeletedNodesAreNotIncludedInChanges() async throws {
        let initialComponents = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_to_delete", frameName: "Icons"),
        ]
        let initialNodes = makeNodeResponse(for: initialComponents)
        mockClient.setResponse(initialNodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)
        let firstResult = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: initialComponents.map { ($0.nodeId, $0) })
        )
        cache.updateNodeHashes(fileId: "file123", hashes: firstResult.computedHashes)

        // Remove one component (simulating deletion in Figma)
        let remainingComponents = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
        ]
        let remainingNodes = makeNodeResponse(for: remainingComponents)
        mockClient.setResponse(remainingNodes, for: NodesEndpoint.self)

        let managerWithCache = GranularCacheManager(client: mockClient, cache: cache)
        let secondResult = try await managerWithCache.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: remainingComponents.map { ($0.nodeId, $0) })
        )

        // No changes - existing node unchanged, deleted node not included
        XCTAssertEqual(secondResult.changedComponents.count, 0)
    }

    // MARK: - Hash Computation Batching

    func testLargeComponentSetIsBatched() async throws {
        // Create 150 components (should trigger batching at 100)
        let components = (0 ..< 150).map { i in
            Component.make(nodeId: "node\(i)", name: "icon_\(i)", frameName: "Icons")
        }
        let nodes = makeNodeResponse(for: components)
        mockClient.setResponse(nodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        let result = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // All components should be returned
        XCTAssertEqual(result.changedComponents.count, 150)
        XCTAssertEqual(result.computedHashes.count, 150)

        // Verify batching occurred (at least 2 requests for 150 items)
        let nodesRequests = mockClient.requests(containing: "nodes")
        XCTAssertGreaterThanOrEqual(nodesRequests.count, 2)
    }

    // MARK: - Parallel Hash Computation

    func testParallelHashComputationProducesDeterministicResults() async throws {
        // Given: Multiple components with the same data
        let components = (0 ..< 20).map { i in
            Component.make(nodeId: "node\(i)", name: "icon_\(i)", frameName: "Icons")
        }
        let nodes = makeNodeResponse(for: components)
        mockClient.setResponse(nodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        // When: Computing hashes multiple times
        let result1 = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        let result2 = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // Then: Hashes should be identical (deterministic)
        XCTAssertEqual(result1.computedHashes, result2.computedHashes)
    }

    func testEmptyComponentsReturnsEmptyResult() async throws {
        // Given: No components
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        // When: Filtering with empty components
        let result = try await manager.filterChangedComponents(
            fileId: "file123",
            components: [:]
        )

        // Then: Empty result
        XCTAssertTrue(result.changedComponents.isEmpty)
        XCTAssertTrue(result.computedHashes.isEmpty)
    }

    func testParallelHashComputationWithManyNodes() async throws {
        // Given: Large number of components to trigger parallel processing
        let components = (0 ..< 200).map { i in
            Component.make(nodeId: "node\(i)", name: "icon_\(i)", frameName: "Icons")
        }
        let nodes = makeNodeResponse(for: components)
        mockClient.setResponse(nodes, for: NodesEndpoint.self)

        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file123", version: "v1")

        let manager = GranularCacheManager(client: mockClient, cache: cache)

        // When: Computing hashes for many nodes
        let result = try await manager.filterChangedComponents(
            fileId: "file123",
            components: Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
        )

        // Then: All hashes computed correctly
        XCTAssertEqual(result.computedHashes.count, 200)
        XCTAssertEqual(result.changedComponents.count, 200)

        // Verify each hash is non-empty
        for (_, hash) in result.computedHashes {
            XCTAssertFalse(hash.isEmpty)
        }
    }

    // MARK: - Helpers

    private func makeNodeResponse(for components: [Component]) -> [NodeId: Node] {
        var nodes: [NodeId: Node] = [:]
        for component in components {
            nodes[component.nodeId] = Node.makeWithFill(
                id: component.nodeId,
                name: component.name,
                fillColor: PaintColor(r: 0.5, g: 0.5, b: 0.5, a: 1.0)
            )
        }
        return nodes
    }
}

// MARK: - Test Helpers

extension Node {
    /// Creates a Node with a document containing specified fill.
    static func makeWithFill(id: String, name: String, fillColor: PaintColor) -> Node {
        let colorJSON = """
        {"r": \(fillColor.r), "g": \(fillColor.g), "b": \(fillColor.b), "a": \(fillColor.a)}
        """
        let json = """
        {
            "document": {
                "id": "\(id)",
                "name": "\(name)",
                "type": "COMPONENT",
                "fills": [{"type": "SOLID", "color": \(colorJSON)}]
            }
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Node.self, from: Data(json.utf8))
    }
}
