import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation

extension ExFigCommand {
    struct ExportTypography: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "typography",
            abstract: "Exports typography from Figma",
            discussion: "Exports font styles from Figma to Xcode",
            aliases: ["text-styles"]
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        @Option(name: .long, help: "Path to write JSON report")
        var report: String?

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

            try await withExportReport(
                command: "typography",
                assetType: "typography",
                reportPath: report,
                configInput: options.input,
                ui: ui,
                buildStats: { .typography($0) },
                export: { try await performExport(client: client, ui: ui) }
            )
        }

        /// Export result for batch mode (includes file versions for deferred cache save).
        struct TypographyExportResult {
            let count: Int
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported text styles.
        func performExport(client: Client, ui: TerminalUI) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui, context: nil)
            return result.count
        }

        /// Performs export and returns full result with file versions for batch mode.
        /// - Parameters:
        ///   - client: Figma API client.
        ///   - ui: Terminal UI for output.
        ///   - context: Optional per-config execution context (passed explicitly in batch mode).
        func performExportWithResult( // swiftlint:disable:this function_body_length
            client: Client,
            ui: TerminalUI,
            context: ConfigExecutionContext? = nil
        ) async throws -> TypographyExportResult {
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
                    assetType: "Typography",
                    ui: ui,
                    logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return TypographyExportResult(count: 0, fileVersions: nil)
            }

            // Suppress version message in batch mode (check via BatchSharedState)
            if batchState?.progressView == nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export typography.")
            }

            var totalCount = 0
            let input = TypographyExportInput(
                figma: options.params.figma,
                common: options.params.common,
                client: client,
                ui: ui
            )

            // Export iOS typography via plugin
            if let ios = options.params.ios,
               let typographyEntry = ios.typography
            {
                let count = try await exportiOSTypographyViaPlugin(
                    entry: typographyEntry,
                    ios: ios,
                    input: input
                )
                totalCount += count
            }

            // Export Android typography via plugin
            if let android = options.params.android,
               let typographyEntry = android.typography
            {
                let count = try await exportAndroidTypographyViaPlugin(
                    entry: typographyEntry,
                    android: android,
                    input: input
                )
                totalCount += count
            }

            // Update cache after successful export (deferred in batch mode)
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Return file versions only in batch mode (for deferred batch-level cache save)
            return TypographyExportResult(count: totalCount, fileVersions: batchMode ? fileVersions : nil)
        }
    }
}
