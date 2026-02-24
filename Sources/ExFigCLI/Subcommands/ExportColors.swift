import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

extension ExFigCommand {
    struct ExportColors: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Exports colors from Figma",
            discussion:
            "Exports light and dark color palette from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        @Argument(
            help: """
            [Optional] Name of the colors to export. For example \"background/default\" \
            to export single color, \"background/default, background/secondary\" to export several colors and \
            \"background/*\" to export all colors from the folder.
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
            let manifestTracker: ManifestTracker? = hasReport ? ManifestTracker(assetType: "color") : nil
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
                    command: "colors",
                    config: options.input ?? "exfig.pkl",
                    startTime: ISO8601DateFormatter().string(from: startTime),
                    endTime: ISO8601DateFormatter().string(from: endTime),
                    duration: endTime.timeIntervalSince(startTime),
                    success: exportError == nil,
                    error: exportError?.localizedDescription,
                    stats: ReportStats(colors: exportCount, icons: 0, images: 0, typography: 0),
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

        /// Export result for batch mode (includes file versions for deferred cache save).
        struct ColorsExportResult {
            let count: Int
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported colors.
        func performExport(client: Client, ui: TerminalUI) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui, context: nil)
            return result.count
        }

        // swiftlint:disable:next cyclomatic_complexity function_body_length
        /// Performs export and returns full result with file versions for batch mode.
        /// - Parameters:
        ///   - client: Figma API client.
        ///   - ui: Terminal UI for output.
        ///   - context: Optional per-config execution context (passed explicitly in batch mode).
        func performExportWithResult(
            client: Client,
            ui: TerminalUI,
            context: ConfigExecutionContext? = nil
        ) async throws -> ColorsExportResult {
            // Detect batch mode via BatchSharedState (single TaskLocal)
            let batchState = BatchSharedState.current
            let batchMode = batchState?.isBatchMode ?? false

            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client, params: options.params, cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Colors", ui: ui, logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return ColorsExportResult(count: 0, fileVersions: nil)
            }

            // In batch mode, progress view is accessed via BatchSharedState
            if batchState?.progressView == nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export colors.")
            }

            var totalCount = 0

            // Platform routing: hardcoded dispatch (PluginRegistry is available but not used for dispatch yet)
            if let ios = options.params.ios, let colors = ios.colors {
                totalCount += try await exportiOSColorsViaPlugin(
                    entries: colors, ios: ios, client: client, ui: ui
                )
            }

            if let android = options.params.android, let colors = android.colors {
                totalCount += try await exportAndroidColorsViaPlugin(
                    entries: colors, android: android, client: client, ui: ui
                )
            }

            if let flutter = options.params.flutter, let colors = flutter.colors {
                totalCount += try await exportFlutterColorsViaPlugin(
                    entries: colors, flutter: flutter, client: client, ui: ui
                )
            }

            if let web = options.params.web, let colors = web.colors {
                totalCount += try await exportWebColorsViaPlugin(
                    entries: colors, web: web, client: client, ui: ui
                )
            }

            // Update file version cache after successful export (deferred in batch mode)
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Return file versions only in batch mode (for deferred batch-level cache save)
            return ColorsExportResult(count: totalCount, fileVersions: batchMode ? fileVersions : nil)
        }
    }
}
