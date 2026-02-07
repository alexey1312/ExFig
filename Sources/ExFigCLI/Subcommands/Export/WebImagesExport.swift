import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Web Images Export

extension ExFigCommand.ExportImages {
    /// Exports Web images via plugin architecture.
    ///
    /// For multiple entries, uses ComponentPreFetcher to optimize Figma API calls.
    func exportWebImages(
        client: Client,
        params: PKLConfig,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let web = params.web,
              let imagesConfig = web.images
        else {
            ui.warning(.configMissing(platform: "web", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let entries = imagesConfig

        // Multiple entries - pre-fetch Components once for all entries
        if entries.count > 1 {
            return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                client: client,
                params: params
            ) {
                try await exportWebImagesViaPlugin(
                    entries: entries,
                    web: web,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }
        }

        // Single or no entries - direct export
        return try await exportWebImagesViaPlugin(
            entries: entries,
            web: web,
            client: client,
            params: params,
            ui: ui,
            granularCacheManager: granularCacheManager
        )
    }
}
