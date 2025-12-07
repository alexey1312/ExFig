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
    let concurrentDownloads: Int

    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        try await InjectedClientStorage.$client.withValue(client) {
            var cacheOptions = CacheOptions()
            cacheOptions.cache = cache
            cacheOptions.noCache = noCache
            cacheOptions.force = force
            cacheOptions.cachePath = cachePath

            let faultToleranceOptions = FaultToleranceOptions()

            var heavyFaultToleranceOptions = HeavyFaultToleranceOptions()
            heavyFaultToleranceOptions.resume = resume
            heavyFaultToleranceOptions.concurrentDownloads = concurrentDownloads

            let colors = makeColors(
                options: options,
                cacheOptions: cacheOptions,
                faultToleranceOptions: faultToleranceOptions
            )
            let colorsCount = try await colors.performExport(client: client, ui: ui)

            let icons = makeIcons(
                options: options,
                cacheOptions: cacheOptions,
                faultToleranceOptions: heavyFaultToleranceOptions
            )
            let iconsCount = try await icons.performExport(client: client, ui: ui)

            let images = makeImages(
                options: options,
                cacheOptions: cacheOptions,
                faultToleranceOptions: heavyFaultToleranceOptions
            )
            let imagesCount = try await images.performExport(client: client, ui: ui)

            let typography = makeTypography(
                options: options,
                cacheOptions: cacheOptions,
                faultToleranceOptions: faultToleranceOptions
            )
            let typographyCount = try await typography.performExport(client: client, ui: ui)

            return ExportStats(
                colors: colorsCount,
                icons: iconsCount,
                images: imagesCount,
                typography: typographyCount
            )
        }
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
    let concurrentDownloads: Int
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
        concurrentDownloads: Int = FileDownloader.defaultMaxConcurrentDownloads,
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
        self.concurrentDownloads = concurrentDownloads
        self.exporter = exporter ?? SubcommandConfigExporter(
            globalOptions: globalOptions,
            resume: resume,
            cache: cache,
            noCache: noCache,
            force: force,
            cachePath: cachePath,
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

            let baseClient = FigmaClient(
                accessToken: options.accessToken,
                timeout: options.params.figma.timeout
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
            ui.error("Failed: \(configFile.name) - \(error.localizedDescription)")
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
