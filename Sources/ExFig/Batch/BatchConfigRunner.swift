import FigmaAPI
import Foundation

protocol ConfigExportPerforming: Sendable {
    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats
}

struct SubcommandConfigExporter: ConfigExportPerforming {
    let globalOptions: GlobalOptions
    let resume: Bool
    let cache: Bool
    let noCache: Bool
    let force: Bool
    let cachePath: String?
    let experimentalGranularCache: Bool
    let concurrentDownloads: Int

    /// Config execution context with per-config data (passed explicitly, no TaskLocal nesting).
    let configContext: ConfigExecutionContext

    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        // No nested withValue calls - all context comes from:
        // 1. BatchSharedState.current (single TaskLocal)
        // 2. configContext (passed explicitly)
        // 3. client (passed as parameter)
        try await runExports(options: options, client: client, ui: ui)
    }

    private func runExports(
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        let cacheOpts = makeCacheOptions()
        let faultTolerance = FaultToleranceOptions()
        let heavyFaultTolerance = makeHeavyFaultToleranceOptions()
        let params = options.params

        var stats = ExportStats.zero

        // Colors export
        if hasColorsConfig(params) {
            let cmd = makeColors(options: options, cacheOptions: cacheOpts, faultToleranceOptions: faultTolerance)
            let result = try await cmd.performExportWithResult(
                client: client,
                ui: ui,
                context: configContext.with(assetType: .colors)
            )
            stats += ExportStats(colors: result.count, fileVersions: result.fileVersions)
        }

        // Icons export
        if hasIconsConfig(params) {
            let cmd = makeIcons(options: options, cacheOptions: cacheOpts, faultToleranceOptions: heavyFaultTolerance)
            let result = try await cmd.performExportWithResult(
                client: client,
                ui: ui,
                context: configContext.with(assetType: .icons)
            )
            stats += ExportStats(
                icons: result.count,
                computedNodeHashes: result.computedHashes,
                granularCacheStats: result.granularCacheStats,
                fileVersions: result.fileVersions
            )
        }

        // Images export
        if hasImagesConfig(params) {
            let cmd = makeImages(options: options, cacheOptions: cacheOpts, faultToleranceOptions: heavyFaultTolerance)
            let result = try await cmd.performExportWithResult(
                client: client,
                ui: ui,
                context: configContext.with(assetType: .images)
            )
            stats += ExportStats(
                images: result.count,
                computedNodeHashes: result.computedHashes,
                granularCacheStats: result.granularCacheStats,
                fileVersions: result.fileVersions
            )
        }

        // Typography export
        if hasTypographyConfig(params) {
            let cmd = makeTypography(options: options, cacheOptions: cacheOpts, faultToleranceOptions: faultTolerance)
            let result = try await cmd.performExportWithResult(
                client: client,
                ui: ui,
                context: configContext.with(assetType: .typography)
            )
            stats += ExportStats(typography: result.count, fileVersions: result.fileVersions)
        }

        return stats
    }

    private func makeCacheOptions() -> CacheOptions {
        var options = CacheOptions()
        options.cache = cache
        options.noCache = noCache
        options.force = force
        options.cachePath = cachePath
        options.experimentalGranularCache = experimentalGranularCache
        return options
    }

    private func makeHeavyFaultToleranceOptions() -> HeavyFaultToleranceOptions {
        var options = HeavyFaultToleranceOptions()
        options.resume = resume
        options.concurrentDownloads = concurrentDownloads
        return options
    }

    // MARK: - Config Detection

    private func hasColorsConfig(_ params: Params?) -> Bool {
        guard let params else { return false }
        let hasColorSource = params.common?.colors != nil || params.common?.variablesColors != nil
        let hasColorOutput = params.ios?.colors != nil
            || params.android?.colors != nil
            || params.flutter?.colors != nil
        return hasColorSource || hasColorOutput
    }

    private func hasIconsConfig(_ params: Params?) -> Bool {
        guard let params else { return false }
        return params.ios?.icons != nil
            || params.android?.icons != nil
            || params.flutter?.icons != nil
    }

    private func hasImagesConfig(_ params: Params?) -> Bool {
        guard let params else { return false }
        return params.ios?.images != nil
            || params.android?.images != nil
            || params.flutter?.images != nil
    }

    private func hasTypographyConfig(_ params: Params?) -> Bool {
        guard let params else { return false }
        return params.ios?.typography != nil
            || params.android?.typography != nil
    }
}

struct BatchConfigRunner: Sendable {
    let rateLimiter: SharedRateLimiter
    let retryPolicy: RetryPolicy
    let globalOptions: GlobalOptions
    let maxRetries: Int
    let resume: Bool
    let cache: Bool
    let noCache: Bool
    let force: Bool
    let cachePath: String?
    let experimentalGranularCache: Bool
    let concurrentDownloads: Int
    /// CLI timeout override (in seconds). When set, overrides per-config YAML timeout.
    let cliTimeout: Int?
    /// Priority for this config's downloads (lower = higher priority, based on submission order).
    let configPriority: Int
    /// Test-only: injected exporter for unit testing.
    private let _testExporter: (any ConfigExportPerforming)?

    init(
        rateLimiter: SharedRateLimiter,
        retryPolicy: RetryPolicy,
        globalOptions: GlobalOptions,
        maxRetries: Int,
        resume: Bool,
        cache: Bool = false,
        noCache: Bool = false,
        force: Bool = false,
        cachePath: String? = nil,
        experimentalGranularCache: Bool = false,
        concurrentDownloads: Int = FileDownloader.defaultMaxConcurrentDownloads,
        cliTimeout: Int? = nil,
        configPriority: Int = 0,
        exporter: (any ConfigExportPerforming)? = nil
    ) {
        self.rateLimiter = rateLimiter
        self.retryPolicy = retryPolicy
        self.globalOptions = globalOptions
        self.maxRetries = maxRetries
        self.resume = resume
        self.cache = cache
        self.noCache = noCache
        self.force = force
        self.cachePath = cachePath
        self.experimentalGranularCache = experimentalGranularCache
        self.concurrentDownloads = concurrentDownloads
        self.cliTimeout = cliTimeout
        self.configPriority = configPriority
        _testExporter = exporter
    }

    // swiftlint:disable:next function_body_length
    func process(
        configFile: ConfigFile,
        ui: TerminalUI
    ) async -> ConfigResult {
        // Get progress view from BatchSharedState (if in batch mode)
        let progressView = BatchSharedState.current?.progressView

        // Start config in progress view or log to UI
        if let progressView {
            await progressView.startConfig(name: configFile.name)
        } else {
            ui.info("Processing: \(configFile.name)")
        }

        do {
            var options = ExFigOptions()
            options.input = configFile.url.path
            try options.validate()

            let retryHandler = RetryLogger.createHandler(ui: ui, maxAttempts: maxRetries)

            // CLI timeout takes precedence over per-config YAML timeout
            let effectiveTimeout: TimeInterval? = cliTimeout.map { TimeInterval($0) }
                ?? options.params.figma?.timeout

            let baseClient = FigmaClient(
                accessToken: options.accessToken,
                timeout: effectiveTimeout
            )

            let client = RateLimitedClient(
                client: baseClient,
                rateLimiter: rateLimiter,
                configID: ConfigID(configFile.name),
                retryPolicy: retryPolicy,
                onRetry: { attempt, error in
                    let delay = retryPolicy.delay(for: attempt - 1, error: error)
                    retryHandler(configFile.name, attempt, error, delay)
                }
            )

            // Create per-config execution context (passed explicitly, no TaskLocal nesting)
            let configContext = ConfigExecutionContext(
                configId: configFile.name,
                configPriority: configPriority
            )

            // Use test exporter if provided, otherwise create real exporter
            let exporter: any ConfigExportPerforming = _testExporter ?? SubcommandConfigExporter(
                globalOptions: globalOptions,
                resume: resume,
                cache: cache,
                noCache: noCache,
                force: force,
                cachePath: cachePath,
                experimentalGranularCache: experimentalGranularCache,
                concurrentDownloads: concurrentDownloads,
                configContext: configContext
            )

            // No nested withValue calls - context is passed explicitly
            let stats = try await exporter.export(
                configFile: configFile,
                options: options,
                client: client,
                ui: ui
            )

            // Update progress view with final counts or log success
            if let progressView {
                await progressView.updateProgress(
                    name: configFile.name,
                    colors: stats.colors > 0 ? (stats.colors, stats.colors) : nil,
                    icons: stats.icons > 0 ? (stats.icons, stats.icons) : nil,
                    images: stats.images > 0 ? (stats.images, stats.images) : nil,
                    typography: stats.typography > 0 ? (stats.typography, stats.typography) : nil
                )
                await progressView.succeedConfig(name: configFile.name)
            } else {
                ui.success("Completed: \(configFile.name)")
            }

            return .success(config: configFile, stats: stats)

        } catch {
            // Update progress view with failure or log error
            if let progressView {
                let errorMsg = String(error.localizedDescription.prefix(30))
                await progressView.failConfig(name: configFile.name, error: errorMsg)
            } else {
                ui.error("Failed: \(configFile.name)")
                ui.error(error)
            }
            return .failure(config: configFile, error: error)
        }
    }
}

private extension SubcommandConfigExporter {
    func makeColors(
        options: ExFigOptions,
        cacheOptions: CacheOptions,
        faultToleranceOptions: FaultToleranceOptions
    ) -> ExFigCommand.ExportColors {
        var cmd = ExFigCommand.ExportColors()
        cmd.globalOptions = globalOptions
        cmd.options = options
        cmd.cacheOptions = cacheOptions
        cmd.faultToleranceOptions = faultToleranceOptions
        cmd.filter = nil
        return cmd
    }

    func makeIcons(
        options: ExFigOptions,
        cacheOptions: CacheOptions,
        faultToleranceOptions: HeavyFaultToleranceOptions
    ) -> ExFigCommand.ExportIcons {
        var cmd = ExFigCommand.ExportIcons()
        cmd.globalOptions = globalOptions
        cmd.options = options
        cmd.cacheOptions = cacheOptions
        cmd.faultToleranceOptions = faultToleranceOptions
        cmd.filter = nil
        cmd.strictPathValidation = false
        return cmd
    }

    func makeImages(
        options: ExFigOptions,
        cacheOptions: CacheOptions,
        faultToleranceOptions: HeavyFaultToleranceOptions
    ) -> ExFigCommand.ExportImages {
        var cmd = ExFigCommand.ExportImages()
        cmd.globalOptions = globalOptions
        cmd.options = options
        cmd.cacheOptions = cacheOptions
        cmd.faultToleranceOptions = faultToleranceOptions
        cmd.filter = nil
        return cmd
    }

    func makeTypography(
        options: ExFigOptions,
        cacheOptions: CacheOptions,
        faultToleranceOptions: FaultToleranceOptions
    ) -> ExFigCommand.ExportTypography {
        var cmd = ExFigCommand.ExportTypography()
        cmd.globalOptions = globalOptions
        cmd.options = options
        cmd.cacheOptions = cacheOptions
        cmd.faultToleranceOptions = faultToleranceOptions
        return cmd
    }
}
