/// Protocol for types that provide Figma file IDs for version tracking.
///
/// Implementing this protocol ensures that all file IDs used by a configuration
/// are included in version tracking, preventing cache misses when only some
/// files change.
///
/// ## Usage
///
/// Each configuration type that references Figma files should implement this protocol.
/// The aggregating implementation in `Params` collects all file IDs from nested configs.
///
/// ## Adding New File ID Sources
///
/// When adding a new configuration that uses Figma file IDs:
/// 1. Implement `FileIdProvider` for the new configuration type
/// 2. Add the new source to `Params.getFileIds()` aggregation
/// 3. Add test cases for the new configuration
protocol FileIdProvider {
    /// Returns all unique Figma file IDs used by this configuration.
    func getFileIds() -> Set<String>
}
