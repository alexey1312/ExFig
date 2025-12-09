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

    // swiftlint:disable:next function_body_length
    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        try await InjectedClientStorage.$client.withValue(client) {
            let cacheOptions = makeCacheOptions()
            let faultToleranceOptions = FaultToleranceOptions()
            let heavyFaultToleranceOptions = makeHeavyFaultToleranceOptions()

            let params = options.params
            var colorsCount = 0
            var iconsCount = 0
            var imagesCount = 0
            var typographyCount = 0
            var allComputedHashes: [String: [String: String]] = [:]
            var allGranularStats: GranularCacheStats?
            var allFileVersions: [String: FileVersionInfo] = [:]

            // Only run exports for configured asset types
            if hasColorsConfig(params) {
                let colors = makeColors(
                    options: options,
                    cacheOptions: cacheOptions,
                    faultToleranceOptions: faultToleranceOptions
                )
                colorsCount = try await colors.performExport(client: client, ui: ui)
            }

            if hasIconsConfig(params) {
                let icons = makeIcons(
                    options: options,
                    cacheOptions: cacheOptions,
                    faultToleranceOptions: heavyFaultToleranceOptions
                )
                let result = try await icons.performExportWithResult(client: client, ui: ui)
                iconsCount = result.count
                allComputedHashes = mergeHashes(allComputedHashes, result.computedHashes)
                allGranularStats = GranularCacheStats.merge(allGranularStats, result.granularCacheStats)
                // Collect file versions
                if let versions = result.fileVersions {
                    for version in versions {
                        allFileVersions[version.fileId] = version
                    }
                }
            }

            if hasImagesConfig(params) {
                let images = makeImages(
                    options: options,
                    cacheOptions: cacheOptions,
                    faultToleranceOptions: heavyFaultToleranceOptions
                )
                let result = try await images.performExportWithResult(client: client, ui: ui)
                imagesCount = result.count
                allComputedHashes = mergeHashes(allComputedHashes, result.computedHashes)
                allGranularStats = GranularCacheStats.merge(allGranularStats, result.granularCacheStats)
                // Collect file versions
                if let versions = result.fileVersions {
                    for version in versions {
                        allFileVersions[version.fileId] = version
                    }
                }
            }

            if hasTypographyConfig(params) {
                let typography = makeTypography(
                    options: options,
                    cacheOptions: cacheOptions,
                    faultToleranceOptions: faultToleranceOptions
                )
                typographyCount = try await typography.performExport(client: client, ui: ui)
            }

            return ExportStats(
                colors: colorsCount,
                icons: iconsCount,
                images: imagesCount,
                typography: typographyCount,
                computedNodeHashes: allComputedHashes,
                granularCacheStats: allGranularStats,
                fileVersions: allFileVersions.isEmpty ? nil : Array(allFileVersions.values)
            )
        }
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

    /// Merges computed hashes from two results.
    private func mergeHashes(
        _ existing: [String: [String: String]],
        _ new: [String: [String: String]]
    ) -> [String: [String: String]] {
        var result = existing
        for (fileId, hashes) in new {
            if let existingHashes = result[fileId] {
                result[fileId] = existingHashes.merging(hashes) { _, new in new }
            } else {
                result[fileId] = hashes
            }
        }
        return result
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
    let exporter: any ConfigExportPerforming

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
        exporter: ConfigExportPerforming? = nil
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
        self.exporter = exporter ?? SubcommandConfigExporter(
            globalOptions: globalOptions,
            resume: resume,
            cache: cache,
            noCache: noCache,
            force: force,
            cachePath: cachePath,
            experimentalGranularCache: experimentalGranularCache,
            concurrentDownloads: concurrentDownloads
        )
    }

    func process(configFile: ConfigFile, ui: TerminalUI) async -> ConfigResult {
        ui.info("Processing: \(configFile.name)")

        do {
            var options = ExFigOptions()
            options.input = configFile.url.path
            try options.validate()

            let retryHandler = RetryLogger.createHandler(ui: ui, maxAttempts: maxRetries)

            // CLI timeout takes precedence over per-config YAML timeout
            let effectiveTimeout: TimeInterval? = cliTimeout.map { TimeInterval($0) }
                ?? options.params.figma.timeout

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

            let stats = try await exporter.export(
                configFile: configFile,
                options: options,
                client: client,
                ui: ui
            )
            ui.success("Completed: \(configFile.name)")
            return .success(config: configFile, stats: stats)

        } catch {
            ui.error("Failed: \(configFile.name)")
            ui.error(error)
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
