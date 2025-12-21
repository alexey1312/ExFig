import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation

// MARK: - Flutter Images Export

extension ExFigCommand.ExportImages {
    // swiftlint:disable function_body_length

    func exportFlutterImages(
        client: Client,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let flutter = params.flutter,
              let imagesConfig = flutter.images
        else {
            ui.warning(.configMissing(platform: "flutter", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let entries = imagesConfig.entries

        if entries.count == 1 {
            return try await exportFlutterImagesEntry(
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
            try await processFlutterImagesEntries(
                entries: entries,
                flutter: flutter,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func processFlutterImagesEntries(
        entries: [Params.Flutter.ImagesEntry],
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportFlutterImagesEntry(
                entry: entry,
                flutter: flutter,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportFlutterImagesEntry(
        entry: Params.Flutter.ImagesEntry,
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let formatString = switch entry.format {
        case .png, .none:
            "png"
        case .svg:
            "svg"
        case .webp:
            "webp"
        }

        let loaderConfig = ImagesLoaderConfig.forFlutter(entry: entry, params: params)
        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: .flutter,
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
                    allNames: []
                )
            }
        }

        if loaderResult.allSkipped {
            ui.success("All images unchanged (granular cache hit). Skipping Flutter export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allNames.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        let processor = ImagesProcessor(
            platform: .flutter,
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

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        let output = FlutterOutput(
            outputDirectory: flutter.output,
            imagesAssetsDirectory: assetsDirectory,
            templatesPath: flutter.templatesPath,
            imagesClassName: entry.className
        )

        let exporter = FlutterImagesExporter(
            output: output,
            outputFileName: entry.dartFile,
            scales: entry.scales,
            format: formatString
        )
        let allImageNames = granularCacheManager != nil
            ? processor.processNames(loaderResult.allNames)
            : nil
        let (dartFile, assetFiles) = try exporter.export(images: images, allImageNames: allImageNames)

        let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        var localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading images", total: remoteFiles.count) { progress in
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

        // Track which files were converted to WebP (to exclude from final write)
        var convertedPngPaths: Set<String> = []

        if entry.format == .webp {
            // Write PNG files to disk first (WebP converter reads from disk)
            try ExFigCommand.fileWriter.write(files: localFiles)
            convertedPngPaths = Set(localFiles.map(\.destination.url.path))

            let converter = WebpConverterFactory.createWebpConverter(from: entry.webpOptions)
            // Convert to proper file:// URLs (YAML-decoded URLs lack scheme)
            let filesToConvert = localFiles.map { URL(fileURLWithPath: $0.destination.url.path) }
            try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                try await converter.convertBatch(files: filesToConvert) { current, _ in
                    progress.update(current: current)
                }
            }
            // Delete source PNG files after successful conversion
            for pngFile in filesToConvert {
                try? FileManager.default.removeItem(at: pngFile)
            }
            localFiles = localFiles.map { $0.changingExtension(newExtension: "webp") }
        }

        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        localFiles.append(dartFile)

        // Exclude converted images - WebP files were already created by converter
        let filesToWrite = localFiles.filter { file in
            let originalPath = file.destination.url.path.replacingOccurrences(of: ".webp", with: ".png")
            return !convertedPngPaths.contains(originalPath)
        }
        try await ui.withSpinner("Writing files to Flutter project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        await checkForUpdate(logger: ExFigCommand.logger)

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        ui.success("Done! Exported \(images.count) images to Flutter project.")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
