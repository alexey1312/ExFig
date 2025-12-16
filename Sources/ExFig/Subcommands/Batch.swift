// swiftlint:disable file_length
import ArgumentParser
import FigmaAPI
import Foundation

extension ExFigCommand {
    // swiftlint:disable:next type_body_length
    struct Batch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "batch",
            abstract: "Process multiple config files in parallel",
            discussion: """
            Process multiple ExFig configuration files in a single command with shared rate limiting.

            When a directory is specified, only YAML files directly in that directory are processed.
            Subdirectories are not scanned. To process nested configs, specify them explicitly or use
            shell globbing (e.g., ./configs/*/*.yaml).

            Examples:
              exfig batch ./configs/                 # Process configs in directory (non-recursive)
              exfig batch config1.yaml config2.yaml  # Process specific files
              exfig batch ./configs/ --parallel 5    # With custom parallelism
              exfig batch ./configs/ --rate-limit 20 # Custom rate limit
              exfig batch ./configs/*/*.yaml         # Process nested configs via shell glob
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

        // Cache options
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

        // Download concurrency
        @Option(name: .long, help: "Maximum concurrent CDN downloads")
        var concurrentDownloads: Int = FileDownloader.defaultMaxConcurrentDownloads

        // Connection options
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
                ui.warning(formatter.format(conflicts))
            }

            return validConfigs
        }

        private func prepareConfigsWithCheckpoint(
            validConfigs: [URL],
            workingDirectory: URL,
            ui: TerminalUI
        ) -> ([ConfigFile], BatchCheckpoint) {
            var configs = validConfigs.map { ConfigFile(url: $0) }
            var checkpoint = loadCheckpointIfResuming(workingDirectory: workingDirectory, ui: ui)

            if let existing = checkpoint {
                let skipped = existing.completedConfigs.count
                configs = configs.filter { !existing.isCompleted($0.url.path) }
                ui.info("Resuming: \(skipped) config(s) already completed, \(configs.count) remaining")
            } else {
                checkpoint = BatchCheckpoint(requestedPaths: paths)
            }

            return (configs, checkpoint!)
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
                downloadQueue: downloadQueue,
                priorityMap: priorityMap
            )

            // Create shared theme attributes collector for batch mode
            let themeAttributesCollector = SharedThemeAttributesCollector()

            // Wrap execution with batch progress view and batch context injection
            // Nodes are injected via separate TaskLocal (Phase 3 optimization)
            // Theme attributes collector is always injected for batch mode
            let collector = themeAttributesCollector
            let result: BatchResult = await SharedThemeAttributesStorage.$collector.withValue(collector) {
                await BatchProgressViewStorage.$progressView.withValue(progressView) {
                    await PreFetchedNodesStorage.$nodes.withValue(preFetchedNodes) {
                        await withBatchContext(
                            preFetchedVersions: preFetchedVersions,
                            preFetchedComponents: preFetchedComponents,
                            sharedGranularCache: sharedGranularCache
                        ) {
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
                    }
                }
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

        // swiftlint:disable function_parameter_count
        /// Execute batch with progress view updates and rate limiter status.
        private func executeWithProgressUpdates(
            executor: BatchExecutor,
            configs: [ConfigFile],
            checkpointManager: CheckpointManager,
            runnerFactory: @escaping @Sendable (ConfigFile) -> BatchConfigRunner,
            progressView: BatchProgressView,
            rateLimiter: SharedRateLimiter,
            ui: TerminalUI
        ) async -> BatchResult {
            // swiftlint:enable function_parameter_count
            // Start rate limiter status updates (every 500ms)
            let rateLimiterTask = Task {
                while !Task.isCancelled {
                    let status = await rateLimiter.status()
                    await progressView.updateRateLimiterStatus(status)
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }
            }

            // Execute batch with progress view
            let result = await executor.execute(configs: configs) { configFile in
                let runner = runnerFactory(configFile)
                let configResult = await runner.process(
                    configFile: configFile,
                    ui: ui,
                    progressView: progressView
                )
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
            downloadQueue: SharedDownloadQueue,
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
                    downloadQueue: downloadQueue,
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
        private func prepareSharedGranularCache() -> SharedGranularCache? {
            // Only enable if granular cache is requested and cache is enabled
            guard experimentalGranularCache, cache, !noCache else { return nil }

            let resolvedCachePath = ImageTrackingCache.resolvePath(customPath: cachePath)
            let cacheData = ImageTrackingCache.load(from: resolvedCachePath)

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

        /// Wraps execution with TaskLocal context for pre-fetched data and shared granular cache.
        private func withBatchContext<T>(
            preFetchedVersions: PreFetchedFileVersions?,
            preFetchedComponents: PreFetchedComponents?,
            sharedGranularCache: SharedGranularCache?,
            operation: () async -> T
        ) async -> T {
            // Nested TaskLocal injection based on what's available
            switch (preFetchedVersions, preFetchedComponents, sharedGranularCache) {
            // All three contexts
            case let (versions?, components?, cache?):
                await PreFetchedVersionsStorage.$versions.withValue(versions) {
                    await PreFetchedComponentsStorage.$components.withValue(components) {
                        await SharedGranularCacheStorage.$cache.withValue(cache) {
                            await operation()
                        }
                    }
                }

            // Versions + components
            case let (versions?, components?, nil):
                await PreFetchedVersionsStorage.$versions.withValue(versions) {
                    await PreFetchedComponentsStorage.$components.withValue(components) {
                        await operation()
                    }
                }

            // Versions + cache
            case let (versions?, nil, cache?):
                await PreFetchedVersionsStorage.$versions.withValue(versions) {
                    await SharedGranularCacheStorage.$cache.withValue(cache) {
                        await operation()
                    }
                }

            // Components + cache
            case let (nil, components?, cache?):
                await PreFetchedComponentsStorage.$components.withValue(components) {
                    await SharedGranularCacheStorage.$cache.withValue(cache) {
                        await operation()
                    }
                }

            // Only versions
            case let (versions?, nil, nil):
                await PreFetchedVersionsStorage.$versions.withValue(versions) {
                    await operation()
                }

            // Only components
            case let (nil, components?, nil):
                await PreFetchedComponentsStorage.$components.withValue(components) {
                    await operation()
                }

            // Only cache
            case let (nil, nil, cache?):
                await SharedGranularCacheStorage.$cache.withValue(cache) {
                    await operation()
                }

            // None
            case (nil, nil, nil):
                await operation()
            }
        }

        /// Saves granular cache after batch completes by merging all computed hashes.
        private func saveGranularCacheAfterBatch(
            result: BatchResult,
            sharedCache: SharedGranularCache,
            ui: TerminalUI
        ) {
            var updatedCache = sharedCache.cache

            // First, merge all file versions from successful configs
            for success in result.successes {
                if let versions = success.stats.fileVersions {
                    for version in versions {
                        updatedCache.updateFileVersion(
                            fileId: version.fileId,
                            version: version.currentVersion,
                            fileName: version.fileName
                        )
                    }
                }
            }

            // Then merge all computed hashes from successful configs
            for success in result.successes {
                for (fileId, hashes) in success.stats.computedNodeHashes {
                    let nodeHashes = hashes.reduce(into: [NodeId: String]()) { result, pair in
                        result[pair.key] = pair.value
                    }
                    updatedCache.updateNodeHashes(fileId: fileId, hashes: nodeHashes)
                }
            }

            // Save merged cache
            do {
                try updatedCache.save(to: sharedCache.cachePath)
                if globalOptions.verbose {
                    let totalHashes = result.totalStats.computedNodeHashes.values.reduce(0) { $0 + $1.count }
                    ui.info("Granular cache saved: \(totalHashes) node hashes")
                }
            } catch {
                ui.warning("Failed to save granular cache: \(error.localizedDescription)")
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

            // Update each file with all its theme sections
            for (fileURL, fileCollections) in attrsByFile {
                updateSharedThemeAttributesFile(
                    url: fileURL,
                    collections: fileCollections,
                    contentKeyPath: \.attrsContent,
                    isAttrsFile: true,
                    ui: ui
                )
            }

            for (fileURL, fileCollections) in stylesByFile {
                updateSharedThemeAttributesFile(
                    url: fileURL,
                    collections: fileCollections,
                    contentKeyPath: \.stylesContent,
                    isAttrsFile: false,
                    ui: ui
                )
            }

            for (fileURL, fileCollections) in stylesNightByFile {
                updateSharedThemeAttributesFile(
                    url: fileURL,
                    collections: fileCollections,
                    contentKeyPath: \.stylesContent,
                    isAttrsFile: false,
                    ui: ui
                )
            }

            if globalOptions.verbose {
                let uniqueFiles = Set(attrsByFile.keys).union(stylesByFile.keys).union(stylesNightByFile.keys)
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
                    ui.warning("Failed to read \(url.lastPathComponent): \(error.localizedDescription)")
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
                    ui.warning(
                        .themeAttributesMarkerNotFound(
                            file: url.lastPathComponent,
                            marker: updater.fullStartMarker
                        )
                    )
                }
            }

            // Write updated file
            do {
                try Data(fileContent.utf8).write(to: url, options: .atomic)
            } catch {
                ui.warning("Failed to write \(url.lastPathComponent): \(error.localizedDescription)")
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
                try? writeReport(result: result, to: reportPath, ui: ui)
            }

            if result.failureCount == 0 {
                try? BatchCheckpoint.delete(from: workingDirectory)
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

            for success in result.successes {
                let stats = success.stats
                var parts: [String] = []
                if stats.colors > 0 { parts.append("\(stats.colors) colors") }
                if stats.icons > 0 { parts.append("\(stats.icons) icons") }
                if stats.images > 0 { parts.append("\(stats.images) images") }
                if stats.typography > 0 { parts.append("\(stats.typography) typography") }

                let statsString = parts.isEmpty ? "validated" : parts.joined(separator: ", ")
                ui.success("\(success.config.name) - \(statsString)")
            }

            for failure in result.failures {
                ui.error("\(failure.config.name): \(failure.error.localizedDescription)")
            }
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

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)

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
