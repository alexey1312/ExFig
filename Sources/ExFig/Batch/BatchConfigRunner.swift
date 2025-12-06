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

    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        try await InjectedClientStorage.$client.withValue(client) {
            let cacheOptions = CacheOptions()
            let faultToleranceOptions = FaultToleranceOptions()

            var heavyFaultToleranceOptions = HeavyFaultToleranceOptions()
            heavyFaultToleranceOptions.resume = resume

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
    let exporter: any ConfigExportPerforming

    init(
        rateLimiter: SharedRateLimiter,
        retryPolicy: RetryPolicy,
        globalOptions: GlobalOptions,
        maxRetries: Int,
        resume: Bool,
        exporter: ConfigExportPerforming? = nil
    ) {
        self.rateLimiter = rateLimiter
        self.retryPolicy = retryPolicy
        self.globalOptions = globalOptions
        self.maxRetries = maxRetries
        self.resume = resume
        self.exporter = exporter ?? SubcommandConfigExporter(
            globalOptions: globalOptions,
            resume: resume
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
