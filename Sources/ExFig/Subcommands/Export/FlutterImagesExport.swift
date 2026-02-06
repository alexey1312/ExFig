import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Flutter Images Export

extension ExFigCommand.ExportImages {
    /// Exports Flutter images via plugin architecture.
    ///
    /// For multiple entries, uses ComponentPreFetcher to optimize Figma API calls.
    func exportFlutterImages(
        client: Client,
        params: PKLConfig,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let flutter = params.flutter,
              let imagesConfig = flutter.images
        else {
            ui.warning(.configMissing(platform: "flutter", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let entries = imagesConfig.entries

        // Multiple entries - pre-fetch Components once for all entries
        if entries.count > 1 {
            return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                client: client,
                params: params
            ) {
                try await exportFlutterImagesViaPlugin(
                    entries: entries,
                    flutter: flutter,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }
        }

        // Single or no entries - direct export
        return try await exportFlutterImagesViaPlugin(
            entries: entries,
            flutter: flutter,
            client: client,
            params: params,
            ui: ui,
            granularCacheManager: granularCacheManager
        )
    }
}
