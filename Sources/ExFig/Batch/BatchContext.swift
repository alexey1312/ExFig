import FigmaAPI

/// Unified context for batch processing optimization.
///
/// Consolidates all pre-fetched data into a single struct to avoid nested `@Sendable` closures
/// which can cause Swift runtime crashes on Linux.
/// See: https://github.com/swiftlang/swift/issues/75501
///
/// ## Usage
///
/// ```swift
/// let context = BatchContext(
///     versions: preFetchedVersions,
///     components: preFetchedComponents,
///     granularCache: sharedGranularCache,
///     nodes: preFetchedNodes
/// )
///
/// await BatchContextStorage.$context.withValue(context) {
///     // All batch data accessible via BatchContextStorage.context
/// }
/// ```
struct BatchContext: Sendable {
    /// Pre-fetched file metadata for version checking.
    let versions: PreFetchedFileVersions?

    /// Pre-fetched components from Figma API.
    let components: PreFetchedComponents?

    /// Shared granular cache for per-node hash tracking.
    let granularCache: SharedGranularCache?

    /// Pre-fetched node documents for granular cache.
    let nodes: PreFetchedNodes?

    /// Creates a new batch context with optional pre-fetched data.
    init(
        versions: PreFetchedFileVersions? = nil,
        components: PreFetchedComponents? = nil,
        granularCache: SharedGranularCache? = nil,
        nodes: PreFetchedNodes? = nil
    ) {
        self.versions = versions
        self.components = components
        self.granularCache = granularCache
        self.nodes = nodes
    }

    /// Whether any batch context is active (any field is non-nil).
    ///
    /// Used to detect batch mode in export commands.
    var isBatchMode: Bool {
        versions != nil || components != nil || granularCache != nil || nodes != nil
    }

    /// Whether granular cache is available in this context.
    var hasGranularCache: Bool {
        granularCache != nil
    }
}

/// TaskLocal storage for unified batch context.
///
/// Replaces individual storages:
/// - `PreFetchedVersionsStorage`
/// - `PreFetchedComponentsStorage`
/// - `SharedGranularCacheStorage`
/// - `PreFetchedNodesStorage`
///
/// ## Usage in Batch Mode
///
/// ```swift
/// let context = BatchContext(versions: ..., components: ..., granularCache: ..., nodes: ...)
/// await BatchContextStorage.$context.withValue(context) {
///     // All configs executed here can access batch data
/// }
/// ```
///
/// ## Usage in Consumers
///
/// ```swift
/// // Check for batch mode
/// if BatchContextStorage.context?.isBatchMode == true { ... }
///
/// // Access specific data
/// if let versions = BatchContextStorage.context?.versions { ... }
/// if let components = BatchContextStorage.context?.components { ... }
/// if let cache = BatchContextStorage.context?.granularCache { ... }
/// if let nodes = BatchContextStorage.context?.nodes { ... }
/// ```
enum BatchContextStorage {
    @TaskLocal static var context: BatchContext?
}
