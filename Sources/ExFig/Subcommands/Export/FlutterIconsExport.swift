import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation

// MARK: - Flutter Icons Export

extension ExFigCommand.ExportIcons {
    // swiftlint:disable function_body_length

    /// Exports Flutter icons from Figma.
    func exportFlutterIcons(
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        guard let flutter = params.flutter, let iconsConfig = flutter.icons else {
            ui.warning(.configMissing(platform: "flutter", assetType: "icons"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        // Get all entries from config (supports both single and multiple formats)
        let entries = iconsConfig.entries

        // Single entry - use direct processing (legacy behavior)
        if entries.count == 1 {
            return try await exportFlutterIconsEntry(
                entry: entries[0],
                flutter: flutter,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }

        // Multiple entries - pre-fetch Components once for all entries
        return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
            client: client,
            params: params
        ) {
            try await processFlutterIconsEntries(
                entries: entries,
                flutter: flutter,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Helper to process multiple Flutter icon entries sequentially.
    // swiftlint:disable:next function_parameter_count
    func processFlutterIconsEntries(
        entries: [Params.Flutter.IconsEntry],
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportFlutterIconsEntry(
                entry: entry,
                flutter: flutter,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Exports icons for a single Flutter icons entry.
    // swiftlint:disable:next function_body_length function_parameter_count
    func exportFlutterIconsEntry(
        entry: Params.Flutter.IconsEntry,
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let loaderConfig = IconsLoaderConfig.forFlutter(entry: entry, params: params)

        // 1. Get Icons info
        let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .flutter,
                logger: ExFigCommand.logger,
                config: loaderConfig
            )
            if let manager = granularCacheManager {
                loader.granularCacheManager = manager
                return try await loader.loadWithGranularCache(filter: filter, onBatchProgress: onProgress)
            } else {
                let output = try await loader.load(filter: filter, onBatchProgress: onProgress)
                return IconsLoaderResultWithHashes(
                    light: output.light,
                    dark: output.dark,
                    computedHashes: [:],
                    allSkipped: false,
                    allNames: [] // Not needed when not using granular cache
                )
            }
        }

        // If granular cache skipped all icons, return early
        if loaderResult.allSkipped {
            ui.success("All icons unchanged (granular cache). Skipping export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allNames.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        // 2. Process images
        let processor = ImagesProcessor(
            platform: .flutter,
            nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
            nameStyle: .snakeCase
        )

        let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing icons...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let iconsWarning {
            ui.warning(iconsWarning)
        }

        // 3. Export icons
        let assetsDirectory = URL(fileURLWithPath: entry.output)
        let output = FlutterOutput(
            outputDirectory: flutter.output,
            iconsAssetsDirectory: assetsDirectory,
            templatesPath: flutter.templatesPath,
            iconsClassName: entry.className
        )

        let exporter = FlutterIconsExporter(output: output, outputFileName: entry.dartFile)
        // Process allNames with the same transformations applied to icons
        let allIconNames = granularCacheManager != nil
            ? processor.processNames(loaderResult.allNames)
            : nil
        let (dartFile, assetFiles) = try exporter.export(icons: icons, allIconNames: allIconNames)

        // 4. Download SVG files
        let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        var localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, _ in
                    progress.update(current: current)
                }
            }
        } else {
            []
        }

        // Clear output directory if not filtering
        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        // 5. Write files
        localFiles.append(dartFile)

        let filesToWrite = localFiles
        try await ui.withSpinner("Writing files to Flutter project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        await checkForUpdate(logger: ExFigCommand.logger)

        // Calculate skipped count for granular cache stats
        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - icons.count
            : 0

        ui.success("Done! Exported \(icons.count) icons to Flutter project.")
        return PlatformExportResult(
            count: icons.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
