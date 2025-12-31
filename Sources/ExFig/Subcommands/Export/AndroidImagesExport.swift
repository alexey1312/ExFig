import ExFigKit

// swiftlint:disable file_length
import AndroidExport
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Android Images Export

extension ExFigCommand.ExportImages {
    // swiftlint:disable function_body_length

    func exportAndroidImages(
        client: Client,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws -> PlatformExportResult {
        guard let android = params.android,
              let imagesConfig = android.images
        else {
            ui.warning(.configMissing(platform: "android", assetType: "images"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let entries = imagesConfig.entries

        if entries.count == 1 {
            return try await exportAndroidImagesEntry(
                entry: entries[0],
                android: android,
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
            try await processAndroidImagesEntries(
                entries: entries,
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func processAndroidImagesEntries(
        entries: [Params.Android.ImagesEntry],
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportAndroidImagesEntry(
                entry: entry,
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportAndroidImagesEntry(
        entry: Params.Android.ImagesEntry,
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let loaderConfig = ImagesLoaderConfig.forAndroid(entry: entry, params: params)
        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: .android,
            logger: ExFigCommand.logger,
            config: loaderConfig
        )
        loader.granularCacheProvider = granularCacheManager

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
            ui.success("All images unchanged (granular cache hit). Skipping Android export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allNames.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing images...") {
                let processor = ImagesProcessor(
                    platform: .android,
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
            try await exportAndroidSVGImagesEntry(
                images: images,
                entry: entry,
                android: android,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        case .webp where entry.sourceFormat == .svg:
            // WebP output with SVG source - rasterize locally with resvg
            try await exportAndroidSVGSourceWebpImagesEntry(
                images: images,
                entry: entry,
                android: android,
                params: params,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        case .png, .webp:
            // PNG/WebP output with PNG source from Figma
            try await exportAndroidRasterImagesEntry(
                images: images,
                entry: entry,
                android: android,
                params: params,
                granularCacheManager: granularCacheManager,
                ui: ui
            )
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        ui.success("Done! Exported \(images.count) images.")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:disable:next function_parameter_count
    func exportAndroidSVGImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Android.ImagesEntry,
        android: Params.Android,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let remoteFiles = images.flatMap { asset -> [FileContents] in
            let lightFiles = asset.light.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url)
            }
            let darkFiles = asset.dark?.images.map { image -> FileContents in
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, dark: true)
            } ?? []
            return lightFiles + darkFiles
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        var localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    // Report to batch progress if in batch mode
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            []
        }

        try ExFigCommand.fileWriter.write(files: localFiles)

        try await ui.withSpinner("Converting SVGs to vector drawables...") {
            if FileManager.default.fileExists(atPath: tempDirectoryLightURL.path) {
                try await ExFigCommand.svgFileConverter.convertAsync(inputDirectoryUrl: tempDirectoryLightURL)
            }
            if FileManager.default.fileExists(atPath: tempDirectoryDarkURL.path) {
                try await ExFigCommand.svgFileConverter.convertAsync(inputDirectoryUrl: tempDirectoryDarkURL)
            }
        }

        let lightDirectory = URL(fileURLWithPath: android.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable", isDirectory: true).path)

        let darkDirectory = URL(fileURLWithPath: android.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable-night", isDirectory: true).path)

        if filter == nil, granularCacheManager == nil {
            try? FileManager.default.removeItem(atPath: lightDirectory.path)
            try? FileManager.default.removeItem(atPath: darkDirectory.path)
        }

        localFiles = localFiles.map { fileContents -> FileContents in
            let source = fileContents.destination.url
                .deletingPathExtension()
                .appendingPathExtension("xml")

            let fileURL = fileContents.destination.file
                .deletingPathExtension()
                .appendingPathExtension("xml")

            let directory = fileContents.dark ? darkDirectory : lightDirectory

            return FileContents(
                destination: Destination(directory: directory, file: fileURL),
                dataFile: source
            )
        }

        let filesToWrite = localFiles
        try await ui.withSpinner("Writing files to Android Studio project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        try? FileManager.default.removeItem(at: tempDirectoryLightURL)
        try? FileManager.default.removeItem(at: tempDirectoryDarkURL)
    }

    // swiftlint:disable:next function_parameter_count
    func exportAndroidRasterImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Android.ImagesEntry,
        android: Params.Android,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let remoteFiles = try images.flatMap { asset -> [FileContents] in
            let lightFiles = try makeRemoteFiles(
                images: asset.light.images,
                dark: false,
                outputDirectory: tempDirectoryURL
            )
            let darkFiles = try asset.dark.flatMap { darkImagePack -> [FileContents] in
                try makeRemoteFiles(images: darkImagePack.images, dark: true, outputDirectory: tempDirectoryURL)
            } ?? []
            return lightFiles + darkFiles
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        var localFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading images", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    // Report to batch progress if in batch mode
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            []
        }

        try ExFigCommand.fileWriter.write(files: localFiles)

        if entry.format == .webp {
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
            let outputDirectory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(entry.output).path)
            try? FileManager.default.removeItem(atPath: outputDirectory.path)
        }

        let isSingleScale = entry.scales?.count == 1
        localFiles = localFiles.map { fileContents -> FileContents in
            let directoryName = Drawable.scaleToDrawableName(
                fileContents.scale,
                dark: fileContents.dark,
                singleScale: isSingleScale
            )
            let directory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(entry.output).path)
                .appendingPathComponent(directoryName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: fileContents.destination.file),
                dataFile: fileContents.destination.url
            )
        }

        let filesToWriteRaster = localFiles
        try await ui.withSpinner("Writing files to Android Studio project...") {
            try ExFigCommand.fileWriter.write(files: filesToWriteRaster)
        }

        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    // swiftlint:disable:next function_parameter_count
    func exportAndroidSVGSourceWebpImagesEntry(
        images: [AssetPair<ImagesProcessor.AssetType>],
        entry: Params.Android.ImagesEntry,
        android: Params.Android,
        params: Params,
        granularCacheManager: GranularCacheManager?,
        ui: TerminalUI
    ) async throws {
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create remote file list for SVG downloads (one SVG per image, no scales)
        let remoteFiles = try images.flatMap { asset -> [FileContents] in
            let lightFiles = try makeSVGRemoteFiles(
                images: asset.light.images,
                dark: false,
                outputDirectory: tempDirectoryURL
            )
            let darkFiles = try asset.dark.flatMap { darkImagePack -> [FileContents] in
                try makeSVGRemoteFiles(images: darkImagePack.images, dark: true, outputDirectory: tempDirectoryURL)
            } ?? []
            return lightFiles + darkFiles
        }

        // Download SVG files
        let fileDownloader = faultToleranceOptions.createFileDownloader()
        let localSVGFiles: [FileContents] = if !remoteFiles.isEmpty {
            try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                try await PipelinedDownloader.download(
                    files: remoteFiles,
                    fileDownloader: fileDownloader
                ) { current, total in
                    progress.update(current: current)
                    // Report to batch progress if in batch mode
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            []
        }

        try ExFigCommand.fileWriter.write(files: localSVGFiles)

        // Get scales for rasterization
        let scales = getScalesForPlatform(entry.scales, platform: .android)

        // Create WebP converter with appropriate encoding
        let converter = WebpConverterFactory.createSvgToWebpConverter(from: entry.webpOptions)

        // Rasterize SVGs to WebP at each scale
        let totalConversions = localSVGFiles.count * scales.count
        let webpFiles: [FileContents] = try await ui.withProgress(
            "Rasterizing SVGs to WebP",
            total: totalConversions
        ) { progress in
            var results: [FileContents] = []
            var completed = 0

            for svgFile in localSVGFiles {
                let svgData = try Data(contentsOf: svgFile.destination.url)
                let baseName = svgFile.destination.file.deletingPathExtension().lastPathComponent

                for scale in scales {
                    let webpData = try converter.convert(
                        svgData: svgData,
                        scale: scale,
                        fileName: baseName
                    )

                    // Create output file in temp directory
                    let webpFileName = URL(string: "\(baseName).webp")!
                    let scaleDir = tempDirectoryURL
                        .appendingPathComponent(svgFile.dark ? "dark" : "light")
                        .appendingPathComponent("webp")
                        .appendingPathComponent(String(scale))
                    try FileManager.default.createDirectory(at: scaleDir, withIntermediateDirectories: true)

                    let webpPath = scaleDir.appendingPathComponent(webpFileName.lastPathComponent)
                    try webpData.write(to: webpPath)

                    let fileContents = FileContents(
                        destination: Destination(directory: scaleDir, file: webpFileName),
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

        // Clear output directory if not filtering
        if filter == nil, granularCacheManager == nil {
            let outputDirectory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(entry.output).path)
            try? FileManager.default.removeItem(atPath: outputDirectory.path)
        }

        // Map to final output directories
        let isSingleScale = scales.count == 1
        let finalFiles = webpFiles.compactMap { fileContents -> FileContents? in
            guard let dataFile = fileContents.dataFile else { return nil }
            let directoryName = Drawable.scaleToDrawableName(
                fileContents.scale,
                dark: fileContents.dark,
                singleScale: isSingleScale
            )
            let directory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(entry.output).path)
                .appendingPathComponent(directoryName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: fileContents.destination.file),
                dataFile: dataFile
            )
        }

        try await ui.withSpinner("Writing files to Android Studio project...") {
            try ExFigCommand.fileWriter.write(files: finalFiles)
        }

        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    /// Creates remote file list for SVG downloads (one per image, no scale).
    func makeSVGRemoteFiles(images: [Image], dark: Bool, outputDirectory: URL) throws -> [FileContents] {
        // For SVG source, we only have one image per component (scale: .all)
        // Take the first image from each unique name
        var seenNames = Set<String>()
        return try images.compactMap { image -> FileContents? in
            guard !seenNames.contains(image.name) else { return nil }
            seenNames.insert(image.name)

            guard let name = image.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let fileURL = URL(string: "\(name).svg")
            else {
                throw ExFigError.invalidFileName(image.name)
            }

            let dest = Destination(
                directory: outputDirectory.appendingPathComponent(dark ? "dark" : "light"),
                file: fileURL
            )
            return FileContents(destination: dest, sourceURL: image.url, dark: dark)
        }
    }

    /// Gets valid scales for the given platform.
    func getScalesForPlatform(_ customScales: [Double]?, platform: Platform) -> [Double] {
        let validScales: [Double] = platform == .android ? [1, 2, 3, 1.5, 4.0] : [1, 2, 3]
        let filtered = customScales?.filter { validScales.contains($0) } ?? []
        return filtered.isEmpty ? validScales : filtered
    }

    /// Make array of remote FileContents for downloading images
    /// - Parameters:
    ///   - images: Dictionary of images. Key = scale, value = image info
    ///   - dark: Dark mode?
    ///   - outputDirectory: URL of the output directory
    func makeRemoteFiles(images: [Image], dark: Bool, outputDirectory: URL) throws -> [FileContents] {
        try images.map { image -> FileContents in
            guard let name = image.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let fileURL = URL(string: "\(name).\(image.format)")
            else {
                throw ExFigError.invalidFileName(image.name)
            }
            let scale = image.scale.value
            let dest = Destination(
                directory: outputDirectory
                    .appendingPathComponent(dark ? "dark" : "light")
                    .appendingPathComponent(String(scale)),
                file: fileURL
            )
            return FileContents(destination: dest, sourceURL: image.url, scale: scale, dark: dark)
        }
    }

    // swiftlint:enable function_body_length
}
