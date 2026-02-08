// swiftlint:disable file_length
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation
import Noora

extension ExFigCommand {
    // swiftlint:disable:next type_body_length
    struct Batch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "batch",
            abstract: "Process multiple config files in parallel",
            discussion: """
            Process multiple ExFig configuration files in a single command with shared rate limiting.

            When a directory is specified, only config files directly in that directory are processed.
            Subdirectories are not scanned. To process nested configs, specify them explicitly or use
            shell globbing (e.g., ./configs/*/*.pkl).

            Examples:
              exfig batch ./configs/                 # Process configs in directory (non-recursive)
              exfig batch config1.pkl config2.pkl    # Process specific files
              exfig batch ./configs/ --parallel 5    # With custom parallelism
              exfig batch ./configs/ --rate-limit 20 # Custom rate limit
              exfig batch ./configs/*/*.pkl          # Process nested configs via shell glob
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .long, help: "Maximum configs to process in parallel")
        var parallel: Int = 3

        @Flag(name: .long, help: "Stop processing on first error")
        var failFast: Bool = false

        @Option(name: .long, help: "Figma API requests per minute")
        var rateLimit: Int = 10

        @Option(name: .long, help: "Maximum retry attempts for failed requests")
        var maxRetries: Int = 4

        @Flag(name: .long, help: "Resume from previous checkpoint if available")
        var resume: Bool = false

        @Option(name: .long, help: "Path to write JSON report")
        var report: String?

        /// Cache options
        @Flag(name: .long, help: "Enable version tracking cache (skip export if unchanged)")
        var cache: Bool = false

        @Flag(name: .long, help: "Disable version tracking cache (always export)")
        var noCache: Bool = false

        @Flag(name: .long, help: "Force export and update cache (ignore cached version)")
        var force: Bool = false

        @Option(name: .long, help: "Custom path to cache file (default: .exfig-cache.json)")
        var cachePath: String?

        @Flag(
            name: .long,
            help: "[EXPERIMENTAL] Enable per-node hash tracking for granular cache invalidation"
        )
        var experimentalGranularCache: Bool = false

        /// Download concurrency
        @Option(name: .long, help: "Maximum concurrent CDN downloads")
        var concurrentDownloads: Int = FileDownloader.defaultMaxConcurrentDownloads

        /// Connection options
        @Option(name: .long, help: "Figma API request timeout in seconds (overrides config)")
        var timeout: Int?

        @Argument(help: "Config files or directory to process")
        var paths: [String]

        mutating func validate() throws {
            if let timeout, timeout <= 0 {
                throw ValidationError("Timeout must be positive")
            }
        }

        // swiftlint:disable:next function_body_length
        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            ExFigCommand.checkSchemaVersionIfNeeded()
            let ui = ExFigCommand.terminalUI!

            // Discover and validate configs
            let validConfigs = try discoverAndValidateConfigs(ui: ui)
            guard !validConfigs.isEmpty else { return }

            // Prepare configs with checkpoint handling
            let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let (configs, checkpoint) = prepareConfigsWithCheckpoint(
                validConfigs: validConfigs,
                workingDirectory: workingDirectory,
                ui: ui
            )

            guard !configs.isEmpty else {
                ui.success("All configs already completed!")
                try? BatchCheckpoint.delete(from: workingDirectory)
                return
            }

            // Execute batch
            let (result, rateLimiter) = await executeBatch(
                configs: configs,
                checkpoint: checkpoint,
                workingDirectory: workingDirectory,
                ui: ui
            )

            // Handle results
            handleResults(
                result: result,
                rateLimiter: rateLimiter,
                workingDirectory: workingDirectory,
                ui: ui
            )
        }

        // MARK: - Run Helpers

        private func discoverAndValidateConfigs(ui: TerminalUI) throws -> [URL] {
            let configURLs = try discoverConfigs(ui: ui)
            guard !configURLs.isEmpty else {
                ui.warning(.noConfigsFound)
                return []
            }

            let discovery = ConfigDiscovery()
            let validConfigs = discovery.filterValidConfigs(configURLs)

            if validConfigs.count < configURLs.count {
                let skipped = configURLs.count - validConfigs.count
                ui.warning(.invalidConfigsSkipped(count: skipped))
            }

            guard !validConfigs.isEmpty else {
                ui.warning(.noValidConfigs)
                return []
            }

            // Check for conflicts
            let conflicts = try discovery.detectOutputPathConflicts(validConfigs)
            if !conflicts.isEmpty {
                let formatter = ConflictFormatter()
                formatter.display(conflicts)
            }

            return validConfigs
        }

        private func prepareConfigsWithCheckpoint(
            validConfigs: [URL],
            workingDirectory: URL,
            ui: TerminalUI
        ) -> ([ConfigFile], BatchCheckpoint) {
            var configs = validConfigs.map { ConfigFile(url: $0) }

            if let existing = loadCheckpointIfResuming(workingDirectory: workingDirectory, ui: ui) {
                let skipped = existing.completedConfigs.count
                configs = configs.filter { !existing.isCompleted($0.url.path) }
                ui.info("Resuming: \(skipped) config(s) already completed, \(configs.count) remaining")
                return (configs, existing)
            }

            return (configs, BatchCheckpoint(requestedPaths: paths))
        }

        private func loadCheckpointIfResuming(workingDirectory: URL, ui: TerminalUI) -> BatchCheckpoint? {
            guard resume else { return nil }

            guard let existing = try? BatchCheckpoint.load(from: workingDirectory) else {
                return nil
            }

            if existing.isExpired() {
                ui.warning(.checkpointExpired)
                try? BatchCheckpoint.delete(from: workingDirectory)
                return nil
            }

            if !existing.matchesPaths(paths) {
                ui.warning(.checkpointPathMismatch)
                try? BatchCheckpoint.delete(from: workingDirectory)
                return nil
            }

            return existing
        }

        // swiftlint:disable:next function_body_length
        private func executeBatch(
            configs: [ConfigFile],
            checkpoint: BatchCheckpoint,
            workingDirectory: URL,
            ui: TerminalUI
        ) async -> (BatchResult, SharedRateLimiter) {
            let rateLimiter = SharedRateLimiter(requestsPerMinute: Double(rateLimit))
            let retryPolicy = RetryPolicy(maxRetries: maxRetries)

            // Load cache for smart pre-fetch optimization (version checking)
            // This allows skipping heavy Components API calls when file version is unchanged
            let cacheForVersionCheck = loadCacheForVersionCheck()

            // Pre-fetch file versions and components if cache is enabled (optimization)
            // Smart two-phase pre-fetch:
            // 1. Fetch FileMetadata only (fast, lightweight)
            // 2. Compare versions with cache
            // 3. Only fetch Components for files with changed versions
            let preFetchConfig = PreFetchConfiguration(
                configs: configs,
                cacheEnabled: cache,
                noCacheFlag: noCache,
                verbose: globalOptions.verbose,
                rateLimiter: rateLimiter,
                retryPolicy: retryPolicy,
                cache: cacheForVersionCheck
            )
            let preFetchResult = await FileVersionPreFetcher.preFetchWithComponents(
                configuration: preFetchConfig,
                ui: ui
            )
            let preFetchedVersions = preFetchResult.versions
            let preFetchedComponents = preFetchResult.components

            // Pre-load granular cache if enabled (uses same cache data if already loaded)
            let sharedGranularCache: SharedGranularCache? = prepareSharedGranularCache()

            // Phase 3: Pre-fetch nodes for granular cache if enabled
            // This avoids redundant Nodes API calls when multiple configs reference same file
            let preFetchedNodes = await preFetchNodesIfNeeded(
                components: preFetchedComponents,
                preFetchConfig: preFetchConfig,
                ui: ui
            )

            // Create shared download queue for cross-config pipelining
            let downloadQueue = SharedDownloadQueue(
                maxConcurrentDownloads: concurrentDownloads * parallel
            )

            // Create priority map: configs submitted first get higher priority (lower number)
            let priorityMap = Dictionary(
                uniqueKeysWithValues: configs.enumerated().map { ($0.element.name, $0.offset) }
            )

            displayBatchStartInfo(
                configCount: configs.count,
                sharedGranularCache: sharedGranularCache,
                ui: ui
            )

            // Create batch progress view for rich per-config progress display
            let progressView = BatchProgressView(
                useColors: !globalOptions.quiet,
                useAnimations: !globalOptions.quiet && TTYDetector.isTTY
            )

            // Register all configs upfront
            for config in configs {
                await progressView.registerConfig(name: config.name)
            }

            let executor = BatchExecutor(maxParallel: parallel, failFast: failFast)
            let checkpointManager = CheckpointManager(checkpoint: checkpoint, directory: workingDirectory)
            let runnerFactory = makeRunnerFactory(
                rateLimiter: rateLimiter,
                retryPolicy: retryPolicy,
                priorityMap: priorityMap
            )

            // Create shared theme attributes collector for batch mode
            let themeAttributesCollector = SharedThemeAttributesCollector()

            // Create consolidated batch shared state with SINGLE TaskLocal scope.
            // This avoids nested withValue() calls which cause Swift runtime crashes on Linux.
            // See: https://github.com/swiftlang/swift/issues/75501
            let batchContext = BatchContext(
                versions: preFetchedVersions,
                components: preFetchedComponents,
                granularCache: sharedGranularCache,
                nodes: preFetchedNodes
            )
            let batchState = BatchSharedState(
                context: batchContext,
                progressView: progressView,
                themeCollector: themeAttributesCollector,
                downloadQueue: downloadQueue
            )

            // SINGLE withValue scope - no nesting!
            let result: BatchResult = await BatchSharedState.$current.withValue(batchState) {
                await executeWithProgressUpdates(
                    executor: executor,
                    configs: configs,
                    checkpointManager: checkpointManager,
                    runnerFactory: runnerFactory,
                    progressView: progressView,
                    rateLimiter: rateLimiter,
                    ui: ui
                )
            }

            // Clear progress view after batch completes
            await progressView.clear()

            // Check for updates once at the end (suppressed during individual exports)
            await checkForUpdate(logger: logger)

            // After batch: merge all computed hashes and save once
            if let sharedCache = sharedGranularCache {
                saveGranularCacheAfterBatch(result: result, sharedCache: sharedCache, ui: ui)
            }

            // After batch: merge theme attributes from all configs into shared files
            await mergeThemeAttributesAfterBatch(collector: themeAttributesCollector, ui: ui)

            return (result, rateLimiter)
        }

        /// Execute batch with progress view updates and rate limiter status.
        private func executeWithProgressUpdates( // swiftlint:disable:this function_parameter_count
            executor: BatchExecutor,
            configs: [ConfigFile],
            checkpointManager: CheckpointManager,
            runnerFactory: @escaping @Sendable (ConfigFile) -> BatchConfigRunner,
            progressView: BatchProgressView,
            rateLimiter: SharedRateLimiter,
            ui: TerminalUI
        ) async -> BatchResult {
            // Start rate limiter status updates (every 500ms)
            let rateLimiterTask = Task {
                while !Task.isCancelled {
                    let status = await rateLimiter.status()
                    await progressView.updateRateLimiterStatus(status)
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }
            }

            // Execute batch - runner.process() gets progressView from BatchSharedState.current
            let result = await executor.execute(configs: configs) { configFile in
                let runner = runnerFactory(configFile)
                let configResult = await runner.process(configFile: configFile, ui: ui)
                await checkpointManager.update(for: configFile, result: configResult)
                return configResult
            }

            // Stop rate limiter updates
            rateLimiterTask.cancel()

            return result
        }

        /// Creates a factory function for BatchConfigRunner instances.
        private func makeRunnerFactory(
            rateLimiter: SharedRateLimiter,
            retryPolicy: RetryPolicy,
            priorityMap: [String: Int]
        ) -> @Sendable (ConfigFile) -> BatchConfigRunner {
            // Capture all values needed for runner creation
            let globalOptions = globalOptions
            let maxRetries = maxRetries
            let resume = resume
            let cache = cache
            let noCache = noCache
            let force = force
            let cachePath = cachePath
            let experimentalGranularCache = experimentalGranularCache
            let concurrentDownloads = concurrentDownloads
            let timeout = timeout

            return { configFile in
                BatchConfigRunner(
                    rateLimiter: rateLimiter,
                    retryPolicy: retryPolicy,
                    globalOptions: globalOptions,
                    maxRetries: maxRetries,
                    resume: resume,
                    cache: cache,
                    noCache: noCache,
                    force: force,
                    cachePath: cachePath,
                    experimentalGranularCache: experimentalGranularCache,
                    concurrentDownloads: concurrentDownloads,
                    cliTimeout: timeout,
                    configPriority: priorityMap[configFile.name] ?? 0
                )
            }
        }

        /// Displays batch start information.
        private func displayBatchStartInfo(
            configCount: Int,
            sharedGranularCache: SharedGranularCache?,
            ui: TerminalUI
        ) {
            ui.info("Processing \(configCount) config(s) with up to \(parallel) parallel workers...")
            if globalOptions.verbose {
                ui.info("Rate limit: \(rateLimit) req/min, max retries: \(maxRetries)")
                if sharedGranularCache != nil {
                    ui.info("Granular cache: shared across workers")
                }
                ui.info("Download queue: shared with \(concurrentDownloads * parallel) concurrent slots")
            }
        }

        /// Prepares shared granular cache for batch mode.
        /// Creates cache when --cache is enabled (for file versions), granular node hashes only when
        /// --experimental-granular-cache.
        private func prepareSharedGranularCache() -> SharedGranularCache? {
            // Create cache when --cache is enabled (for file versions tracking)
            // Node hashes are only used when --experimental-granular-cache is also set
            guard cache, !noCache else { return nil }

            let resolvedCachePath = ImageTrackingCache.resolvePath(customPath: cachePath)
            var cacheData = ImageTrackingCache.load(from: resolvedCachePath)

            // Clear all node hashes when --force is set (forces full re-export)
            if force {
                cacheData.clearAllNodeHashes()
            }

            return SharedGranularCache(cache: cacheData, cachePath: resolvedCachePath)
        }

        /// Loads cache for smart pre-fetch optimization (version checking).
        /// Returns cache data for version comparison, even when granular cache is disabled.
        private func loadCacheForVersionCheck() -> ImageTrackingCache? {
            guard cache, !noCache else { return nil }

            let resolvedCachePath = ImageTrackingCache.resolvePath(customPath: cachePath)
            return ImageTrackingCache.load(from: resolvedCachePath)
        }

        /// Pre-fetch nodes for granular cache optimization if enabled.
        ///
        /// Phase 3 of smart pre-fetch: collects ALL nodeIds from pre-fetched components
        /// and fetches in 1 request per file. This avoids redundant Nodes API calls when
        /// multiple configs reference the same Figma file.
        private func preFetchNodesIfNeeded(
            components: PreFetchedComponents?,
            preFetchConfig: PreFetchConfiguration,
            ui: TerminalUI
        ) async -> PreFetchedNodes? {
            // Only pre-fetch nodes when granular cache is enabled
            guard experimentalGranularCache,
                  cache,
                  !noCache,
                  let components
            else {
                return nil
            }

            // Get file IDs that have components (those that need nodes)
            let changedFileIds = Set(components.allFileIds())

            guard !changedFileIds.isEmpty else {
                return nil
            }

            guard let preFetcher = FileVersionPreFetcher.createPreFetcher(
                configuration: preFetchConfig,
                ui: ui
            ) else {
                return nil
            }

            do {
                return try await preFetcher.preFetchNodes(
                    components: components,
                    changedFileIds: changedFileIds
                )
            } catch {
                // Log warning and continue without pre-fetched nodes (fallback to per-config fetch)
                ui.warning(.preFetchNodesPartialFailure(error: error.localizedDescription))
                return nil
            }
        }

        /// Saves granular cache after batch completes by merging all computed hashes.
        private func saveGranularCacheAfterBatch(
            result: BatchResult,
            sharedCache: SharedGranularCache,
            ui: TerminalUI
        ) {
            var updatedCache = sharedCache.cache

            // Merge file versions and computed hashes from all successful configs
            for success in result.successes {
                for version in success.stats.fileVersions ?? [] {
                    updatedCache.updateFileVersion(
                        fileId: version.fileId,
                        version: version.currentVersion,
                        fileName: version.fileName
                    )
                }

                // Node hashes are only saved when --experimental-granular-cache is enabled
                if experimentalGranularCache {
                    for (fileId, hashes) in success.stats.computedNodeHashes {
                        let nodeHashes = Dictionary(uniqueKeysWithValues: hashes.map { ($0.key, $0.value) })
                        updatedCache.updateNodeHashes(fileId: fileId, hashes: nodeHashes)
                    }
                }
            }

            do {
                try updatedCache.save(to: sharedCache.cachePath)
                if globalOptions.verbose {
                    let fileCount = updatedCache.files.count
                    if experimentalGranularCache {
                        let totalHashes = result.totalStats.computedNodeHashes.values.reduce(0) { $0 + $1.count }
                        ui.info("Cache saved: \(fileCount) file versions, \(totalHashes) node hashes")
                    } else {
                        ui.info("Cache saved: \(fileCount) file versions")
                    }
                }
            } catch {
                ui.error("Failed to save cache: \(error.localizedDescription)")
            }
        }

        /// Merges theme attributes from all configs into shared files after batch completes.
        ///
        /// Multiple configs may export to the same attrs.xml and styles.xml files.
        /// This function updates each file once with content from all configs,
        /// where each config's content goes into its own marker section (identified by themeName).
        private func mergeThemeAttributesAfterBatch(
            collector: SharedThemeAttributesCollector,
            ui: TerminalUI
        ) async {
            let collections = await collector.getAll()
            guard !collections.isEmpty else { return }

            // Group collections by target file URL
            var fileGroups: [(
                url: URL,
                collections: [ThemeAttributesCollection],
                keyPath: KeyPath<ThemeAttributesCollection, String>,
                isAttrs: Bool
            )] = []

            var attrsByFile: [URL: [ThemeAttributesCollection]] = [:]
            var stylesByFile: [URL: [ThemeAttributesCollection]] = [:]
            var stylesNightByFile: [URL: [ThemeAttributesCollection]] = [:]

            for collection in collections {
                attrsByFile[collection.attrsFile, default: []].append(collection)
                stylesByFile[collection.stylesFile, default: []].append(collection)
                if let nightFile = collection.stylesNightFile {
                    stylesNightByFile[nightFile, default: []].append(collection)
                }
            }

            // Collect all file groups to process
            for (url, items) in attrsByFile {
                fileGroups.append((url, items, \.attrsContent, true))
            }
            for (url, items) in stylesByFile {
                fileGroups.append((url, items, \.stylesContent, false))
            }
            for (url, items) in stylesNightByFile {
                fileGroups.append((url, items, \.stylesContent, false))
            }

            // Update all files with their theme sections
            for group in fileGroups {
                updateSharedThemeAttributesFile(
                    url: group.url,
                    collections: group.collections,
                    contentKeyPath: group.keyPath,
                    isAttrsFile: group.isAttrs,
                    ui: ui
                )
            }

            if globalOptions.verbose {
                let uniqueFiles = Set(fileGroups.map(\.url))
                ui.info("Theme attributes: merged \(collections.count) configs into \(uniqueFiles.count) files")
            }
        }

        /// Updates a single shared theme attributes file with multiple theme sections.
        private func updateSharedThemeAttributesFile(
            url: URL,
            collections: [ThemeAttributesCollection],
            contentKeyPath: KeyPath<ThemeAttributesCollection, String>,
            isAttrsFile: Bool,
            ui: TerminalUI
        ) {
            // Ensure directory exists
            let directory = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            // Read existing file content (or create if needed)
            var fileContent: String
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    fileContent = try String(contentsOf: url, encoding: .utf8)
                } catch {
                    ui.error("Failed to read \(url.lastPathComponent): \(error.localizedDescription)")
                    return
                }
            } else {
                // Check if any collection allows auto-create
                guard let firstAutoCreate = collections.first(where: { $0.autoCreateMarkers }), isAttrsFile else {
                    ui.warning(
                        .themeAttributesFileNotFound(file: url.lastPathComponent)
                    )
                    return
                }
                // Create minimal attrs.xml with markers
                let updater = MarkerFileUpdater(
                    markerStart: firstAutoCreate.markerStart,
                    markerEnd: firstAutoCreate.markerEnd,
                    themeName: firstAutoCreate.themeName
                )
                fileContent = """
                <?xml version="1.0" encoding="utf-8"?>
                <resources>
                    \(updater.fullStartMarker)
                    \(updater.fullEndMarker)
                </resources>
                """
            }

            // Update each theme section in sequence
            for collection in collections {
                let updater = MarkerFileUpdater(
                    markerStart: collection.markerStart,
                    markerEnd: collection.markerEnd,
                    themeName: collection.themeName
                )

                do {
                    fileContent = try updater.update(
                        content: collection[keyPath: contentKeyPath],
                        in: fileContent,
                        fileName: url.lastPathComponent
                    )
                } catch {
                    let file = url.lastPathComponent
                    let marker = updater.fullStartMarker
                    ui.error(
                        "Theme attributes skipped: marker not found, file=\(file), marker=\(marker)"
                    )
                }
            }

            // Write updated file
            do {
                try Data(fileContent.utf8).write(to: url, options: .atomic)
            } catch {
                ui.error("Failed to write \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        private func handleResults(
            result: BatchResult,
            rateLimiter: SharedRateLimiter,
            workingDirectory: URL,
            ui: TerminalUI
        ) {
            displaySummary(result: result, ui: ui)

            if globalOptions.verbose {
                Task {
                    let status = await rateLimiter.status()
                    displayRateLimitStatus(status: status, ui: ui)
                }
            }

            if let reportPath = report {
                do {
                    try writeReport(result: result, to: reportPath, ui: ui)
                } catch {
                    ui.error("Failed to write report to \(reportPath): \(error.localizedDescription)")
                }
            }

            if result.failureCount == 0 {
                do {
                    try BatchCheckpoint.delete(from: workingDirectory)
                } catch {
                    let hint = "\(workingDirectory.path)/.exfig-checkpoint.json"
                    ui.warning(
                        "Failed to delete checkpoint: \(error.localizedDescription). Delete manually: \(hint)"
                    )
                }
                if globalOptions.verbose {
                    ui.info("Checkpoint cleared (all configs completed successfully)")
                }
            } else if !failFast {
                ui.error("Batch completed with \(result.failureCount) failure(s)")
                ui.info("Run with --resume to retry failed configs")
            }
        }

        // MARK: - Private Methods

        private func discoverConfigs(ui: TerminalUI) throws -> [URL] {
            let discovery = ConfigDiscovery()
            var allConfigs: [URL] = []

            for path in paths {
                let url = URL(fileURLWithPath: path)
                var isDirectory: ObjCBool = false

                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let configs = try discovery.discoverConfigs(in: url)
                        allConfigs.append(contentsOf: configs)
                    } else {
                        allConfigs.append(url)
                    }
                } else {
                    throw ConfigDiscoveryError.fileNotFound(url)
                }
            }

            return allConfigs
        }

        private func displaySummary(result: BatchResult, ui: TerminalUI) {
            ui.info("")
            ui.info("Batch complete: \(result.successCount) succeeded, \(result.failureCount) failed")
            ui.info("Duration: \(String(format: "%.2f", result.duration))s")

            // Display aggregated granular cache stats if available
            if let granularStats = result.totalStats.granularCacheStats {
                let skipped = granularStats.skipped
                let exported = granularStats.exported
                ui.info("Granular cache: \(skipped) nodes skipped, \(exported) nodes exported")
            }

            ui.info("")

            let headers: [TableCellStyle] = [
                .plain(" "),
                .plain("Config"),
                .plain("Result"),
            ]

            var rows: [StyledTableRow] = []

            for success in result.successes {
                let stats = success.stats
                var parts: [String] = []
                if stats.colors > 0 { parts.append("\(stats.colors) colors") }
                if stats.icons > 0 { parts.append("\(stats.icons) icons") }
                if stats.images > 0 { parts.append("\(stats.images) images") }
                if stats.typography > 0 { parts.append("\(stats.typography) typography") }

                let statsString = parts.isEmpty ? "validated" : parts.joined(separator: ", ")
                rows.append([.success("✓"), .plain(success.config.name), .plain(statsString)])
            }

            for failure in result.failures {
                let errorMessage = failure.error.localizedDescription
                rows.append([.danger("✗"), .plain(failure.config.name), .danger(errorMessage)])
            }

            NooraUI.shared.table(headers: headers, rows: rows)
        }

        private func displayRateLimitStatus(status: RateLimiterStatus, ui: TerminalUI) {
            ui.info("")
            ui.info("Rate Limiter Stats:")
            ui.info("  Configured: \(Int(status.requestsPerMinute)) req/min")

            let available = String(format: "%.1f", status.availableTokens)
            let max = String(format: "%.0f", status.maxTokens)
            ui.info("  Tokens: \(available)/\(max)")

            if !status.configRequestCounts.isEmpty {
                let totalRequests = status.configRequestCounts.values.reduce(0, +)
                ui.info("  Total requests: \(totalRequests)")
            }

            if status.isPaused, let retryAfter = status.retryAfter {
                ui.warning("  Status: Paused (retry after \(Int(retryAfter))s)")
            }
        }

        private func writeReport(result: BatchResult, to path: String, ui: TerminalUI) throws {
            let report = BatchReport(
                startTime: ISO8601DateFormatter().string(from: result.startTime),
                endTime: ISO8601DateFormatter().string(from: result.endTime),
                duration: result.duration,
                totalConfigs: result.results.count,
                successCount: result.successCount,
                failureCount: result.failureCount,
                results: result.results.map { configResult in
                    BatchReport.ConfigReport(
                        name: configResult.config.name,
                        path: configResult.config.url.path,
                        success: configResult.isSuccess,
                        error: configResult.error?.localizedDescription,
                        stats: configResult.stats.map { stats in
                            BatchReport.Stats(
                                colors: stats.colors,
                                icons: stats.icons,
                                images: stats.images,
                                typography: stats.typography
                            )
                        }
                    )
                }
            )

            let data = try JSONCodec.encodePrettySorted(report)

            let url = URL(fileURLWithPath: path)
            try data.write(to: url)
            ui.info("Report written to: \(path)")
        }
    }
}

// MARK: - Checkpoint Manager

/// Actor for safely updating batch checkpoint from concurrent tasks.
private actor CheckpointManager {
    private var checkpoint: BatchCheckpoint
    private let directory: URL

    init(checkpoint: BatchCheckpoint, directory: URL) {
        self.checkpoint = checkpoint
        self.directory = directory
    }

    func update(for config: ConfigFile, result: ConfigResult) {
        switch result {
        case .success:
            checkpoint.markCompleted(config.url.path)
        case .failure:
            checkpoint.markFailed(config.url.path)
        }

        // Save checkpoint after each update
        try? checkpoint.save(to: directory)
    }
}

// MARK: - Report Models

private struct BatchReport: Encodable {
    let startTime: String
    let endTime: String
    let duration: TimeInterval
    let totalConfigs: Int
    let successCount: Int
    let failureCount: Int
    let results: [ConfigReport]

    struct ConfigReport: Encodable {
        let name: String
        let path: String
        let success: Bool
        let error: String?
        let stats: Stats?
    }

    struct Stats: Encodable {
        let colors: Int
        let icons: Int
        let images: Int
        let typography: Int
    }
}
