import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// swiftlint:disable function_parameter_count

// MARK: - Plugin-based Images Export

extension ExFigCommand.ExportImages {
    /// Exports iOS images using plugin architecture.
    ///
    /// This method uses `iOSImagesExporter` from the plugin system. For granular
    /// cache support, the context internally routes to cache-aware loading.
    ///
    /// - Parameters:
    ///   - entries: Params entries to convert and export.
    ///   - ios: iOS platform configuration from Params.
    ///   - client: Figma API client.
    ///   - params: Full params for context creation.
    ///   - ui: Terminal UI for output.
    ///   - granularCacheManager: Optional granular cache manager.
    /// - Returns: Platform export result with count and hashes.
    func exportiOSImagesViaPlugin(
        entries: [Params.iOS.ImagesEntry],
        ios: Params.iOS,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry(common: params.common) }
        let platformConfig = ios.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = ImagesExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .ios
        )

        // Export via plugin (returns ImagesExportResult with hashes)
        let exporter = iOSImagesExporter()
        let result = try await exporter.exportImages(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        // Post-export: update Xcode project (only if not in Swift Package)
        if ios.xcassetsInSwiftPackage != true {
            do {
                let xcodeProject = try XcodeProjectWriter(
                    xcodeProjPath: ios.xcodeprojPath,
                    target: ios.target
                )
                for entry in pluginEntries {
                    if let imageSwift = entry.imageSwift {
                        try xcodeProject.addFileReferenceToXcodeProj(imageSwift)
                    }
                    if let swiftUIImageSwift = entry.swiftUIImageSwift {
                        try xcodeProject.addFileReferenceToXcodeProj(swiftUIImageSwift)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning(.xcodeProjectUpdateFailed)
            }
        }

        // Check for updates (only in standalone mode)
        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return result.toPlatformExportResult()
    }

    /// Exports Android images using plugin architecture.
    func exportAndroidImagesViaPlugin(
        entries: [Params.Android.ImagesEntry],
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry(common: params.common) }
        let platformConfig = android.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = ImagesExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .android
        )

        let exporter = AndroidImagesExporter()
        let result = try await exporter.exportImages(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return result.toPlatformExportResult()
    }

    /// Exports Flutter images using plugin architecture.
    func exportFlutterImagesViaPlugin(
        entries: [Params.Flutter.ImagesEntry],
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry(common: params.common) }
        let platformConfig = flutter.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = ImagesExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .flutter
        )

        let exporter = FlutterImagesExporter()
        let result = try await exporter.exportImages(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return result.toPlatformExportResult()
    }

    /// Exports Web images using plugin architecture.
    func exportWebImagesViaPlugin(
        entries: [Params.Web.ImagesEntry],
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry(common: params.common) }
        let platformConfig = web.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = ImagesExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .web
        )

        let exporter = WebImagesExporter()
        let result = try await exporter.exportImages(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return result.toPlatformExportResult()
    }
}

// MARK: - ImagesExportResult Extension

extension ImagesExportResult {
    /// Converts to CLI's PlatformExportResult format.
    func toPlatformExportResult() -> PlatformExportResult {
        PlatformExportResult(
            count: count,
            hashes: computedHashes,
            skippedCount: skippedCount
        )
    }
}

// swiftlint:enable function_parameter_count
