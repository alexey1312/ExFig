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
            """)
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(
                verbose: globalOptions.verbose, quiet: globalOptions.quiet
            )
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma?.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            _ = try await performExport(client: client, ui: ui)
        }

        /// Export result for batch mode (includes file versions for deferred cache save).
        struct ColorsExportResult {
            let count: Int
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported colors.
        func performExport(client: Client, ui: TerminalUI) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui)
            return result.count
        }

        // swiftlint:disable:next cyclomatic_complexity function_body_length
        /// Performs export and returns full result with file versions for batch mode.
        func performExportWithResult(client: Client, ui: TerminalUI) async throws -> ColorsExportResult {
            // Detect batch mode via TaskLocal (batch context presence)
            let batchMode = BatchContextStorage.context?.isBatchMode ?? false

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

            if BatchProgressViewStorage.progressView == nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export colors.")
            }

            let legacyConfig = LegacyExportConfig(
                commonParams: options.params.common, figmaParams: options.params.figma, client: client, ui: ui
            )
            var totalCount = 0

            if let ios = options.params.ios, let colors = ios.colors {
                totalCount += try await (colors.isMultiple
                    ? exportiOSColorsMultiple(entries: colors.entries, ios: ios, client: client, ui: ui)
                    : exportiOSColorsLegacy(colorsConfig: colors, ios: ios, config: legacyConfig))
            }

            if let android = options.params.android, let colors = android.colors {
                totalCount += try await (colors.isMultiple
                    ? exportAndroidColorsMultiple(entries: colors.entries, android: android, client: client, ui: ui)
                    : exportAndroidColorsLegacy(colorsConfig: colors, android: android, config: legacyConfig))
            }

            if let flutter = options.params.flutter, let colors = flutter.colors {
                totalCount += try await (colors.isMultiple
                    ? exportFlutterColorsMultiple(entries: colors.entries, flutter: flutter, client: client, ui: ui)
                    : exportFlutterColorsLegacy(colorsConfig: colors, flutter: flutter, config: legacyConfig))
            }

            if let web = options.params.web, let colors = web.colors {
                totalCount += try await (colors.isMultiple
                    ? exportWebColorsMultiple(entries: colors.entries, web: web, client: client, ui: ui)
                    : exportWebColorsLegacy(colorsConfig: colors, web: web, config: legacyConfig))
            }

            // Update file version cache after successful export (deferred in batch mode)
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Return file versions only in batch mode (for deferred batch-level cache save)
            return ColorsExportResult(count: totalCount, fileVersions: batchMode ? fileVersions : nil)
        }

        // MARK: - Legacy Export Configuration

        /// Configuration for legacy colors export (using common.variablesColors or common.colors).
        struct LegacyExportConfig {
            let commonParams: Params.Common?
            let figmaParams: Params.Figma?
            let client: Client
            let ui: TerminalUI
        }

        // MARK: - Legacy Helper Methods

        /// Validates that both common.colors and common.variablesColors are not set at the same time.
        func validateLegacyConfig(_ commonParams: Params.Common?) throws {
            if commonParams?.colors != nil, commonParams?.variablesColors != nil {
                throw ExFigError.custom(
                    errorString:
                    "In the configuration file, you can use "
                        + "either the common/colors or common/variablesColors parameter"
                )
            }
        }

        /// Loads colors from Figma using either Variables API or legacy Styles API.
        func loadLegacyColors(config: LegacyExportConfig) async throws -> ColorsLoaderOutput {
            try await config.ui.withSpinner("Fetching colors from Figma...") {
                if let variableParams = config.commonParams?.variablesColors {
                    let loader = ColorsVariablesLoader(
                        client: config.client,
                        variableParams: variableParams,
                        filter: filter
                    )
                    return try await loader.load()
                } else {
                    guard let figmaParams = config.figmaParams else {
                        throw ExFigError.custom(errorString:
                            "figma section is required for legacy Styles API colors export. " +
                                "Use common.variablesColors for Variables API instead."
                        )
                    }
                    let loader = ColorsLoader(
                        client: config.client,
                        figmaParams: figmaParams,
                        colorParams: config.commonParams?.colors,
                        filter: filter
                    )
                    return try await loader.load()
                }
            }
        }

        /// Extracts name validation and replacement regexps from common params.
        func extractNameRegexps(
            from commonParams: Params.Common?
        ) -> (validate: String?, replace: String?) {
            if let variableParams = commonParams?.variablesColors {
                return (variableParams.nameValidateRegexp, variableParams.nameReplaceRegexp)
            }
            return (commonParams?.colors?.nameValidateRegexp, commonParams?.colors?.nameReplaceRegexp)
        }
    }
}
