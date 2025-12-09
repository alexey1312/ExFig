// swiftlint:disable file_length type_body_length
import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import SVGKit
import XcodeExport

extension ExFigCommand {
    struct ExportIcons: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "icons",
            abstract: "Exports icons from Figma",
            discussion: "Exports icons from Figma to Xcode / Android Studio project"
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
        [Optional] Name of the icons to export. For example \"ic/24/edit\" \
        to export single icon, \"ic/24/edit, ic/16/notification\" to export several icons and \
        \"ic/16/*\" to export all icons of size 16 pt
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

        /// Result of icons export for batch mode integration.
        struct IconsExportResult {
            let count: Int
            let computedHashes: [String: [String: String]]
            let granularCacheStats: GranularCacheStats?
            let fileVersions: [FileVersionInfo]?
        }

        /// Performs the actual export and returns the number of exported icons.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: The number of icons exported.
        func performExport(
            client: Client,
            ui: TerminalUI
        ) async throws -> Int {
            let result = try await performExportWithResult(client: client, ui: ui)
            return result.count
        }

        // swiftlint:disable function_body_length cyclomatic_complexity
        /// Performs export and returns full result with hashes for batch mode.
        /// - Parameters:
        ///   - client: The Figma API client to use.
        ///   - ui: The terminal UI for progress and messages.
        /// - Returns: Export result including count, hashes, and granular cache stats.
        func performExportWithResult(
            client: Client,
            ui: TerminalUI
        ) async throws -> IconsExportResult {
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
                    assetType: "Icons",
                    ui: ui,
                    logger: logger,
                    batchMode: batchMode
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return IconsExportResult(count: 0, computedHashes: [:], granularCacheStats: nil, fileVersions: nil)
            }

            // Check for granular cache warning
            let configCacheEnabled = options.params.common?.cache?.isEnabled ?? false
            if let warning = cacheOptions.granularCacheWarning(configEnabled: configCacheEnabled) {
                ui.warning(warning)
            }

            // Determine if granular cache is enabled
            let granularCacheEnabled = cacheOptions.isGranularCacheEnabled(configEnabled: configCacheEnabled)

            // Clear node hashes if --force flag is set
            if cacheOptions.force, granularCacheEnabled {
                let fileIds = [options.params.figma.lightFileId] +
                    (options.params.figma.darkFileId.map { [$0] } ?? [])
                for fileId in fileIds {
                    try trackingManager.clearNodeHashes(fileId: fileId)
                }
            }

            // Create granular cache manager if enabled
            let granularCacheManager: GranularCacheManager? = granularCacheEnabled
                ? trackingManager.createGranularCacheManager()
                : nil

            var totalIcons = 0
            var totalSkipped = 0
            var allComputedHashes: [String: [NodeId: String]] = [:]

            if options.params.ios != nil {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Xcode project.")
                }
                let result = try await exportiOSIcons(
                    client: client,
                    params: options.params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalIcons += result.count
                totalSkipped += result.skippedCount
                mergeHashes(&allComputedHashes, result.hashes)
            }

            if options.params.android != nil {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Android Studio project.")
                }
                let result = try await exportAndroidIcons(
                    client: client,
                    params: options.params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalIcons += result.count
                totalSkipped += result.skippedCount
                mergeHashes(&allComputedHashes, result.hashes)
            }

            if options.params.flutter != nil {
                // Suppress version message in batch mode
                if BatchProgressViewStorage.progressView == nil {
                    ui.info("Using ExFig \(ExFigCommand.version) to export icons to Flutter project.")
                }
                let result = try await exportFlutterIcons(
                    client: client,
                    params: options.params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
                totalIcons += result.count
                totalSkipped += result.skippedCount
                mergeHashes(&allComputedHashes, result.hashes)
            }

            // Update file version cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            // Update node hashes for granular cache (no-op in batch mode)
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
            let stats: GranularCacheStats? = granularCacheEnabled && (totalIcons > 0 || totalSkipped > 0)
                ? GranularCacheStats(skipped: totalSkipped, exported: totalIcons)
                : nil

            return IconsExportResult(
                count: totalIcons,
                computedHashes: stringHashes,
                granularCacheStats: stats,
                fileVersions: batchMode ? fileVersions : nil
            )
        }

        // swiftlint:enable function_body_length cyclomatic_complexity

        /// Result of exporting icons for a single platform.
        private struct PlatformExportResult {
            let count: Int
            let hashes: [String: [NodeId: String]]
            /// Number of icons skipped by granular cache.
            let skippedCount: Int

            init(count: Int, hashes: [String: [NodeId: String]], skippedCount: Int = 0) {
                self.count = count
                self.hashes = hashes
                self.skippedCount = skippedCount
            }
        }

        /// Merges computed hashes from one result into the accumulator.
        private func mergeHashes(
            _ accumulator: inout [String: [NodeId: String]],
            _ newHashes: [String: [NodeId: String]]
        ) {
            for (fileId, hashes) in newHashes {
                if accumulator[fileId] != nil {
                    accumulator[fileId]!.merge(hashes) { _, new in new }
                } else {
                    accumulator[fileId] = hashes
                }
            }
        }

        // swiftlint:disable function_body_length cyclomatic_complexity
        private func exportiOSIcons(
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            guard let ios = params.ios,
                  let iconsParams = ios.icons
            else {
                ui.warning(.configMissing(platform: "ios", assetType: "icons"))
                return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
            }

            let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .ios, logger: logger)
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

            let processor = ImagesProcessor(
                platform: .ios,
                nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                nameStyle: iconsParams.nameStyle
            )

            let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing icons...") {
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let iconsWarning {
                ui.warning(iconsWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(iconsParams.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                preservesVectorRepresentation: iconsParams.preservesVectorRepresentation,
                uiKitImageExtensionURL: iconsParams.imageSwift,
                swiftUIImageExtensionURL: iconsParams.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeIconsExporter(output: output)
            // Process allNames with the same transformations applied to icons
            let allIconNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let localAndRemoteFiles = try exporter.export(
                icons: icons,
                allIconNames: allIconNames,
                append: filter != nil
            )
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            let remoteFilesCount = localAndRemoteFiles.filter { $0.sourceURL != nil }.count
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            // Download with progress bar (uses SharedDownloadQueue in batch mode)
            let localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading icons", total: remoteFilesCount) { progress in
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

            // Calculate skipped count for granular cache stats
            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - icons.count
                : 0

            guard params.ios?.xcassetsInSwiftPackage == false else {
                // Suppress update check in batch mode (will be shown once at the end)
                if BatchProgressViewStorage.progressView == nil {
                    await checkForUpdate(logger: logger)
                }
                ui.success("Done! Exported \(icons.count) icons.")
                return PlatformExportResult(
                    count: icons.count,
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

            // Suppress update check in batch mode (will be shown once at the end)
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(icons.count) icons.")
            return PlatformExportResult(
                count: icons.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // swiftlint:enable function_body_length cyclomatic_complexity

        // swiftlint:disable:next function_body_length
        private func exportAndroidIcons(
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            guard let android = params.android, let androidIcons = android.icons else {
                ui.warning(.configMissing(platform: "android", assetType: "icons"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // Check if ImageVector format is requested
            let composeFormat = androidIcons.composeFormat ?? .resourceReference

            if composeFormat == .imageVector {
                return try await exportAndroidIconsAsImageVector(
                    client: client,
                    params: params,
                    ui: ui,
                    granularCacheManager: granularCacheManager
                )
            }

            // 1. Get Icons info
            let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
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
                platform: .android,
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

            // Calculate skipped count for granular cache stats
            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - icons.count
                : 0

            // Create empty temp directory
            let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // 3. Download SVG files to user's temp directory
            let remoteFiles = icons.flatMap { asset -> [FileContents] in
                let lightFiles = asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
                }
                let darkFiles = asset.dark?.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, dark: true, isRTL: image.isRTL)
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

            // 4. Move downloaded SVG files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // 5. Convert all SVG to XML files
            let rtlFileNames = Set(remoteFiles.filter(\.isRTL).map {
                $0.destination.file.deletingPathExtension().lastPathComponent
            })

            try await ui.withSpinner("Converting SVGs to vector drawables...") {
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryLightURL, rtlFiles: rtlFileNames)
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryDarkURL, rtlFiles: rtlFileNames)
            }

            // Create output directory main/res/custom-directory/drawable/
            let lightDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidIcons.output)
                .appendingPathComponent("drawable", isDirectory: true).path)

            let darkDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidIcons.output)
                .appendingPathComponent("drawable-night", isDirectory: true).path)

            if filter == nil, granularCacheManager == nil {
                // Clear output directory
                try? FileManager.default.removeItem(atPath: lightDirectory.path)
                try? FileManager.default.removeItem(atPath: darkDirectory.path)
            }

            // 6. Move XML files to main/res/drawable/
            localFiles = localFiles.map { fileContents -> FileContents in
                let directory = fileContents.dark ? darkDirectory : lightDirectory

                let source = fileContents.destination.url
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                let fileURL = fileContents.destination.file
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                return FileContents(
                    destination: Destination(directory: directory, file: fileURL),
                    dataFile: source
                )
            }

            // 7. Create Compose extension if configured
            let output = AndroidOutput(
                xmlOutputDirectory: android.mainRes,
                xmlResourcePackage: android.resourcePackage,
                srcDirectory: android.mainSrc,
                packageName: android.icons?.composePackageName,
                templatesPath: android.templatesPath
            )
            let composeExporter = AndroidComposeIconExporter(output: output)
            let composeIconNames = Set(localFiles.filter { fileContents in
                !fileContents.dark
            }.map { fileContents -> String in
                fileContents.destination.file.deletingPathExtension().lastPathComponent
            })
            // Process allNames with the same transformations applied to icons
            let allIconNames = granularCacheManager != nil
                ? processor.processNames(loaderResult.allNames)
                : nil
            let composeFile = try composeExporter.exportIcons(
                iconNames: Array(composeIconNames).sorted(),
                allIconNames: allIconNames
            )
            composeFile.map { localFiles.append($0) }

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Android Studio project...") {
                try fileWriter.write(files: filesToWrite)
            }

            try? FileManager.default.removeItem(at: tempDirectoryLightURL)
            try? FileManager.default.removeItem(at: tempDirectoryDarkURL)

            // Suppress update check in batch mode (will be shown once at the end)
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(icons.count) icons.")
            return PlatformExportResult(
                count: icons.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // Exports Android icons as Jetpack Compose ImageVector Kotlin files
        // swiftlint:disable:next function_body_length cyclomatic_complexity
        private func exportAndroidIconsAsImageVector(
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            guard let android = params.android, let androidIcons = android.icons else {
                return PlatformExportResult(count: 0, hashes: [:])
            }

            guard let packageName = androidIcons.composePackageName else {
                ui.warning(.composeRequirementMissing(requirement: "composePackageName"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            guard let srcDirectory = android.mainSrc else {
                ui.warning(.composeRequirementMissing(requirement: "mainSrc"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // 1. Get Icons info
            let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
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
                platform: .android,
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

            // Create temp directory for SVG files
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // 3. Download SVG files to temp directory
            let remoteFiles = icons.flatMap { asset -> [FileContents] in
                asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
                }
            }

            let fileDownloader = faultToleranceOptions.createFileDownloader()
            let localFiles: [FileContents] = if !remoteFiles.isEmpty {
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

            // 4. Convert SVGs to ImageVector Kotlin files
            let kotlinFiles = try await ui.withSpinner("Converting SVGs to ImageVector...") {
                let outputDirectory = srcDirectory.appendingPathComponent(
                    packageName.replacingOccurrences(of: ".", with: "/")
                )

                let exporter = AndroidImageVectorExporter(
                    outputDirectory: outputDirectory,
                    config: .init(
                        packageName: packageName,
                        extensionTarget: androidIcons.composeExtensionTarget,
                        generatePreview: true,
                        colorMappings: [:]
                    )
                )

                // Collect SVG data from temp files
                var svgFiles: [String: Data] = [:]
                for file in localFiles {
                    let iconName = file.destination.file.deletingPathExtension().lastPathComponent
                    if let data = try? Data(contentsOf: file.destination.url) {
                        svgFiles[iconName] = data
                    }
                }

                let files = try exporter.export(svgFiles: svgFiles)

                // Clear output directory if not filtering
                if filter == nil, granularCacheManager == nil {
                    try? FileManager.default.removeItem(atPath: outputDirectory.path)
                }

                return files
            }

            try await ui.withSpinner("Writing Kotlin files to Android Studio project...") {
                try fileWriter.write(files: kotlinFiles)
            }

            // Cleanup temp directory
            try? FileManager.default.removeItem(at: tempDirectoryURL)

            await checkForUpdate(logger: logger)

            // Calculate skipped count for granular cache stats
            let skippedCount = granularCacheManager != nil
                ? loaderResult.allNames.count - icons.count
                : 0

            ui.success("Done! Generated \(kotlinFiles.count) ImageVector files.")
            return PlatformExportResult(
                count: icons.count,
                hashes: loaderResult.computedHashes,
                skippedCount: skippedCount
            )
        }

        // swiftlint:disable:next function_body_length
        private func exportFlutterIcons(
            client: Client,
            params: Params,
            ui: TerminalUI,
            granularCacheManager: GranularCacheManager?
        ) async throws -> PlatformExportResult {
            guard let flutter = params.flutter, let flutterIcons = flutter.icons else {
                ui.warning(.configMissing(platform: "flutter", assetType: "icons"))
                return PlatformExportResult(count: 0, hashes: [:])
            }

            // 1. Get Icons info
            let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
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
                platform: .android, // Flutter uses similar naming to Android
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
            let assetsDirectory = URL(fileURLWithPath: flutterIcons.output)
            let output = FlutterOutput(
                outputDirectory: flutter.output,
                iconsAssetsDirectory: assetsDirectory,
                templatesPath: flutter.templatesPath,
                iconsClassName: flutterIcons.className
            )

            let exporter = FlutterIconsExporter(output: output, outputFileName: flutterIcons.dartFile)
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
                try fileWriter.write(files: filesToWrite)
            }

            await checkForUpdate(logger: logger)

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
    }
}
