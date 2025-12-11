import ExFigCore
import FigmaAPI
import Foundation

/// Result of filtering components through granular cache.
struct GranularCacheResult: Sendable {
    /// Components that have changed and need re-export.
    let changedComponents: [NodeId: Component]

    /// Computed hashes for all components (for cache update).
    let computedHashes: [NodeId: String]
}

/// Manages per-node hash computation and change detection for granular caching.
///
/// This class fetches node documents from Figma, computes content hashes,
/// and compares them with cached hashes to determine which nodes have changed.
final class GranularCacheManager: @unchecked Sendable {
    private let client: Client
    private let cache: ImageTrackingCache

    /// Batch size for NodesEndpoint requests (Figma API limit).
    private let batchSize = 100

    init(client: Client, cache: ImageTrackingCache) {
        self.client = client
        self.cache = cache
    }

    /// Filters components to only those that have changed since last export.
    ///
    /// In batch mode with `--cache` and `--experimental-granular-cache`, nodes are
    /// pre-fetched before parallel config processing. This method checks the pre-fetched
    /// storage first to avoid redundant API calls.
    ///
    /// - Parameters:
    ///   - fileId: The Figma file ID.
    ///   - components: All components to potentially export.
    /// - Returns: Result containing changed components and all computed hashes.
    func filterChangedComponents(
        fileId: String,
        components: [NodeId: Component]
    ) async throws -> GranularCacheResult {
        guard !components.isEmpty else {
            return GranularCacheResult(changedComponents: [:], computedHashes: [:])
        }

        // Fetch node documents - check pre-fetched storage first
        let nodeIds = Array(components.keys)
        let nodes = try await fetchNodeDocumentsWithPreFetchCheck(fileId: fileId, nodeIds: nodeIds)

        // Compute hashes for all nodes
        var computedHashes: [NodeId: String] = [:]
        for (nodeId, node) in nodes {
            let hashableProps = node.document.toHashableProperties()
            let hash = NodeHasher.computeHash(hashableProps)
            computedHashes[nodeId] = hash
        }

        // Compare with cached hashes
        let changedNodeIds = cache.changedNodeIds(fileId: fileId, currentHashes: computedHashes)

        // Filter to only changed components
        var changedComponents: [NodeId: Component] = [:]
        for nodeId in changedNodeIds {
            if let component = components[nodeId] {
                changedComponents[nodeId] = component
            }
        }

        return GranularCacheResult(
            changedComponents: changedComponents,
            computedHashes: computedHashes
        )
    }

    /// Fetches node documents, checking pre-fetched storage first.
    ///
    /// In batch mode, nodes are pre-fetched before parallel config processing.
    /// This method uses pre-fetched nodes when available, falling back to API.
    private func fetchNodeDocumentsWithPreFetchCheck(
        fileId: String,
        nodeIds: [NodeId]
    ) async throws -> [NodeId: Node] {
        // Check pre-fetched nodes first (batch optimization)
        if let preFetched = PreFetchedNodesStorage.nodes,
           let preFetchedNodes = preFetched.nodes(for: fileId)
        {
            // Filter to only requested nodeIds
            let filteredNodes = preFetchedNodes.filter { nodeIds.contains($0.key) }

            // If we have all requested nodes, use pre-fetched
            if filteredNodes.count == nodeIds.count {
                return filteredNodes
            }

            // If some nodes are missing, fetch only the missing ones
            let missingNodeIds = nodeIds.filter { preFetchedNodes[$0] == nil }
            if !missingNodeIds.isEmpty {
                let fetchedNodes = try await fetchNodeDocuments(fileId: fileId, nodeIds: missingNodeIds)
                return filteredNodes.merging(fetchedNodes) { _, new in new }
            }

            return filteredNodes
        }

        // Fall back to API request (standalone mode or missing pre-fetch)
        return try await fetchNodeDocuments(fileId: fileId, nodeIds: nodeIds)
    }

    /// Fetches node documents from Figma API in batches.
    private func fetchNodeDocuments(
        fileId: String,
        nodeIds: [NodeId]
    ) async throws -> [NodeId: Node] {
        let batches = nodeIds.chunked(into: batchSize)

        // Fetch all batches in parallel with limited concurrency
        let allNodes = try await withThrowingTaskGroup(
            of: [NodeId: Node].self
        ) { [self] group in
            for batch in batches {
                group.addTask { [fileId, batch] in
                    let endpoint = NodesEndpoint(fileId: fileId, nodeIds: batch)
                    return try await self.client.request(endpoint)
                }
            }

            var results: [NodeId: Node] = [:]
            for try await batchResult in group {
                results.merge(batchResult) { _, new in new }
            }
            return results
        }

        return allNodes
    }
}
