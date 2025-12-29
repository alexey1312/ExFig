import FigmaAPI
import Foundation

// MARK: - Components Provider

/// Protocol for pre-fetched components storage.
///
/// Allows loaders to use pre-fetched components without depending on CLI-specific TaskLocal storage.
public protocol ComponentsProvider: Sendable {
    /// Get pre-fetched components for a fileId.
    /// - Parameter fileId: The Figma file ID to look up.
    /// - Returns: The components if pre-fetched, nil otherwise.
    func components(for fileId: String) -> [Component]?
}

/// TaskLocal storage for injecting components provider.
///
/// In batch mode, the CLI sets this with pre-fetched components.
/// In standalone or GUI mode, this is `nil` and loaders fetch their own components.
public enum ComponentsProviderStorage {
    @TaskLocal public static var provider: ComponentsProvider?
}

// MARK: - Nodes Provider

/// Protocol for pre-fetched node documents storage.
///
/// Allows granular cache to use pre-fetched nodes without depending on CLI-specific TaskLocal storage.
public protocol NodesProvider: Sendable {
    /// Get all pre-fetched nodes for a fileId.
    /// - Parameter fileId: The Figma file ID to look up.
    /// - Returns: All nodes for this file if pre-fetched, nil otherwise.
    func nodes(for fileId: String) -> [NodeId: Node]?

    /// Get pre-fetched node for a specific fileId and nodeId.
    /// - Parameters:
    ///   - fileId: The Figma file ID.
    ///   - nodeId: The node ID to look up.
    /// - Returns: The node if pre-fetched, nil otherwise.
    func node(fileId: String, nodeId: NodeId) -> Node?
}

/// TaskLocal storage for injecting nodes provider.
///
/// In batch mode with granular cache, the CLI sets this with pre-fetched nodes.
/// In standalone or GUI mode, this is `nil` and GranularCacheManager fetches nodes via API.
public enum NodesProviderStorage {
    @TaskLocal public static var provider: NodesProvider?
}
