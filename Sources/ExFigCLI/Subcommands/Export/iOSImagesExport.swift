import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - iOS Images Export

extension ExFigCommand.ExportImages {
    /// Exports iOS images via plugin architecture.
    ///
    /// For multiple entries, uses ComponentPreFetcher to optimize Figma API calls.
    func exportiOSImages(
        client: Client,
        params: ExFig.ModuleImpl,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let ios = params.ios,
              let entries = ios.images, !entries.isEmpty
        else {
            ui.warning(.configMissing(platform: "ios", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        // Multiple entries - pre-fetch Components once for all entries
        if entries.count > 1 {
            return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                client: client,
                params: params
            ) {
                try await exportiOSImagesViaPlugin(
                    entries: entries,
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }
        }

        // Single or no entries - direct export
        return try await exportiOSImagesViaPlugin(
            entries: entries,
            ios: ios,
            client: client,
            params: params,
            ui: ui,
            granularCacheManager: granularCacheManager
        )
    }
}
