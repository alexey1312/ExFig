// swiftlint:disable file_length cyclomatic_complexity
import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import WebExport
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
            let fileVersions: [FileVersionInfo]?
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
                return ImagesExportResult(count: 0, computedHashes: [:], granularCacheStats: nil, fileVersions: nil)
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
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export images to Xcode project.")
                }
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
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export images to Android Studio project.")
                }
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
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export images to Flutter project.")
                }
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

            if options.params.web != nil {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export images to Web project.")
                }
                let result = try await exportWebImages(
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
                granularCacheStats: stats,
                fileVersions: batchMode ? fileVersions : nil
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

        private func exportiOSImages(
            client: Client,
            params: Params,
            granularCacheManager: GranularCacheManager?,
            ui: TerminalUI
        ) async throws -> PlatformExportResult {
            guard let ios = params.ios,
                  let imagesConfig = ios.images
            else {
                ui.warning(.configMissing(platform: "ios", assetType: "images"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // Get all entries from config (supports both single and multiple formats)
            let entries = imagesConfig.entries

            // Single entry - use direct processing (legacy behavior)
            if entries.count == 1 {
                return try await exportiOSImagesEntry(
                    entry: entries[0],
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }

            // Multiple entries - pre-fetch Components once for all entries
            let needsLocalPreFetch = PreFetchedComponentsStorage.components == nil

            if needsLocalPreFetch {
                var componentsMap: [String: [Component]] = [:]
                let fileIds = Set([params.figma.lightFileId] + (params.figma.darkFileId.map { [$0] } ?? []))

                for fileId in fileIds {
                    let components = try await client.request(ComponentsEndpoint(fileId: fileId))
                    componentsMap[fileId] = components
                }

                let preFetched = PreFetchedComponents(components: componentsMap)

                return try await PreFetchedComponentsStorage.$components.withValue(preFetched) {
                    try await processIOSImagesEntries(
                        entries: entries,
                        ios: ios,
                        client: client,
                        params: params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
            } else {
                return try await processIOSImagesEntries(
                    entries: entries,
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }
        }

        // Helper to process multiple iOS images entries sequentially.
        // swiftlint:disable:next function_parameter_count
        private func processIOSImagesEntries(
            entries: [Params.iOS.ImagesEntry],
            ios: Params.iOS,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            var totalCount = 0
            var totalSkipped = 0
            var allHashes: [String: [NodeId: String]] = [:]

            for entry in entries {
                let result = try await exportiOSImagesEntry(
                    entry: entry,
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalCount += result.count
                totalSkipped += result.skippedCount
                allHashes = mergeHashes(allHashes, result.hashes)
            }

            return PlatformExportResult(
                count: totalCount,
                hashes: allHashes,
                skippedCount: totalSkipped
            )
        }

        // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
        private func exportiOSImagesEntry(
            entry: Params.iOS.ImagesEntry,
            ios: Params.iOS,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            // Check if HEIC output requested but not available
            let effectiveOutputFormat = resolveOutputFormat(entry: entry, ui: ui)

            // Branch based on source format and output format
            if entry.sourceFormat == .svg {
                if effectiveOutputFormat == .heic {
                    return try await exportiOSSVGSourceHeicImagesEntry(
                        entry: entry,
                        ios: ios,
                        client: client,
                        params: params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
                return try await exportiOSSVGSourceImagesEntry(
                    entry: entry,
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }

            // PNG source with HEIC output
            if effectiveOutputFormat == .heic {
                return try await exportiOSPngSourceHeicImagesEntry(
                    entry: entry,
                    ios: ios,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }

            let loaderConfig = ImagesLoaderConfig.forIOS(entry: entry, params: params)
            let loader = ImagesLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger,
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
                nameStyle: entry.nameStyle
            )

            let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing images...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let imagesWarning {
                ui.warning(imagesWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: entry.imageSwift,
                swiftUIImageExtensionURL: entry.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeImagesExporter(output: output)
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

            let localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading images", total: remoteFilesCount) { progress in
                    try await PipelinedDownloader.download(
                        files: localAndRemoteFiles,
                        fileDownloader: fileDownloader
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                localAndRemoteFiles
            }

            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: localFiles)
            }

            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                if BatchProgressViewStorage.progressView == nil {
                    await checkForUpdate(logger: logger)
                }
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

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(images.count) images.")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // MARK: - iOS SVG Source Export

        // swiftlint:disable:next function_body_length function_parameter_count cyclomatic_complexity
        private func exportiOSSVGSourceImagesEntry(
            entry: Params.iOS.ImagesEntry,
            ios: Params.iOS,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            let loaderConfig = ImagesLoaderConfig.forIOS(entry: entry, params: params)
            let loader = ImagesLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger,
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
                nameStyle: entry.nameStyle
            )

            let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing images...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let imagesWarning {
                ui.warning(imagesWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

            // Collect SVG URLs for download
            let svgRemoteFiles = makeSVGRemoteFilesForIOS(
                images: images,
                assetsURL: assetsURL
            )

            // Download SVG files
            let fileDownloader = faultToleranceOptions.createFileDownloader()
            let downloadedSVGs: [FileContents] = if !svgRemoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVGs from Figma", total: svgRemoteFiles.count) { progress in
                    try await PipelinedDownloader.download(
                        files: svgRemoteFiles,
                        fileDownloader: fileDownloader
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // iOS uses 1x, 2x, 3x scales
            let scales: [Double] = entry.scales ?? [1.0, 2.0, 3.0]
            let converter = SvgToPngConverter()

            // Clear existing assets if not filtering and not using granular cache
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            // Rasterize SVGs to PNG at each scale
            let pngFiles: [FileContents] = try await ui.withProgress(
                "Rasterizing SVGs to PNG",
                total: downloadedSVGs.count * scales.count
            ) { progress in
                var results: [FileContents] = []

                for fileContents in downloadedSVGs {
                    guard let svgData = fileContents.data else { continue }
                    let baseName = fileContents.destination.file.deletingPathExtension().lastPathComponent
                    let imagesetDir = fileContents.destination.file.deletingLastPathComponent()

                    for scale in scales {
                        let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                        let pngFileName = "\(baseName)\(scaleSuffix).png"

                        do {
                            let pngData = try converter.convert(
                                svgData: svgData,
                                scale: scale,
                                fileName: baseName
                            )

                            results.append(FileContents(
                                destination: Destination(
                                    directory: imagesetDir,
                                    file: URL(fileURLWithPath: pngFileName)
                                ),
                                data: pngData
                            ))
                        } catch {
                            logger.error("Failed to rasterize \(baseName) at \(scale)x: \(error)")
                            throw error
                        }

                        progress.increment()
                    }
                }

                return results
            }

            // Generate Contents.json for each imageset
            let contentsJsonFiles = makeImagesetContentsJson(
                for: images,
                scales: scales,
                assetsURL: assetsURL
            )

            // Generate folder Contents.json
            let folderContentsFile = FileContents(
                destination: Destination(
                    directory: assetsURL,
                    file: URL(fileURLWithPath: "Contents.json")
                ),
                data: Data(#"{"info":{"author":"xcode","version":1}}"#.utf8)
            )

            // Combine all files to write
            var allFiles = pngFiles + contentsJsonFiles
            allFiles.append(folderContentsFile)

            // Generate Swift extensions
            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: entry.imageSwift,
                swiftUIImageExtensionURL: entry.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeImagesExporter(output: output)
            let allAssetNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let extensionFiles = try exporter.exportSwiftExtensions(
                assets: images,
                allAssetNames: allAssetNames,
                append: filter != nil
            )
            allFiles.append(contentsOf: extensionFiles)

            let filesToWrite = allFiles
            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: filesToWrite)
            }

            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                if BatchProgressViewStorage.progressView == nil {
                    await checkForUpdate(logger: logger)
                }
                ui.success("Done! Exported \(images.count) images (SVG source).")
                return PlatformExportResult(
                    count: images.count,
                    hashes: loaderResult.computedHashes,
                    skippedCount: skippedCount
                )
            }

            do {
                let xcodeProject = try XcodeProjectWriter(xcodeProjPath: ios.xcodeprojPath, target: ios.target)
                try allFiles.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning(.xcodeProjectUpdateFailed)
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(images.count) images (SVG source).")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        /// Creates remote file references for SVG downloads (iOS).
        private func makeSVGRemoteFilesForIOS(
            images: [AssetPair<ImagePack>],
            assetsURL: URL
        ) -> [FileContents] {
            var files: [FileContents] = []

            for pair in images {
                // Light variant
                if let image = pair.light.images.first {
                    let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")
                    files.append(FileContents(
                        destination: Destination(
                            directory: imagesetDir,
                            file: URL(fileURLWithPath: "\(pair.light.name).svg")
                        ),
                        sourceURL: image.url
                    ))
                }

                // Dark variant (if exists) - must use same imageset directory as light
                if let dark = pair.dark, let image = dark.images.first {
                    let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")
                    files.append(FileContents(
                        destination: Destination(
                            directory: imagesetDir,
                            file: URL(fileURLWithPath: "\(pair.light.name)_dark.svg")
                        ),
                        sourceURL: image.url
                    ))
                }
            }

            return files
        }

        /// Creates Contents.json files for each imageset.
        private func makeImagesetContentsJson(
            for images: [AssetPair<ImagePack>],
            scales: [Double],
            assetsURL: URL
        ) -> [FileContents] {
            var files: [FileContents] = []

            for pair in images {
                let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")

                var imagesArray: [[String: Any]] = []

                // Add light variants at each scale
                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                    imagesArray.append([
                        "filename": "\(pair.light.name)\(scaleSuffix).png",
                        "idiom": "universal",
                        "scale": scaleString,
                    ])
                }

                // Add dark variants if they exist
                if pair.dark != nil {
                    for scale in scales {
                        let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                        let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                        imagesArray.append([
                            "appearances": [["appearance": "luminosity", "value": "dark"]],
                            "filename": "\(pair.light.name)_dark\(scaleSuffix).png",
                            "idiom": "universal",
                            "scale": scaleString,
                        ])
                    }
                }

                let contentsJson: [String: Any] = [
                    "images": imagesArray,
                    "info": ["author": "xcode", "version": 1],
                ]

                if let jsonData = try? JSONSerialization.data(
                    withJSONObject: contentsJson,
                    options: [.prettyPrinted, .sortedKeys]
                ) {
                    files.append(FileContents(
                        destination: Destination(
                            directory: imagesetDir,
                            file: URL(fileURLWithPath: "Contents.json")
                        ),
                        data: jsonData
                    ))
                }
            }

            return files
        }

        // MARK: - iOS HEIC Export Helpers

        /// Resolves the effective output format, falling back to PNG if HEIC is unavailable.
        private func resolveOutputFormat(
            entry: Params.iOS.ImagesEntry,
            ui: TerminalUI
        ) -> Params.ImageOutputFormat {
            guard entry.outputFormat == .heic else {
                return entry.outputFormat ?? .png
            }

            // Check if HEIC encoding is available on this platform
            guard NativeHeicEncoder.isAvailable() else {
                ui.warning(.heicUnavailableFallingBackToPng)
                return .png
            }

            return .heic
        }

        /// Creates Contents.json files for each imageset with HEIC extension.
        private func makeImagesetContentsJsonForHeic(
            for images: [AssetPair<ImagePack>],
            scales: [Double],
            assetsURL: URL
        ) -> [FileContents] {
            var files: [FileContents] = []

            for pair in images {
                let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")

                var imagesArray: [[String: Any]] = []

                // Add light variants at each scale
                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                    imagesArray.append([
                        "filename": "\(pair.light.name)\(scaleSuffix).heic",
                        "idiom": "universal",
                        "scale": scaleString,
                    ])
                }

                // Add dark variants if they exist
                if pair.dark != nil {
                    for scale in scales {
                        let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                        let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                        imagesArray.append([
                            "appearances": [["appearance": "luminosity", "value": "dark"]],
                            "filename": "\(pair.light.name)_dark\(scaleSuffix).heic",
                            "idiom": "universal",
                            "scale": scaleString,
                        ])
                    }
                }

                let contentsJson: [String: Any] = [
                    "images": imagesArray,
                    "info": ["author": "xcode", "version": 1],
                ]

                if let jsonData = try? JSONSerialization.data(
                    withJSONObject: contentsJson,
                    options: [.prettyPrinted, .sortedKeys]
                ) {
                    files.append(FileContents(
                        destination: Destination(
                            directory: imagesetDir,
                            file: URL(fileURLWithPath: "Contents.json")
                        ),
                        data: jsonData
                    ))
                }
            }

            return files
        }

        /// Creates a HEIC converter from iOS images entry options.
        private func createHeicConverter(from entry: Params.iOS.ImagesEntry) -> HeicConverter {
            let options = entry.heicOptions
            let quality = options?.resolvedQuality ?? 90
            let isLossless = options?.resolvedEncoding == .lossless

            if isLossless {
                return HeicConverter(encoding: .lossless)
            } else {
                return HeicConverter(encoding: .lossy(quality: quality))
            }
        }

        /// Creates an SVG to HEIC converter from iOS images entry options.
        private func createSvgToHeicConverter(from entry: Params.iOS.ImagesEntry) -> SvgToHeicConverter {
            let options = entry.heicOptions
            let quality = options?.resolvedQuality ?? 90
            let isLossless = options?.resolvedEncoding == .lossless

            if isLossless {
                return SvgToHeicConverter(encoding: .lossless)
            } else {
                return SvgToHeicConverter(encoding: .lossy(quality: quality))
            }
        }

        // MARK: - iOS SVG Source + HEIC Output Export

        // swiftlint:disable:next function_body_length function_parameter_count cyclomatic_complexity
        private func exportiOSSVGSourceHeicImagesEntry(
            entry: Params.iOS.ImagesEntry,
            ios: Params.iOS,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            let loaderConfig = ImagesLoaderConfig.forIOS(entry: entry, params: params)
            let loader = ImagesLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger,
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
                nameStyle: entry.nameStyle
            )

            let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing images...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let imagesWarning {
                ui.warning(imagesWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

            // Collect SVG URLs for download
            let svgRemoteFiles = makeSVGRemoteFilesForIOS(
                images: images,
                assetsURL: assetsURL
            )

            // Download SVG files
            let fileDownloader = faultToleranceOptions.createFileDownloader()
            let downloadedSVGs: [FileContents] = if !svgRemoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVGs from Figma", total: svgRemoteFiles.count) { progress in
                    try await PipelinedDownloader.download(
                        files: svgRemoteFiles,
                        fileDownloader: fileDownloader
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // iOS uses 1x, 2x, 3x scales
            let scales: [Double] = entry.scales ?? [1.0, 2.0, 3.0]
            let converter = createSvgToHeicConverter(from: entry)

            // Clear existing assets if not filtering and not using granular cache
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            // Rasterize SVGs to HEIC at each scale
            let heicFiles: [FileContents] = try await ui.withProgress(
                "Rasterizing SVGs to HEIC",
                total: downloadedSVGs.count * scales.count
            ) { progress in
                var results: [FileContents] = []

                for fileContents in downloadedSVGs {
                    guard let svgData = fileContents.data else { continue }
                    let baseName = fileContents.destination.file.deletingPathExtension().lastPathComponent
                    let imagesetDir = fileContents.destination.file.deletingLastPathComponent()

                    for scale in scales {
                        let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                        let heicFileName = "\(baseName)\(scaleSuffix).heic"

                        do {
                            let heicData = try converter.convert(
                                svgData: svgData,
                                scale: scale,
                                fileName: baseName
                            )

                            results.append(FileContents(
                                destination: Destination(
                                    directory: imagesetDir,
                                    file: URL(fileURLWithPath: heicFileName)
                                ),
                                data: heicData
                            ))
                        } catch {
                            logger.error("Failed to rasterize \(baseName) at \(scale)x: \(error)")
                            throw error
                        }

                        progress.increment()
                    }
                }

                return results
            }

            // Generate Contents.json for each imageset (with .heic extension)
            let contentsJsonFiles = makeImagesetContentsJsonForHeic(
                for: images,
                scales: scales,
                assetsURL: assetsURL
            )

            // Generate folder Contents.json
            let folderContentsFile = FileContents(
                destination: Destination(
                    directory: assetsURL,
                    file: URL(fileURLWithPath: "Contents.json")
                ),
                data: Data(#"{"info":{"author":"xcode","version":1}}"#.utf8)
            )

            // Combine all files to write
            var allFiles = heicFiles + contentsJsonFiles
            allFiles.append(folderContentsFile)

            // Generate Swift extensions
            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: entry.imageSwift,
                swiftUIImageExtensionURL: entry.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeImagesExporter(output: output)
            let allAssetNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let extensionFiles = try exporter.exportSwiftExtensions(
                assets: images,
                allAssetNames: allAssetNames,
                append: filter != nil
            )
            allFiles.append(contentsOf: extensionFiles)

            let filesToWrite = allFiles
            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: filesToWrite)
            }

            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                if BatchProgressViewStorage.progressView == nil {
                    await checkForUpdate(logger: logger)
                }
                ui.success("Done! Exported \(images.count) images (SVG source, HEIC output).")
                return PlatformExportResult(
                    count: images.count,
                    hashes: loaderResult.computedHashes,
                    skippedCount: skippedCount
                )
            }

            do {
                let xcodeProject = try XcodeProjectWriter(xcodeProjPath: ios.xcodeprojPath, target: ios.target)
                try allFiles.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning(.xcodeProjectUpdateFailed)
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(images.count) images (SVG source, HEIC output).")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // MARK: - iOS PNG Source + HEIC Output Export

        // swiftlint:disable:next function_body_length function_parameter_count cyclomatic_complexity
        private func exportiOSPngSourceHeicImagesEntry(
            entry: Params.iOS.ImagesEntry,
            ios: Params.iOS,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            let loaderConfig = ImagesLoaderConfig.forIOS(entry: entry, params: params)
            let loader = ImagesLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger,
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
                nameStyle: entry.nameStyle
            )

            let (images, imagesWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing images...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let imagesWarning {
                ui.warning(imagesWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: entry.imageSwift,
                swiftUIImageExtensionURL: entry.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            // Use HEIC-aware exporter
            let exporter = XcodeImagesExporter(output: output)
            let allAssetNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let localAndRemoteFiles = try exporter.exportForHeic(
                assets: images,
                allAssetNames: allAssetNames,
                append: filter != nil
            )
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            let remoteFilesCount = localAndRemoteFiles.filter { $0.sourceURL != nil }.count
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            var localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading images", total: remoteFilesCount) { progress in
                    try await PipelinedDownloader.download(
                        files: localAndRemoteFiles,
                        fileDownloader: fileDownloader
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                localAndRemoteFiles
            }

            // Convert PNGs to HEIC
            let pngFiles = localFiles.filter { $0.destination.file.pathExtension == "png" }
            if !pngFiles.isEmpty {
                let converter = createHeicConverter(from: entry)
                let filesToConvert = pngFiles.map(\.destination.url)
                try await ui.withProgress("Converting to HEIC", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        progress.update(current: current)
                    }
                }
                // Update file references to use .heic extension
                localFiles = localFiles.map { file in
                    if file.destination.file.pathExtension == "png" {
                        return file.changingExtension(newExtension: "heic")
                    }
                    return file
                }
            }

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: filesToWrite)
            }

            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                if BatchProgressViewStorage.progressView == nil {
                    await checkForUpdate(logger: logger)
                }
                ui.success("Done! Exported \(images.count) images (HEIC output).")
                return PlatformExportResult(
                    count: images.count,
                    hashes: loaderResult.computedHashes,
                    skippedCount: skippedCount
                )
            }

            do {
                let xcodeProject = try XcodeProjectWriter(xcodeProjPath: ios.xcodeprojPath, target: ios.target)
                try filesToWrite.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning(.xcodeProjectUpdateFailed)
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(images.count) images (HEIC output).")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        private func exportAndroidImages(
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

            let needsLocalPreFetch = PreFetchedComponentsStorage.components == nil

            if needsLocalPreFetch {
                var componentsMap: [String: [Component]] = [:]
                let fileIds = Set([params.figma.lightFileId] + (params.figma.darkFileId.map { [$0] } ?? []))

                for fileId in fileIds {
                    let components = try await client.request(ComponentsEndpoint(fileId: fileId))
                    componentsMap[fileId] = components
                }

                let preFetched = PreFetchedComponents(components: componentsMap)

                return try await PreFetchedComponentsStorage.$components.withValue(preFetched) {
                    try await processAndroidImagesEntries(
                        entries: entries,
                        android: android,
                        client: client,
                        params: params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
            } else {
                return try await processAndroidImagesEntries(
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
        private func processAndroidImagesEntries(
            entries: [Params.Android.ImagesEntry],
            android: Params.Android,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            var totalCount = 0
            var totalSkipped = 0
            var allHashes: [String: [NodeId: String]] = [:]

            for entry in entries {
                let result = try await exportAndroidImagesEntry(
                    entry: entry,
                    android: android,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalCount += result.count
                totalSkipped += result.skippedCount
                allHashes = mergeHashes(allHashes, result.hashes)
            }

            return PlatformExportResult(
                count: totalCount,
                hashes: allHashes,
                skippedCount: totalSkipped
            )
        }

        // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
        private func exportAndroidImagesEntry(
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
                logger: logger,
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
                await checkForUpdate(logger: logger)
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

        // swiftlint:disable:next function_body_length function_parameter_count
        private func exportAndroidSVGImagesEntry(
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
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            try fileWriter.write(files: localFiles)

            try await ui.withSpinner("Converting SVGs to vector drawables...") {
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryLightURL)
                if images.first?.dark != nil {
                    try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryDarkURL)
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
                try fileWriter.write(files: filesToWrite)
            }

            try? FileManager.default.removeItem(at: tempDirectoryLightURL)
            try? FileManager.default.removeItem(at: tempDirectoryDarkURL)
        }

        // swiftlint:disable:next function_body_length function_parameter_count
        private func exportAndroidRasterImagesEntry(
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
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            try fileWriter.write(files: localFiles)

            if entry.format == .webp {
                let converter = createWebpConverter(from: entry.webpOptions)
                let filesToConvert = localFiles.map(\.destination.url)
                try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        progress.update(current: current)
                    }
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
                try fileWriter.write(files: filesToWriteRaster)
            }

            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        // swiftlint:disable:next function_body_length function_parameter_count
        private func exportAndroidSVGSourceWebpImagesEntry(
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
                    ) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            try fileWriter.write(files: localSVGFiles)

            // Get scales for rasterization
            let scales = getScalesForPlatform(entry.scales, platform: .android)

            // Create WebP converter with appropriate encoding
            let converter = createSvgToWebpConverter(from: entry.webpOptions)

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
                try fileWriter.write(files: finalFiles)
            }

            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        /// Creates remote file list for SVG downloads (one per image, no scale).
        private func makeSVGRemoteFiles(images: [Image], dark: Bool, outputDirectory: URL) throws -> [FileContents] {
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
        private func getScalesForPlatform(_ customScales: [Double]?, platform: Platform) -> [Double] {
            let validScales: [Double] = platform == .android ? [1, 2, 3, 1.5, 4.0] : [1, 2, 3]
            let filtered = customScales?.filter { validScales.contains($0) } ?? []
            return filtered.isEmpty ? validScales : filtered
        }

        /// Creates an SVG to WebP converter from format options.
        private func createSvgToWebpConverter(from options: Params.Android.Images
            .FormatOptions?) -> SvgToWebpConverter
        {
            guard let options else {
                // Default: lossy with quality 90
                return SvgToWebpConverter(encoding: .lossy(quality: 90))
            }

            switch (options.encoding, options.quality) {
            case (.lossless, _):
                return SvgToWebpConverter(encoding: .lossless)
            case let (.lossy, quality?):
                return SvgToWebpConverter(encoding: .lossy(quality: quality))
            case (.lossy, .none):
                return SvgToWebpConverter(encoding: .lossy(quality: 90))
            }
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

        private func exportFlutterImages(
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

            let needsLocalPreFetch = PreFetchedComponentsStorage.components == nil

            if needsLocalPreFetch {
                var componentsMap: [String: [Component]] = [:]
                let fileIds = Set([params.figma.lightFileId] + (params.figma.darkFileId.map { [$0] } ?? []))

                for fileId in fileIds {
                    let components = try await client.request(ComponentsEndpoint(fileId: fileId))
                    componentsMap[fileId] = components
                }

                let preFetched = PreFetchedComponents(components: componentsMap)

                return try await PreFetchedComponentsStorage.$components.withValue(preFetched) {
                    try await processFlutterImagesEntries(
                        entries: entries,
                        flutter: flutter,
                        client: client,
                        params: params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
            } else {
                return try await processFlutterImagesEntries(
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
        private func processFlutterImagesEntries(
            entries: [Params.Flutter.ImagesEntry],
            flutter: Params.Flutter,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            var totalCount = 0
            var totalSkipped = 0
            var allHashes: [String: [NodeId: String]] = [:]

            for entry in entries {
                let result = try await exportFlutterImagesEntry(
                    entry: entry,
                    flutter: flutter,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalCount += result.count
                totalSkipped += result.skippedCount
                allHashes = mergeHashes(allHashes, result.hashes)
            }

            return PlatformExportResult(
                count: totalCount,
                hashes: allHashes,
                skippedCount: totalSkipped
            )
        }

        // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
        private func exportFlutterImagesEntry(
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
                logger: logger,
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

            if entry.format == .webp {
                let converter = createWebpConverter(from: entry.webpOptions)
                let filesToConvert = localFiles.map(\.destination.url)
                try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        progress.update(current: current)
                    }
                }
                localFiles = localFiles.map { $0.changingExtension(newExtension: "webp") }
            }

            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsDirectory.path)
            }

            localFiles.append(dartFile)

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Flutter project...") {
                try fileWriter.write(files: filesToWrite)
            }

            await checkForUpdate(logger: logger)

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

        // MARK: - Web Images Export

        private func exportWebImages(
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

            // Multiple entries - need to pre-fetch components if not already done
            let needsLocalPreFetch = PreFetchedComponentsStorage.components == nil

            if needsLocalPreFetch {
                var componentsMap: [String: [Component]] = [:]
                let fileIds = Set([params.figma.lightFileId] + (params.figma.darkFileId.map { [$0] } ?? []))

                for fileId in fileIds {
                    let components = try await client.request(ComponentsEndpoint(fileId: fileId))
                    componentsMap[fileId] = components
                }

                let preFetched = PreFetchedComponents(components: componentsMap)

                return try await PreFetchedComponentsStorage.$components.withValue(preFetched) {
                    try await processWebImagesEntries(
                        entries: entries,
                        web: web,
                        client: client,
                        params: params,
                        ui: ui,
                        granularCacheManager: granularCacheManager
                    )
                }
            } else {
                return try await processWebImagesEntries(
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
        private func processWebImagesEntries(
            entries: [Params.Web.ImagesEntry],
            web: Params.Web,
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            var totalCount = 0
            var totalSkipped = 0
            var allHashes: [String: [NodeId: String]] = [:]

            for entry in entries {
                let result = try await exportWebImagesEntry(
                    entry: entry,
                    web: web,
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalCount += result.count
                totalSkipped += result.skippedCount
                allHashes = mergeHashes(allHashes, result.hashes)
            }

            return PlatformExportResult(
                count: totalCount,
                hashes: allHashes,
                skippedCount: totalSkipped
            )
        }

        // Exports images for a single Web images entry.
        // swiftlint:disable:next function_body_length function_parameter_count
        private func exportWebImagesEntry(
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
                logger: logger,
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
                ui.success("All images unchanged (granular cache hit). Skipping Web export.")
                return PlatformExportResult(
                    count: 0,
                    hashes: loaderResult.computedHashes,
                    skippedCount: loaderResult.allNames.count
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
            let allImageNames = granularCacheManager != nil ? loaderResult.allNames : nil
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
                try fileWriter.write(files: filesToWrite)
            }

            await checkForUpdate(logger: logger)

            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - images.count
                : 0

            ui.success("Done! Exported \(images.count) images to Web project.")
            return PlatformExportResult(
                count: images.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // MARK: - WebP Converter Helpers

        /// Creates a WebP converter from Android format options, using defaults if not specified.
        private func createWebpConverter(from options: Params.Android.Images.FormatOptions?) -> WebpConverter {
            guard let options else {
                // Default: lossy with quality 90
                return WebpConverter(encoding: .lossy(quality: 90))
            }

            switch (options.encoding, options.quality) {
            case (.lossless, _):
                return WebpConverter(encoding: .lossless)
            case let (.lossy, quality?):
                return WebpConverter(encoding: .lossy(quality: quality))
            case (.lossy, .none):
                // Lossy without quality specified - use default 90
                return WebpConverter(encoding: .lossy(quality: 90))
            }
        }
    }
}
