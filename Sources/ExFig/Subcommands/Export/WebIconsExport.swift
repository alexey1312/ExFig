import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import WebExport

// MARK: - Web Icons Export

extension ExFigCommand.ExportIcons {
    // swiftlint:disable function_body_length

    /// Exports Web icons from Figma.
    func exportWebIcons(
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        guard let web = params.web, let iconsConfig = web.icons else {
            ui.warning(.configMissing(platform: "web", assetType: "icons"))
            return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
        }

        // Get all entries from config (supports both single and multiple formats)
        let entries = iconsConfig.entries

        // Single entry - use direct processing (legacy behavior)
        if entries.count == 1 {
            return try await exportWebIconsEntry(
                entry: entries[0],
                web: web,
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
            try await processWebIconsEntries(
                entries: entries,
                web: web,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Helper to process multiple Web icon entries sequentially.
    // swiftlint:disable:next function_parameter_count
    func processWebIconsEntries(
        entries: [Params.Web.IconsEntry],
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportWebIconsEntry(
                entry: entry,
                web: web,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Exports icons for a single Web icons entry.
    // swiftlint:disable:next function_body_length function_parameter_count cyclomatic_complexity
    func exportWebIconsEntry(
        entry: Params.Web.IconsEntry,
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let loaderConfig = IconsLoaderConfig.forWeb(entry: entry, params: params)

        // 1. Get Icons info
        let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .web,
                logger: ExFigCommand.logger,
                config: loaderConfig
            )
            if let manager = granularCacheManager {
                loader.granularCacheProvider = manager
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
            platform: .web,
            nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
            nameStyle: entry.nameStyle ?? .snakeCase
        )

        let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing icons...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let iconsWarning {
            ui.warning(iconsWarning)
        }

        if icons.isEmpty, loaderResult.computedHashes.isEmpty {
            ui.warning(.noAssetsFound(
                assetType: "icons",
                frameName: loaderConfig.frameName
            ))
            return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
        }

        // 3. Get download URLs and generate export result
        let svgDir = entry.svgDirectory.map { web.output.appendingPathComponent($0) }
            ?? web.output.appendingPathComponent("assets/icons")
        let outputDir = web.output.appendingPathComponent(entry.outputDirectory)

        let output = WebOutput(
            outputDirectory: outputDir,
            iconsAssetsDirectory: svgDir,
            templatesPath: web.templatesPath
        )
        let generateReactComponents = entry.generateReactComponents ?? true
        let iconSize = entry.iconSize ?? 24
        let exporter = WebIconsExporter(
            output: output,
            generateReactComponents: generateReactComponents,
            iconSize: iconSize
        )

        // Use allNames for barrel file if granular cache is active
        let allIconNames = granularCacheManager != nil ? loaderResult.allNames : nil
        let result = try exporter.export(icons: icons, allIconNames: allIconNames)

        // 4. Download SVGs first (needed for TSX component generation)
        let remoteFiles = result.assetFiles.filter { $0.sourceURL != nil }
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        var downloadedFiles: [FileContents] = []
        if !remoteFiles.isEmpty {
            downloadedFiles = try await ui.withProgress(
                "Downloading SVG files",
                total: remoteFiles.count
            ) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, _ in
                    progress.update(current: current)
                }
            }
        }

        // 5. Build SVG data map for TSX component generation
        var svgDataMap: [String: Data] = [:]
        for file in downloadedFiles where !file.dark {
            // Extract icon name from destination file (e.g., "arrow_left.svg" -> "arrow_left")
            let fileName = file.destination.file.deletingPathExtension().lastPathComponent
            if let data = file.data {
                svgDataMap[fileName] = data
            }
        }

        // 6. Generate React TSX components with real SVG content
        let componentResult = try exporter.generateReactComponentsFromSVGData(
            icons: icons,
            svgDataMap: svgDataMap
        )

        // Log warnings for skipped icons
        if !componentResult.missingDataIcons.isEmpty {
            ui.warning(.webIconsMissingSVGData(
                count: componentResult.missingDataIcons.count,
                names: componentResult.missingDataIcons
            ))
        }
        if !componentResult.conversionFailedIcons.isEmpty {
            ui.warning(.webIconsConversionFailed(
                count: componentResult.conversionFailedIcons.count,
                names: componentResult.conversionFailedIcons.map(\.name)
            ))
        }

        // 7. Collect all files to write
        // Include both downloaded files and any local asset files (without sourceURL)
        let localAssetFiles = result.assetFiles.filter { $0.sourceURL == nil }
        var localFiles: [FileContents] = downloadedFiles + localAssetFiles
        localFiles.append(contentsOf: componentResult.files)
        if let typesFile = result.typesFile {
            localFiles.append(typesFile)
        }
        if let barrelFile = result.barrelFile {
            localFiles.append(barrelFile)
        }

        // Clear output directory if not filtering
        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: svgDir.path)
        }

        let filesToWriteFinal = localFiles
        try await ui.withSpinner("Writing files to Web project...") {
            try ExFigCommand.fileWriter.write(files: filesToWriteFinal)
        }

        await checkForUpdate(logger: ExFigCommand.logger)

        // Calculate skipped count for granular cache stats
        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - icons.count
            : 0

        ui.success("Done! Exported \(icons.count) icons to Web project.")
        return PlatformExportResult(
            count: icons.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
