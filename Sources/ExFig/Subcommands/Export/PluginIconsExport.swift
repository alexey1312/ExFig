import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// swiftlint:disable function_parameter_count

// MARK: - Plugin-based Icons Export

extension ExFigCommand.ExportIcons {
    /// Exports iOS icons using plugin architecture.
    ///
    /// This method uses `iOSIconsExporter` from the plugin system. For granular
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
    func exportiOSIconsViaPlugin(
        entries: [Params.iOS.IconsEntry],
        ios: Params.iOS,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry() }
        let platformConfig = ios.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = IconsExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .ios
        )

        // Export via plugin
        let exporter = iOSIconsExporter()
        let count = try await exporter.exportIcons(
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

        return PlatformExportResult(count: count, hashes: [:], skippedCount: 0)
    }

    /// Exports Android icons using plugin architecture.
    func exportAndroidIconsViaPlugin(
        entries: [Params.Android.IconsEntry],
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry() }
        let platformConfig = android.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = IconsExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .android
        )

        let exporter = AndroidIconsExporter()
        let count = try await exporter.exportIcons(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return PlatformExportResult(count: count, hashes: [:], skippedCount: 0)
    }

    /// Exports Flutter icons using plugin architecture.
    func exportFlutterIconsViaPlugin(
        entries: [Params.Flutter.IconsEntry],
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry() }
        let platformConfig = flutter.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = IconsExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .flutter
        )

        let exporter = FlutterIconsExporter()
        let count = try await exporter.exportIcons(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return PlatformExportResult(count: count, hashes: [:], skippedCount: 0)
    }

    /// Exports Web icons using plugin architecture.
    func exportWebIconsViaPlugin(
        entries: [Params.Web.IconsEntry],
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let pluginEntries = entries.map { $0.toPluginEntry() }
        let platformConfig = web.platformConfig()

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        let context = IconsExportContextImpl(
            client: client,
            ui: ui,
            params: params,
            filter: filter,
            isBatchMode: batchMode,
            fileDownloader: fileDownloader,
            granularCacheManager: granularCacheManager,
            platform: .web
        )

        let exporter = WebIconsExporter()
        let count = try await exporter.exportIcons(
            entries: pluginEntries,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return PlatformExportResult(count: count, hashes: [:], skippedCount: 0)
    }
}

// swiftlint:enable function_parameter_count
