import FigmaAPI
import Foundation

/// Result of filtering components through granular cache.
public struct GranularCacheFilterResult: Sendable {
    /// Components that have changed and need re-export.
    public let changedComponents: [NodeId: Component]

    /// Computed hashes for all components (for cache update).
    public let computedHashes: [NodeId: String]

    public init(changedComponents: [NodeId: Component], computedHashes: [NodeId: String]) {
        self.changedComponents = changedComponents
        self.computedHashes = computedHashes
    }
}

/// Protocol for granular cache functionality.
///
/// Allows ImageLoaderBase to work without direct dependency on GranularCacheManager.
/// GUI app can pass `nil` for no granular caching, CLI can provide full implementation.
public protocol GranularCacheProvider: Sendable {
    /// Filters components to only those that have changed since last export.
    ///
    /// - Parameters:
    ///   - fileId: The Figma file ID.
    ///   - components: All components to potentially export.
    /// - Returns: Result containing changed components and all computed hashes.
    func filterChangedComponents(
        fileId: String,
        components: [NodeId: Component]
    ) async throws -> GranularCacheFilterResult
}
