import FigmaAPI
import Foundation

/// Helper for pre-fetching Figma components when processing multiple entries.
/// Avoids redundant API calls by fetching components once.
///
/// ## Linux Crash Fix
///
/// Previously this used nested `TaskLocal.withValue()` which caused Swift runtime crash on Linux:
/// `freed pointer was not the last allocation` (https://github.com/swiftlang/swift/issues/75501)
///
/// The fix uses `BatchSharedState` actor's `setLocalComponents()` method instead,
/// avoiding nested TaskLocal scopes entirely.
enum ComponentPreFetcher {
    /// Pre-fetches components if not already available and executes the process closure.
    ///
    /// **Important:** This method does NOT create nested TaskLocal scopes.
    /// Instead, it updates `BatchSharedState.current` actor's local components.
    ///
    /// - Parameters:
    ///   - client: Figma API client.
    ///   - params: Export parameters containing file IDs.
    ///   - process: Async closure to execute with pre-fetched components available.
    /// - Returns: Result from the process closure.
    static func withPreFetchedComponentsIfNeeded<T>(
        client: Client,
        params: PKLConfig,
        process: () async throws -> T
    ) async throws -> T {
        // Check if we need to pre-fetch components
        let batchState = BatchSharedState.current

        // Collect file IDs that need components
        let fileIds = Set(
            (params.figma?.lightFileId.flatMap { [$0] } ?? []) +
                (params.figma?.darkFileId.flatMap { [$0] } ?? [])
        )

        // Fetch components for files that don't have them yet
        var componentsMap: [String: [Component]] = [:]

        for fileId in fileIds {
            // Skip if already have components for this file
            if let state = batchState, await state.hasComponents(for: fileId) {
                continue
            }
            let components = try await client.request(ComponentsEndpoint(fileId: fileId))
            componentsMap[fileId] = components
        }

        // If in batch mode, store in actor (no nested withValue!)
        if let state = batchState, !componentsMap.isEmpty {
            let preFetched = PreFetchedComponents(components: componentsMap)
            await state.setLocalComponents(preFetched)
        }

        // Execute process - components are now available via BatchSharedState.current
        return try await process()
    }

    /// Pre-fetches components without closure wrapper.
    ///
    /// Use this when you need to pre-fetch and then access components directly.
    /// Returns the pre-fetched components map.
    ///
    /// - Parameters:
    ///   - client: Figma API client.
    ///   - params: Export parameters containing file IDs.
    /// - Returns: Pre-fetched components, or nil if all were already cached.
    static func preFetchComponents(
        client: Client,
        params: PKLConfig
    ) async throws -> PreFetchedComponents? {
        let fileIds = Set(
            (params.figma?.lightFileId.flatMap { [$0] } ?? []) +
                (params.figma?.darkFileId.flatMap { [$0] } ?? [])
        )

        guard !fileIds.isEmpty else { return nil }

        var componentsMap: [String: [Component]] = [:]

        for fileId in fileIds {
            // Skip if already have components in batch state
            if let state = BatchSharedState.current, await state.hasComponents(for: fileId) {
                continue
            }
            let components = try await client.request(ComponentsEndpoint(fileId: fileId))
            componentsMap[fileId] = components
        }

        guard !componentsMap.isEmpty else { return nil }
        return PreFetchedComponents(components: componentsMap)
    }
}
