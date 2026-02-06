import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

extension ExFigCommand {
    struct ExportIcons: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "icons",
            abstract: "Exports icons from Figma",
            discussion: "Exports icons from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: HeavyFaultToleranceOptions

        @Argument(help: """
        [Optional] Name of the icons to export. For example \"ic/24/edit\" \
        to export single icon, \"ic/24/edit, ic/16/notification\" to export several icons and \
        \"ic/16/*\" to export all icons of size 16 pt
        """)
        var filter: String?

        @Flag(help: """
        Exit with error if any Android icon pathData exceeds 32,767 bytes (AAPT limit). \
        Overrides strictPathValidation in config. Default: only log warnings.
        """)
        var strictPathValidation: Bool = false

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            ExFigCommand.checkSchemaVersionIfNeeded()
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma?.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            _ = try await performExport(client: client, ui: ui)
        }

        /// Result of icons export for batch mode integration.
        struct IconsExportResult {
            let count: Int
            let computedHashes: [String: [String: String]]
            let granularCacheStats: GranularCacheStats?
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported icons.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: The number of icons exported.
        func performExport(
            client: Client,
            ui: TerminalUI
        ) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui, context: nil)
            return result.count
        }

        // swiftlint:disable function_body_length cyclomatic_complexity
        /// Performs export and returns full result with hashes for batch mode.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        ///   - context: Optional per-config execution context (passed explicitly in batch mode).
        /// - Returns: Export result including count, hashes, and granular cache stats.
        func performExportWithResult(
            client: Client,
            ui: TerminalUI,
            context: ConfigExecutionContext? = nil
        ) async throws -> IconsExportResult {
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
                    assetType: "Icons",
                    ui: ui,
                    logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return IconsExportResult(count: 0, computedHashes: [:], granularCacheStats: nil, fileVersions: nil)
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

            var totalIcons = 0
            var totalSkipped = 0
            var allComputedHashes: [String: [NodeId: String]] = [:]

            // Export icons via plugin architecture
            if let ios = options.params.ios, let iconsConfig = ios.icons {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Xcode project.")
                }
                let entries = iconsConfig.entries
                let result = try await withComponentPreFetchIfNeeded(
                    entries: entries,
                    client: client
                ) {
                    try await exportiOSIconsViaPlugin(
                        entries: entries,
                        ios: ios,
                        client: client,
                        params: options.params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
                totalIcons += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if let android = options.params.android, let iconsConfig = android.icons {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Android Studio project.")
                }
                let entries = iconsConfig.entries
                let result = try await withComponentPreFetchIfNeeded(
                    entries: entries,
                    client: client
                ) {
                    try await exportAndroidIconsViaPlugin(
                        entries: entries,
                        android: android,
                        client: client,
                        params: options.params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
                totalIcons += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if let flutter = options.params.flutter, let iconsConfig = flutter.icons {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Flutter project.")
                }
                let entries = iconsConfig.entries
                let result = try await withComponentPreFetchIfNeeded(
                    entries: entries,
                    client: client
                ) {
                    try await exportFlutterIconsViaPlugin(
                        entries: entries,
                        flutter: flutter,
                        client: client,
                        params: options.params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
                totalIcons += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            if let web = options.params.web, let iconsConfig = web.icons {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Web project.")
                }
                let entries = iconsConfig.entries
                let result = try await withComponentPreFetchIfNeeded(
                    entries: entries,
                    client: client
                ) {
                    try await exportWebIconsViaPlugin(
                        entries: entries,
                        web: web,
                        client: client,
                        params: options.params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
                totalIcons += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = HashMerger.merge(allComputedHashes, result.hashes)
            }

            // Update file version cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Update node hashes for granular cache (no-op in batch mode)
            if granularCacheEnabled {
                for (fileId, hashes) in allComputedHashes where !hashes.isEmpty {
                    try trackingManager.updateNodeHashes(fileId: fileId, hashes: hashes)
                }
            }

            // Convert NodeId keys to String for batch result
            let stringHashes = HashMerger.convertToStringKeys(allComputedHashes)

            // Build granular cache stats if granular cache was used
            let stats: GranularCacheStats? = granularCacheEnabled && (totalIcons > 0 || totalSkipped > 0)
                ? GranularCacheStats(skipped: totalSkipped, exported: totalIcons)
                : nil

            return IconsExportResult(
                count: totalIcons,
                computedHashes: stringHashes,
                granularCacheStats: stats,
                fileVersions: batchMode ? fileVersions : nil
            )
        }

        // swiftlint:enable function_body_length cyclomatic_complexity

        // MARK: - Helpers

        /// Wraps export operation in ComponentPreFetcher if multiple entries exist.
        ///
        /// For single entry, executes directly. For multiple entries, pre-fetches
        /// Figma components once to avoid redundant API calls.
        private func withComponentPreFetchIfNeeded<T>(
            entries: [some Any],
            client: Client,
            process: () async throws -> T
        ) async throws -> T {
            if entries.count > 1 {
                try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
                    client: client,
                    params: options.params,
                    process: process
                )
            } else {
                try await process()
            }
        }
    }
}
