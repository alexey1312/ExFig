import ExFigCore
import FigmaAPI
import Foundation
import WebExport

// MARK: - Web Images Export

extension ExFigCommand.ExportImages {
    // swiftlint:disable function_body_length

    func exportWebImages(
        client: Client,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let web = params.web, let imagesConfig = web.images else {
            ui.warning(.configMissing(platform: "web", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
        }

        // Get all entries from config (supports both single and multiple formats)
        let entries = imagesConfig.entries

        // Single entry - use direct processing (legacy behavior)
        if entries.count == 1 {
            return try await exportWebImagesEntry(
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
            try await processWebImagesEntries(
                entries: entries,
                web: web,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func processWebImagesEntries(
        entries: [Params.Web.ImagesEntry],
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportWebImagesEntry(
                entry: entry,
                web: web,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Exports images for a single Web images entry.
    // swiftlint:disable:next function_parameter_count
    func exportWebImagesEntry(
        entry: Params.Web.ImagesEntry,
        web: Params.Web,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let loaderConfig = ImagesLoaderConfig.forWeb(entry: entry, params: params)
        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: .web,
            logger: ExFigCommand.logger,
            config: loaderConfig
        )
        loader.granularCacheManager = granularCacheManager

        let loaderResult = try await ui.withSpinnerProgress("Fetching images from Figma...") { onProgress in
            if granularCacheManager != nil {
                return try await loader.loadWithGranularCache(filter: filter, onBatchProgress: onProgress)
            } else {
                let result = try await loader.load(filter: filter, onBatchProgress: onProgress)
                return ImagesLoaderResultWithHashes(
                    light: result.light,
                    dark: result.dark,
                    computedHashes: [:],
                    allSkipped: false,
                    allAssetMetadata: []
                )
            }
        }

        if loaderResult.allSkipped {
            ui.success("All images unchanged (granular cache hit). Skipping Web export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allAssetMetadata.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        let processor = ImagesProcessor(
            platform: .web,
            nameValidateRegexp: params.common?.images?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
            nameStyle: .snakeCase
        )

        let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing images...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }

        if let imagesWarning {
            ui.warning(imagesWarning)
        }

        if images.isEmpty, loaderResult.computedHashes.isEmpty {
            ui.warning(.noAssetsFound(assetType: "images", frameName: loaderConfig.frameName))
            return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
        }

        // Set up output paths
        let assetsDir = entry.assetsDirectory.map { web.output.appendingPathComponent($0) }
            ?? web.output.appendingPathComponent("assets/images")
        let outputDir = web.output.appendingPathComponent(entry.outputDirectory)

        let output = WebOutput(
            outputDirectory: outputDir,
            imagesAssetsDirectory: assetsDir,
            templatesPath: web.templatesPath
        )
        let generateReactComponents = entry.generateReactComponents ?? true
        let exporter = WebImagesExporter(output: output, generateReactComponents: generateReactComponents)

        // Use allNames for barrel file if granular cache is active
        let allImageNames = granularCacheManager != nil ? loaderResult.allAssetMetadata.map(\.name) : nil
        let result = try exporter.export(images: images, allImageNames: allImageNames)

        // Collect all files to write
        var localFiles: [FileContents] = result.componentFiles
        if let barrelFile = result.barrelFile {
            localFiles.append(barrelFile)
        }

        // Download assets if needed
        let remoteFiles = result.assetFiles.filter { $0.sourceURL != nil }
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        if !remoteFiles.isEmpty {
            let downloadedFiles = try await ui.withProgress(
                "Downloading image files",
                total: remoteFiles.count
            ) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, _ in
                    progress.update(current: current)
                }
            }
            localFiles.append(contentsOf: downloadedFiles)
        }

        // Clear output directory if not filtering
        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDir.path)
        }

        let filesToWrite = localFiles
        try await ui.withSpinner("Writing files to Web project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        await checkForUpdate(logger: ExFigCommand.logger)

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allAssetMetadata.count - images.count
            : 0

        ui.success("Done! Exported \(images.count) images to Web project.")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
