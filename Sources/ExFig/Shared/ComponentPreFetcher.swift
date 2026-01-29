import FigmaAPI
import Foundation

/// Helper for pre-fetching Figma components when processing multiple entries.
/// Avoids redundant API calls by fetching components once and injecting via TaskLocal.
enum ComponentPreFetcher {
    /// Pre-fetches components if not already available and executes the process closure.
    /// - Parameters:
    ///   - client: Figma API client.
    ///   - params: Export parameters containing file IDs.
    ///   - process: Async closure to execute with pre-fetched components available.
    /// - Returns: Result from the process closure.
    static func withPreFetchedComponentsIfNeeded<T>(
        client: Client,
        params: Params,
        process: () async throws -> T
    ) async throws -> T {
        let needsLocalPreFetch = PreFetchedComponentsStorage.components == nil

        if needsLocalPreFetch {
            var componentsMap: [String: [Component]] = [:]
            let fileIds = Set(
                (params.figma?.lightFileId.flatMap { [$0] } ?? []) +
                    (params.figma?.darkFileId.flatMap { [$0] } ?? [])
            )

            for fileId in fileIds {
                let components = try await client.request(ComponentsEndpoint(fileId: fileId))
                componentsMap[fileId] = components
            }

            let preFetched = PreFetchedComponents(components: componentsMap)

            return try await PreFetchedComponentsStorage.$components.withValue(preFetched) {
                try await process()
            }
        } else {
            return try await process()
        }
    }
}
