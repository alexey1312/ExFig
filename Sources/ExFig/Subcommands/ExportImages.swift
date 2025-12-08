// swiftlint:disable file_length cyclomatic_complexity
import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import XcodeExport

extension ExFigCommand {
    // swiftlint:disable:next type_body_length
    struct ExportImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "images",
            abstract: "Exports images from Figma",
            discussion: "Exports images from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: HeavyFaultToleranceOptions

        @Argument(help: """
        [Optional] Name of the images to export. For example \"img/login\" to export \
        single image, \"img/onboarding/1, img/onboarding/2\" to export several images \
        and \"img/onboarding/*\" to export all images from onboarding group
        """)
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            _ = try await performExport(client: client, ui: ui)
        }

        /// Result of images export for batch mode integration.
        struct ImagesExportResult {
            let count: Int
            let computedHashes: [String: [String: String]]
            let granularCacheStats: GranularCacheStats?
        }

        /// Result of a platform export operation with granular cache hashes.
        private struct PlatformExportResult {
            let count: Int
            let hashes: [String: [NodeId: String]]
            /// Number of images skipped by granular cache.
            let skippedCount: Int

            init(count: Int, hashes: [String: [NodeId: String]], skippedCount: Int = 0) {
                self.count = count
                self.hashes = hashes
                self.skippedCount = skippedCount
            }
        }

        /// Performs the actual export and returns the number of exported images.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: The number of images exported.
        func performExport(
            client: Client,
            ui: TerminalUI
        ) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui)
            return result.count
        }

        /// Performs export and returns full result with hashes for batch mode.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: Export result including count, hashes, and granular cache stats.
        func performExportWithResult( // swiftlint:disable:this function_body_length
            client: Client,
            ui: TerminalUI
        ) async throws -> ImagesExportResult {
            // Detect batch mode via TaskLocal
            let batchMode = SharedGranularCacheStorage.cache != nil

            // Check for version changes if cache is enabled
            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client,
                    params: options.params,
                    cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Images",
                    ui: ui,
                    logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return ImagesExportResult(count: 0, computedHashes: [:], granularCacheStats: nil)
            }

            // Check for granular cache warnings and setup
            let configCacheEnabled = options.params.common?.cache?.isEnabled ?? false
            if let warning = cacheOptions.granularCacheWarning(configEnabled: configCacheEnabled) {
                ui.warning(warning)
            }

            let granularCacheEnabled = cacheOptions.isGranularCacheEnabled(configEnabled: configCacheEnabled)

            // Clear node hashes if force flag with granular cache
            if cacheOptions.force, granularCacheEnabled {
                let fileIds = [options.params.figma.lightFileId] +
                    (options.params.figma.darkFileId.map { [$0] } ?? [])
                for fileId in fileIds {
                    try trackingManager.clearNodeHashes(fileId: fileId)
                }
            }

            let granularCacheManager: GranularCacheManager? = granularCacheEnabled
                ? trackingManager.createGranularCacheManager()
                : nil

            var totalImages = 0
            var totalSkipped = 0
            var allComputedHashes: [String: [NodeId: String]] = [:]

            if options.params.ios != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export images to Xcode project.")
                let result = try await exportiOSImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = mergeHashes(allComputedHashes, result.hashes)
            }

            if options.params.android != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export images to Android Studio project.")
                let result = try await exportAndroidImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = mergeHashes(allComputedHashes, result.hashes)
            }

            if options.params.flutter != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export images to Flutter project.")
                let result = try await exportFlutterImages(
                    client: client,
                    params: options.params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
                totalImages += result.count
                totalSkipped += result.skippedCount
                allComputedHashes = mergeHashes(allComputedHashes, result.hashes)
            }

            // Update cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Update granular cache node hashes (no-op in batch mode)
            if granularCacheEnabled {
                for (fileId, hashes) in allComputedHashes where !hashes.isEmpty {
                    try trackingManager.updateNodeHashes(fileId: fileId, hashes: hashes)
                }
            }

            // Convert NodeId keys to String for batch result
            let stringHashes = allComputedHashes.mapValues { nodeHashes in
                nodeHashes.reduce(into: [String: String]()) { result, pair in
                    result[pair.key] = pair.value
                }
            }

            // Build granular cache stats if granular cache was used
            let stats: GranularCacheStats? = granularCacheEnabled && (totalImages > 0 || totalSkipped > 0)
                ? GranularCacheStats(skipped: totalSkipped, exported: totalImages)
                : nil

            return ImagesExportResult(
                count: totalImages,
                computedHashes: stringHashes,
                granularCacheStats: stats
            )
        }

        /// Merges hash maps from multiple platform exports.
        private func mergeHashes(
            _ existing: [String: [NodeId: String]],
            _ new: [String: [NodeId: String]]
        ) -> [String: [NodeId: String]] {
            var result = existing
            for (fileId, hashes) in new {
                if let existingHashes = result[fileId] {
                    result[fileId] = existingHashes.merging(hashes) { _, new in new }
                } else {
                    result[fileId] = hashes
                }
            }
            return result
        }

        private func exportiOSImages( // swiftlint:disable:this function_body_length
            client: Client,
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws -> PlatformExportResult {
            guard let ios = params.ios,
                  let imagesParams = ios.images
            else {
                ui.warning(.configMissing(platform: "ios", assetType: "images"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // iOS uses PNG/raster images - granular cache not applicable
            // Just load normally (granular cache is handled inside loader for vector formats)
            let loader = ImagesLoader(client: client, params: params, platform: .ios, logger: logger)
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
                        allNames: [] // Not needed when not using granular cache
                    )
                }
            }

            // Early return if all images skipped by granular cache
            if loaderResult.allSkipped {
                ui.success("All images unchanged (granular cache hit). Skipping iOS export.")
                return PlatformExportResult(
                    count: 0,
                    hashes: loaderResult.computedHashes,
                    skippedCount: loaderResult.allNames.count
                )
            }

            let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

            let processor = ImagesProcessor(
                platform: .ios,
                nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                nameStyle: imagesParams.nameStyle
            )

            let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing images...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let imagesWarning {
                ui.warning(imagesWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(imagesParams.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: imagesParams.imageSwift,
                swiftUIImageExtensionURL: imagesParams.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeImagesExporter(output: output)
            // Process allNames with the same transformations applied to images
            let allAssetNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let localAndRemoteFiles = try exporter.export(
                assets: images,
                allAssetNames: allAssetNames,
                append: filter != nil
            )
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            let remoteFilesCount = localAndRemoteFiles.filter { $0.sourceURL != nil }.count
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            // Download with progress bar
            let localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading images", total: remoteFilesCount) { progress in
                    try await fileDownloader.fetch(files: localAndRemoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                localAndRemoteFiles
            }

            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: localFiles)
            }

            // Calculate skipped count for granular cache stats
            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                await checkForUpdate(logger: logger)
                ui.success("Done! Exported \(images.count) images.")
                return PlatformExportResult(
                    count: images.count,
                    hashes: loaderResult.computedHashes,
                    skippedCount: skippedCount
                )
            }

            do {
                let xcodeProject = try XcodeProjectWriter(xcodeProjPath: ios.xcodeprojPath, target: ios.target)
                try localFiles.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning(.xcodeProjectUpdateFailed)
            }

            await checkForUpdate(logger: logger)

            ui.success("Done! Exported \(images.count) images.")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        private func exportAndroidImages( // swiftlint:disable:this function_body_length
            client: Client,
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws -> PlatformExportResult {
            guard let androidImages = params.android?.images else {
                ui.warning(.configMissing(platform: "android", assetType: "images"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // Android SVG format uses granular cache; PNG/WebP don't
            let loader = ImagesLoader(client: client, params: params, platform: .android, logger: logger)
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
                        allNames: [] // Not needed when not using granular cache
                    )
                }
            }

            // Early return if all images skipped by granular cache
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

            switch androidImages.format {
            case .svg:
                try await exportAndroidSVGImages(
                    images: images,
                    params: params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
            case .png, .webp:
                try await exportAndroidRasterImages(
                    images: images,
                    params: params,
                    granularCacheManager: granularCacheManager,
                    ui: ui
                )
            }

            await checkForUpdate(logger: logger)

            // Calculate skipped count for granular cache stats
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

        // swiftlint:disable:next function_body_length
        private func exportAndroidSVGImages(
            images: [AssetPair<ImagesProcessor.AssetType>],
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws {
            guard let android = params.android, let androidImages = android.images else {
                ui.warning(.configMissing(platform: "android", assetType: "images"))
                return
            }

            // Create empty temp directory
            let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // Download SVG files to user's temp directory
            let remoteFiles = images.flatMap { asset -> [FileContents] in
                let lightFiles = asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url)
                }
                let darkFiles = asset.dark?.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, dark: true)
                } ?? []
                return lightFiles + darkFiles
            }

            let fileDownloader = faultToleranceOptions.createFileDownloader()
            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Move downloaded SVG files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // Convert all SVG to XML files
            try await ui.withSpinner("Converting SVGs to vector drawables...") {
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryLightURL)
                if images.first?.dark != nil {
                    try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryDarkURL)
                }
            }

            // Create output directory main/res/drawable/
            let lightDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable", isDirectory: true).path)

            let darkDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable-night", isDirectory: true).path)

            if filter == nil, granularCacheManager == nil {
                // Clear output directory
                try? FileManager.default.removeItem(atPath: lightDirectory.path)
                try? FileManager.default.removeItem(atPath: darkDirectory.path)
            }

            // Move XML files to main/res/drawable/
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
                try fileWriter.write(files: filesToWrite)
            }

            try? FileManager.default.removeItem(at: tempDirectoryLightURL)
            try? FileManager.default.removeItem(at: tempDirectoryDarkURL)
        }

        // swiftlint:disable:next function_body_length
        private func exportAndroidRasterImages(
            images: [AssetPair<ImagesProcessor.AssetType>],
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws {
            guard let android = params.android, let androidImages = android.images else {
                ui.warning(.configMissing(platform: "android", assetType: "images"))
                return
            }

            // Create empty temp directory
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // Download files to user's temp directory
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
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Move downloaded files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // Convert to WebP
            if androidImages.format == .webp, let options = androidImages.webpOptions {
                let converter: WebpConverter
                switch (options.encoding, options.quality) {
                case (.lossless, _):
                    converter = WebpConverter(encoding: .lossless)
                case let (.lossy, quality?):
                    converter = WebpConverter(encoding: .lossy(quality: quality))
                case (.lossy, .none):
                    throw ExFigError.configurationError(
                        "WebP encoding quality not specified. Set android.images.webpOptions.quality in YAML file."
                    )
                }
                let filesToConvert = localFiles.map(\.destination.url)
                try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        progress.update(current: current)
                    }
                }
                localFiles = localFiles.map { $0.changingExtension(newExtension: "webp") }
            }

            if filter == nil, granularCacheManager == nil {
                // Clear output directory
                let outputDirectory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output)
                    .path)
                try? FileManager.default.removeItem(atPath: outputDirectory.path)
            }

            // Move PNG/WebP files to main/res/exfig-images/drawable-XXXdpi/
            let isSingleScale = params.android?.images?.scales?.count == 1
            localFiles = localFiles.map { fileContents -> FileContents in
                let directoryName = Drawable.scaleToDrawableName(
                    fileContents.scale,
                    dark: fileContents.dark,
                    singleScale: isSingleScale
                )
                let directory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output).path)
                    .appendingPathComponent(directoryName, isDirectory: true)
                return FileContents(
                    destination: Destination(directory: directory, file: fileContents.destination.file),
                    dataFile: fileContents.destination.url
                )
            }

            let filesToWriteRaster = localFiles
            try await ui.withSpinner("Writing files to Android Studio project...") {
                try fileWriter.write(files: filesToWriteRaster)
            }

            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        /// Make array of remote FileContents for downloading images
        /// - Parameters:
        ///   - images: Dictionary of images. Key = scale, value = image info
        ///   - dark: Dark mode?
        ///   - outputDirectory: URL of the output directory
        private func makeRemoteFiles(images: [Image], dark: Bool, outputDirectory: URL) throws -> [FileContents] {
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

        private func exportFlutterImages( // swiftlint:disable:this function_body_length
            client: Client,
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws -> PlatformExportResult {
            guard let flutter = params.flutter, let flutterImages = flutter.images else {
                ui.warning(.configMissing(platform: "flutter", assetType: "images"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // Determine format
            let formatString = switch flutterImages.format {
            case .png, .none:
                "png"
            case .svg:
                "svg"
            case .webp:
                "webp"
            }

            // 1. Get Images info (Flutter uses .android platform for similar loading behavior)
            let loader = ImagesLoader(client: client, params: params, platform: .android, logger: logger)
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
                        allNames: [] // Not needed when not using granular cache
                    )
                }
            }

            // Early return if all images skipped by granular cache
            if loaderResult.allSkipped {
                ui.success("All images unchanged (granular cache hit). Skipping Flutter export.")
                return PlatformExportResult(
                    count: 0,
                    hashes: loaderResult.computedHashes,
                    skippedCount: loaderResult.allNames.count
                )
            }

            let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

            // 2. Process images
            let processor = ImagesProcessor(
                platform: .android, // Flutter uses similar naming to Android
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

            // 3. Export images
            let assetsDirectory = URL(fileURLWithPath: flutterImages.output)
            let output = FlutterOutput(
                outputDirectory: flutter.output,
                imagesAssetsDirectory: assetsDirectory,
                templatesPath: flutter.templatesPath,
                imagesClassName: flutterImages.className
            )

            let exporter = FlutterImagesExporter(
                output: output,
                outputFileName: flutterImages.dartFile,
                scales: flutterImages.scales,
                format: formatString
            )
            // Process allNames with the same transformations applied to images
            let allImageNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let (dartFile, assetFiles) = try exporter.export(images: images, allImageNames: allImageNames)

            // 4. Download image files
            let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading images", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Convert to WebP if needed
            if flutterImages.format == .webp, let options = flutterImages.webpOptions {
                let converter: WebpConverter
                switch (options.encoding, options.quality) {
                case (.lossless, _):
                    converter = WebpConverter(encoding: .lossless)
                case let (.lossy, quality?):
                    converter = WebpConverter(encoding: .lossy(quality: quality))
                case (.lossy, .none):
                    throw ExFigError.configurationError(
                        "WebP encoding quality not specified. Set flutter.images.webpOptions.quality in YAML file."
                    )
                }
                let filesToConvert = localFiles.map(\.destination.url)
                try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        progress.update(current: current)
                    }
                }
                localFiles = localFiles.map { $0.changingExtension(newExtension: "webp") }
            }

            // Clear output directory if not filtering
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsDirectory.path)
            }

            // 5. Write files
            localFiles.append(dartFile)

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Flutter project...") {
                try fileWriter.write(files: filesToWrite)
            }

            await checkForUpdate(logger: logger)

            // Calculate skipped count for granular cache stats
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
    }
}
