import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Android Images Export

extension ExFigCommand.ExportImages {
    /// Exports Android images via plugin architecture.
    ///
    /// For multiple entries, uses ComponentPreFetcher to optimize Figma API calls.
    func exportAndroidImages(
        client: Client,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let android = params.android,
              let imagesConfig = android.images
        else {
            ui.warning(.configMissing(platform: "android", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let entries = imagesConfig.entries

        // Multiple entries - pre-fetch Components once for all entries
        if entries.count > 1 {
            return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                client: client,
                params: params
            ) {
                try await exportAndroidImagesViaPlugin(
                    entries: entries,
                    android: android,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }
        }

        // Single or no entries - direct export
        return try await exportAndroidImagesViaPlugin(
            entries: entries,
            android: android,
            client: client,
            params: params,
            ui: ui,
            granularCacheManager: granularCacheManager
        )
    }
}
