// swiftlint:disable cyclomatic_complexity
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

extension ExFigCommand {
    struct ExportImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "images",
            abstract: "Exports images from Figma",
            discussion: "Exports images from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: HeavyFaultToleranceOptions

        @Argument(
            help: """
            [Optional] Name of the images to export. For example \"img/login\" to export \
            single image, \"img/onboarding/1, img/onboarding/2\" to export several images \
            and \"img/onboarding/*\" to export all images from onboarding group
            """
        )
        var filter: String?

        @Option(name: .long, help: "Path to write JSON report")
        var report: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(
                verbose: globalOptions.verbose, quiet: globalOptions.quiet
            )
            ExFigCommand.checkSchemaVersionIfNeeded()
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma?.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            let hasReport = report != nil
            let warningCollector: WarningCollector? = hasReport ? WarningCollector() : nil
            let manifestTracker: ManifestTracker? = hasReport ? ManifestTracker(assetType: "image") : nil
            if let collector = warningCollector { WarningCollectorStorage.current = collector }
            if let tracker = manifestTracker { ManifestTrackerStorage.current = tracker }

            let startTime = Date()
            var exportCount = 0
            var exportError: (any Error)?

            do {
                exportCount = try await performExport(client: client, ui: ui)
            } catch {
                exportError = error
            }

            if let reportPath = report {
                let endTime = Date()
                let warnings = await warningCollector?.getAll() ?? []
                let manifest = await manifestTracker?.buildManifest(previousReportPath: reportPath)
                WarningCollectorStorage.current = nil
                ManifestTrackerStorage.current = nil

                let exportReport = ExportReport(
                    version: ExportReport.currentVersion,
                    command: "images",
                    config: options.input ?? "exfig.pkl",
                    startTime: ISO8601DateFormatter().string(from: startTime),
                    endTime: ISO8601DateFormatter().string(from: endTime),
                    duration: endTime.timeIntervalSince(startTime),
                    success: exportError == nil,
                    error: exportError?.localizedDescription,
                    stats: ReportStats(colors: 0, icons: 0, images: exportCount, typography: 0),
                    warnings: warnings,
                    manifest: manifest
                )
                writeExportReport(exportReport, to: reportPath, ui: ui)
            } else {
                WarningCollectorStorage.current = nil
                ManifestTrackerStorage.current = nil
            }

            if let error = exportError {
                throw error
            }
        }

        /// Result of images export for batch mode integration.
        struct ImagesExportResult {
            let count: Int
            let computedHashes: [String: [String: String]]
            let granularCacheStats: GranularCacheStats?
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported images.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: The number of images exported.
        func performExport(
            client: Client,
            ui: TerminalUI
        ) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui, context: nil)
            return result.count
        }

        /// Performs export and returns full result with hashes for batch mode.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        ///   - context: Optional per-config execution context (passed explicitly in batch mode).
        /// - Returns: Export result including count, hashes, and granular cache stats.
        func performExportWithResult( // swiftlint:disable:this function_body_length
            client: Client,
            ui: TerminalUI,
            context: ConfigExecutionContext? = nil
        ) async throws -> ImagesExportResult {
            // Detect batch mode via BatchSharedState (single TaskLocal)
            let batchState = BatchSharedState.current
            let batchMode = batchState?.isBatchMode ?? false

            // Check for version changes if cache is enabled
            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client,
                    params: options.params,
                    cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Images",
                    ui: ui,
                    logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return ImagesExportResult(
                    count: 0, computedHashes: [:], granularCacheStats: nil, fileVersions: nil
                )
            }

            // Setup granular cache
            let configCacheEnabled = options.params.common?.cache?.isEnabled ?? false
            let granularCacheSetup = try GranularCacheHelper.setup(
                trackingManager: trackingManager,
                cacheOptions: cacheOptions,
                configCacheEnabled: configCacheEnabled,
                params: options.params,
                ui: ui
            )
            let granularCacheEnabled = granularCacheSetup.enabled
            let granularCacheManager = granularCacheSetup.manager

            var totalImages = 0
            var totalSkipped = 0
            var allComputedHashes: [String: [NodeId: String]] = [:]

            if options.params.ios != nil {
                // Suppress version message in batch mode
                if BatchSharedState.current?.progressView == nil {
                    ui.info(
                        "Using ExFig \(ExFigCommand.version) to export images to Xcode project."
                    )
                }
                let result = try await exportiOSImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if options.params.android != nil {
                // Suppress version message in batch mode
                if BatchSharedState.current?.progressView == nil {
                    ui.info(
                        "Using ExFig \(ExFigCommand.version) to export images to Android Studio project."
                    )
                }
                let result = try await exportAndroidImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if options.params.flutter != nil {
                // Suppress version message in batch mode
                if BatchSharedState.current?.progressView == nil {
                    ui.info(
                        "Using ExFig \(ExFigCommand.version) to export images to Flutter project."
                    )
                }
                let result = try await exportFlutterImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if options.params.web != nil {
                // Suppress version message in batch mode
                if BatchSharedState.current?.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export images to Web project.")
                }
                let result = try await exportWebImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            // Update cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(
                manager: trackingManager, versions: fileVersions
            )

            // Update granular cache node hashes (no-op in batch mode)
            if granularCacheEnabled {
                for (fileId, hashes) in allComputedHashes where !hashes.isEmpty {
                    try trackingManager.updateNodeHashes(fileId: fileId, hashes: hashes)
                }
            }

            // Convert NodeId keys to String for batch result
            let stringHashes = HashMerger.convertToStringKeys(allComputedHashes)

            // Build granular cache stats if granular cache was used
            let stats: GranularCacheStats? =
                granularCacheEnabled && (totalImages > 0 || totalSkipped > 0)
                    ? GranularCacheStats(skipped: totalSkipped, exported: totalImages)
                    : nil

            return ImagesExportResult(
                count: totalImages,
                computedHashes: stringHashes,
                granularCacheStats: stats,
                fileVersions: batchMode ? fileVersions : nil
            )
        }
    }
}
