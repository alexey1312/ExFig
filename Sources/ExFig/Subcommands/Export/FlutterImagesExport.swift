// swiftlint:disable file_length
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

    // swiftlint:disable:next function_parameter_count
    func exportFlutterImagesEntry(
        entry: Params.Flutter.ImagesEntry,
        flutter: Params.Flutter,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
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
                    allAssetMetadata: []
                )
            }
        }

        if loaderResult.allSkipped {
            ui.success("All images unchanged (granular cache hit). Skipping Flutter export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allAssetMetadata.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing images...") {
                let processor = ImagesProcessor(
                    platform: .flutter,
                    nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                    nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                    nameStyle: .snakeCase
                )
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let imagesWarning {
            ui.warning(imagesWarning)
        }

        switch entry.format {
        case .svg:
            // SVG output format
            try await exportFlutterSVGImagesEntry(
                images: images,
                entry: entry,
                flutter: flutter,
                loaderResult: loaderResult,
                params: params,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        case .webp where entry.sourceFormat == .svg:
            // WebP output with SVG source - rasterize locally with resvg
            try await exportFlutterSVGSourceWebpImagesEntry(
                images: images,
                entry: entry,
                flutter: flutter,
                loaderResult: loaderResult,
                params: params,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        case .png, .webp, .none:
            // PNG/WebP output with PNG source from Figma
            try await exportFlutterRasterImagesEntry(
                images: images,
                entry: entry,
                flutter: flutter,
                loaderResult: loaderResult,
                params: params,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allAssetMetadata.count - images.count
            : 0

        ui.success("Done! Exported \(images.count) images to Flutter project.")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length

    // MARK: - SVG Output

    // swiftlint:disable:next function_parameter_count
    func exportFlutterSVGImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Flutter.ImagesEntry,
        flutter: Params.Flutter,
        loaderResult: ImagesLoaderResultWithHashes,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let assetsDirectory = URL(fileURLWithPath: entry.output)

        let remoteFiles = images.flatMap { asset -> [FileContents] in
            let lightFiles = asset.light.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let dest = Destination(directory: assetsDirectory, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url)
            }
            let darkFiles = asset.dark?.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let darkDir = assetsDirectory.appendingPathComponent("dark")
                let dest = Destination(directory: darkDir, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, dark: true)
            } ?? []
            return lightFiles + darkFiles
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        let localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            []
        }

        let output = FlutterOutput(
            outputDirectory: flutter.output,
            imagesAssetsDirectory: assetsDirectory,
            templatesPath: flutter.templatesPath,
            imagesClassName: entry.className
        )

        let exporter = FlutterImagesExporter(
            output: output,
            outputFileName: entry.dartFile,
            scales: [1.0], // SVG doesn't need scales
            format: "svg"
        )
        let processor = ImagesProcessor(
            platform: .flutter,
            nameValidateRegexp: params.common?.images?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
            nameStyle: .snakeCase
        )
        let allImageNames = granularCacheManager != nil
            ? processor.processNames(loaderResult.allAssetMetadata.map(\.name))
            : nil
        let (dartFile, _) = try exporter.export(images: images, allImageNames: allImageNames, assetsPath: entry.output)

        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let filesToWrite = localFiles + [dartFile]

        try await ui.withSpinner("Writing files to Flutter project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }
    }

    // MARK: - SVG Source → WebP Output

    // swiftlint:disable:next function_parameter_count function_body_length
    func exportFlutterSVGSourceWebpImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Flutter.ImagesEntry,
        flutter: Params.Flutter,
        loaderResult: ImagesLoaderResultWithHashes,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let assetsDirectory = URL(fileURLWithPath: entry.output)

        // Clear output directory before writing files
        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let remoteFiles = images.flatMap { asset -> [FileContents] in
            let lightFiles = asset.light.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let dest = Destination(directory: assetsDirectory, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url)
            }
            let darkFiles = asset.dark?.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let darkDir = assetsDirectory.appendingPathComponent("dark")
                let dest = Destination(directory: darkDir, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, dark: true)
            } ?? []
            return lightFiles + darkFiles
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        let localSVGFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            []
        }

        // Write SVG files to disk first (so we can read them for conversion)
        try ExFigCommand.fileWriter.write(files: localSVGFiles)

        // Convert SVGs to WebP (files written directly to disk)
        _ = try await convertFlutterSVGToWebp(
            localFiles: localSVGFiles,
            entry: entry,
            assetsDirectory: assetsDirectory,
            ui: ui
        )

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
            format: "webp"
        )
        let processor = ImagesProcessor(
            platform: .flutter,
            nameValidateRegexp: params.common?.images?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
            nameStyle: .snakeCase
        )
        let allImageNames = granularCacheManager != nil
            ? processor.processNames(loaderResult.allAssetMetadata.map(\.name))
            : nil
        let (dartFile, _) = try exporter.export(images: images, allImageNames: allImageNames, assetsPath: entry.output)

        // WebP files already written by convertFlutterSVGToWebp, just write Dart file
        try await ui.withSpinner("Writing files to Flutter project...") {
            try ExFigCommand.fileWriter.write(files: [dartFile])
        }
    }

    // MARK: - Raster Output (PNG/WebP with PNG source)

    // swiftlint:disable:next function_parameter_count function_body_length
    func exportFlutterRasterImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Flutter.ImagesEntry,
        flutter: Params.Flutter,
        loaderResult: ImagesLoaderResultWithHashes,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let formatString = entry.format == .webp ? "webp" : "png"
        let assetsDirectory = URL(fileURLWithPath: entry.output)

        // Clear output directory before writing files
        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

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
        let processor = ImagesProcessor(
            platform: .flutter,
            nameValidateRegexp: params.common?.images?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
            nameStyle: .snakeCase
        )
        let allImageNames = granularCacheManager != nil
            ? processor.processNames(loaderResult.allAssetMetadata.map(\.name))
            : nil
        let (dartFile, assetFiles) = try exporter.export(
            images: images,
            allImageNames: allImageNames,
            assetsPath: entry.output
        )

        let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
        let fileDownloader = faultToleranceOptions.createFileDownloader()

        var localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading images", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
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

        localFiles.append(dartFile)

        // Exclude converted PNG→WebP files (already created by WebpConverter)
        let filesToWrite = localFiles.filter { file in
            let originalPath = file.destination.url.path.replacingOccurrences(of: ".webp", with: ".png")
            return !convertedPngPaths.contains(originalPath)
        }

        try await ui.withSpinner("Writing files to Flutter project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }
    }

    // MARK: - SVG to WebP Conversion Helper

    /// Converts downloaded SVG files to WebP format using local rasterization.
    ///
    /// This method handles the case when `sourceFormat: svg` and `format: webp` are both set.
    /// Instead of using Figma's PNG export (which WebpConverter expects), we:
    /// 1. Download SVG from Figma (already done before this method is called)
    /// 2. Rasterize SVG to RGBA using resvg
    /// 3. Encode RGBA to WebP using libwebp
    ///
    /// This produces higher quality results than Figma's server-side PNG rendering.
    func convertFlutterSVGToWebp(
        localFiles: [FileContents],
        entry: Params.Flutter.ImagesEntry,
        assetsDirectory: URL,
        ui: TerminalUI
    ) async throws -> [FileContents] {
        // Get scales for rasterization (Flutter uses 1x, 2x, 3x)
        let scales = entry.scales ?? [1.0, 2.0, 3.0]

        // Create WebP converter with appropriate encoding
        let converter = WebpConverterFactory.createSvgToWebpConverter(from: entry.webpOptions)

        // Rasterize SVGs to WebP at each scale
        let totalConversions = localFiles.count * scales.count
        let webpFiles: [FileContents] = try await ui.withProgress(
            "Rasterizing SVGs to WebP",
            total: totalConversions
        ) { progress in
            var results: [FileContents] = []
            var completed = 0

            for svgFile in localFiles {
                // Read SVG data from downloaded file
                let svgData: Data = if let data = svgFile.data {
                    data
                } else {
                    try Data(contentsOf: svgFile.destination.url)
                }
                let baseName = svgFile.destination.file.deletingPathExtension().lastPathComponent

                for scale in scales {
                    let webpData = try converter.convert(
                        svgData: svgData,
                        scale: scale,
                        fileName: baseName
                    )

                    // Flutter scale directories: 1x at root, 2x at 2.0x/, 3x at 3.0x/
                    let scaleDirectory = scale == 1
                        ? assetsDirectory
                        : assetsDirectory.appendingPathComponent("\(scale)x")

                    // Ensure scale directory exists
                    try FileManager.default.createDirectory(at: scaleDirectory, withIntermediateDirectories: true)

                    // Write WebP directly to final destination
                    let darkSuffix = svgFile.dark ? "_dark" : ""
                    let webpFileName = "\(baseName)\(darkSuffix).webp"
                    let webpPath = scaleDirectory.appendingPathComponent(webpFileName)
                    try webpData.write(to: webpPath)

                    // Create FileContents for tracking (file already written to webpPath)
                    guard let fileURL = URL(string: webpFileName) else { continue }
                    let fileContents = FileContents(
                        destination: Destination(directory: scaleDirectory, file: fileURL),
                        dataFile: webpPath,
                        scale: scale,
                        dark: svgFile.dark
                    )
                    results.append(fileContents)

                    completed += 1
                    progress.update(current: completed)
                }
            }
            return results
        }

        // Delete source SVG files (they were downloaded with .svg extension)
        for svgFile in localFiles {
            try? FileManager.default.removeItem(at: svgFile.destination.url)
        }

        return webpFiles
    }
}

// swiftlint:enable file_length
