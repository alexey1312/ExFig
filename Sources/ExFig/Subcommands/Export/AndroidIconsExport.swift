// swiftlint:disable file_length closure_parameter_position
import AndroidExport
import ExFigCore
import FigmaAPI
import Foundation
import SVGKit

// MARK: - Android Icons Export

extension ExFigCommand.ExportIcons {
    // swiftlint:disable function_body_length

    /// Exports Android icons from Figma.
    /// - Parameters:
    ///   - strictPathValidationOverride: If true, overrides per-entry strictPathValidation config.
    func exportAndroidIcons(
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?,
        strictPathValidationOverride: Bool = false
    ) async throws -> PlatformExportResult {
        guard let android = params.android, let iconsConfig = android.icons else {
            ui.warning(.configMissing(platform: "android", assetType: "icons"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        // Get all entries from config (supports both single and multiple formats)
        let entries = iconsConfig.entries

        // Single entry - use direct processing (legacy behavior)
        if entries.count == 1 {
            return try await exportAndroidIconsEntry(
                entry: entries[0],
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager,
                strictPathValidationOverride: strictPathValidationOverride
            )
        }

        // Multiple entries - pre-fetch Components once for all entries
        return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
            client: client,
            params: params
        ) {
            try await processAndroidIconsEntries(
                entries: entries,
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager,
                strictPathValidationOverride: strictPathValidationOverride
            )
        }
    }

    // Helper to process multiple Android icon entries sequentially.
    // swiftlint:disable:next function_parameter_count
    func processAndroidIconsEntries(
        entries: [Params.Android.IconsEntry],
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?,
        strictPathValidationOverride: Bool
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportAndroidIconsEntry(
                entry: entry,
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager,
                strictPathValidationOverride: strictPathValidationOverride
            )
        }
    }

    // Exports icons for a single Android icons entry.
    // swiftlint:disable:next function_body_length function_parameter_count cyclomatic_complexity
    func exportAndroidIconsEntry(
        entry: Params.Android.IconsEntry,
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?,
        strictPathValidationOverride: Bool = false
    ) async throws -> PlatformExportResult {
        // Check if ImageVector format is requested
        let composeFormat = entry.composeFormat ?? .resourceReference

        if composeFormat == .imageVector {
            return try await exportAndroidIconsAsImageVectorEntry(
                entry: entry,
                android: android,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager,
                strictPathValidationOverride: strictPathValidationOverride
            )
        }

        let loaderConfig = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        // 1. Get Icons info
        let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") {
            onProgress in
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .android,
                logger: ExFigCommand.logger,
                config: loaderConfig
            )
            if let manager = granularCacheManager {
                loader.granularCacheManager = manager
                return try await loader.loadWithGranularCache(
                    filter: filter, onBatchProgress: onProgress
                )
            } else {
                let output = try await loader.load(filter: filter, onBatchProgress: onProgress)
                return IconsLoaderResultWithHashes(
                    light: output.light,
                    dark: output.dark,
                    computedHashes: [:],
                    allSkipped: false,
                    allAssetMetadata: [] // Not needed when not using granular cache
                )
            }
        }

        // If granular cache skipped all icons, return early
        if loaderResult.allSkipped {
            ui.success("All icons unchanged (granular cache). Skipping export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allAssetMetadata.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        // 2. Process images
        let processor = ImagesProcessor(
            platform: .android,
            nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
            nameStyle: entry.nameStyle ?? .snakeCase
        )

        let (icons, iconsWarning):
            ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing icons...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let iconsWarning {
            ui.warning(iconsWarning)
        }

        // Calculate skipped count for granular cache stats
        let skippedCount =
            granularCacheManager != nil
                ? loaderResult.allAssetMetadata.count - icons.count
                : 0

        // Create empty temp directory
        let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)

        // 3. Download SVG files to user's temp directory
        let remoteFiles = icons.flatMap { asset -> [FileContents] in
            let lightFiles = asset.light.images.compactMap { image -> FileContents? in
                guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
            }
            let darkFiles =
                asset.dark?.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    return FileContents(
                        destination: dest, sourceURL: image.url, dark: true, isRTL: image.isRTL
                    )
                } ?? []
            return lightFiles + darkFiles
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        var localFiles: [FileContents] =
            if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) {
                    progress in
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

        // 4. Move downloaded SVG files to new empty temp directory
        try ExFigCommand.fileWriter.write(files: localFiles)

        // 5. Convert all SVG to XML files
        let rtlFileNames = Set(
            remoteFiles.filter(\.isRTL).map {
                $0.destination.file.deletingPathExtension().lastPathComponent
            })

        // Create converter with config options (CLI flag overrides entry, entry overrides common)
        let strictValidation = strictPathValidationOverride
            || entry.strictPathValidation
            ?? params.common?.icons?.strictPathValidation
            ?? false
        let svgConverter = NativeVectorDrawableConverter(
            strictPathValidation: strictValidation
        )

        try await ui.withSpinner("Converting SVGs to vector drawables...") {
            if FileManager.default.fileExists(atPath: tempDirectoryLightURL.path) {
                try await svgConverter.convertAsync(
                    inputDirectoryUrl: tempDirectoryLightURL, rtlFiles: rtlFileNames
                )
            }
            if FileManager.default.fileExists(atPath: tempDirectoryDarkURL.path) {
                try await svgConverter.convertAsync(
                    inputDirectoryUrl: tempDirectoryDarkURL, rtlFiles: rtlFileNames
                )
            }
        }

        // Create output directory main/res/custom-directory/drawable/
        let lightDirectory = URL(
            fileURLWithPath: android.mainRes
                .appendingPathComponent(entry.output)
                .appendingPathComponent("drawable", isDirectory: true).path)

        let darkDirectory = URL(
            fileURLWithPath: android.mainRes
                .appendingPathComponent(entry.output)
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
            packageName: entry.composePackageName,
            templatesPath: android.templatesPath
        )
        let composeExporter = AndroidComposeIconExporter(output: output)
        let composeIconNames = Set(
            localFiles.filter { fileContents in
                !fileContents.dark
            }.map { fileContents -> String in
                fileContents.destination.file.deletingPathExtension().lastPathComponent
            })
        // Process allNames with the same transformations applied to icons
        let allIconNames =
            granularCacheManager != nil
                ? processor.processNames(loaderResult.allAssetMetadata.map(\.name))
                : nil
        let composeFile = try composeExporter.exportIcons(
            iconNames: Array(composeIconNames).sorted(),
            allIconNames: allIconNames
        )
        composeFile.map { localFiles.append($0) }

        let filesToWrite = localFiles
        try await ui.withSpinner("Writing files to Android Studio project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        try? FileManager.default.removeItem(at: tempDirectoryLightURL)
        try? FileManager.default.removeItem(at: tempDirectoryDarkURL)

        // Suppress update check in batch mode (will be shown once at the end)
        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(icons.count) icons.")
        return PlatformExportResult(
            count: icons.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // Exports Android icons as Jetpack Compose ImageVector Kotlin files
    // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
    func exportAndroidIconsAsImageVectorEntry(
        entry: Params.Android.IconsEntry,
        android: Params.Android,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?,
        strictPathValidationOverride: Bool = false
    ) async throws -> PlatformExportResult {
        guard let packageName = entry.composePackageName else {
            ui.warning(.composeRequirementMissing(requirement: "composePackageName"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        guard let srcDirectory = android.mainSrc else {
            ui.warning(.composeRequirementMissing(requirement: "mainSrc"))
            return PlatformExportResult(count: 0, hashes: [:])
        }

        let loaderConfig = IconsLoaderConfig.forAndroid(entry: entry, params: params)

        // 1. Get Icons info
        let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") {
            onProgress in
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .android,
                logger: ExFigCommand.logger,
                config: loaderConfig
            )
            if let manager = granularCacheManager {
                loader.granularCacheManager = manager
                return try await loader.loadWithGranularCache(
                    filter: filter, onBatchProgress: onProgress
                )
            } else {
                let output = try await loader.load(filter: filter, onBatchProgress: onProgress)
                return IconsLoaderResultWithHashes(
                    light: output.light,
                    dark: output.dark,
                    computedHashes: [:],
                    allSkipped: false,
                    allAssetMetadata: [] // Not needed when not using granular cache
                )
            }
        }

        // If granular cache skipped all icons, return early
        if loaderResult.allSkipped {
            ui.success("All icons unchanged (granular cache). Skipping export.")
            return PlatformExportResult(
                count: 0,
                hashes: loaderResult.computedHashes,
                skippedCount: loaderResult.allAssetMetadata.count
            )
        }

        let imagesTuple = (light: loaderResult.light, dark: loaderResult.dark)

        // 2. Process images
        let processor = ImagesProcessor(
            platform: .android,
            nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
            nameStyle: entry.nameStyle ?? .snakeCase
        )

        let (icons, iconsWarning):
            ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing icons...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let iconsWarning {
            ui.warning(iconsWarning)
        }

        // Create temp directory for SVG files
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)

        // 3. Download SVG files to temp directory
        let remoteFiles = icons.flatMap { asset -> [FileContents] in
            asset.light.images.compactMap { image -> FileContents? in
                guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                let dest = Destination(directory: tempDirectoryURL, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
            }
        }

        let fileDownloader = faultToleranceOptions.createFileDownloader()
        let localFiles: [FileContents] =
            if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) {
                    progress in
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

        // 4. Convert SVGs to ImageVector Kotlin files
        let kotlinFiles = try await ui.withSpinner("Converting SVGs to ImageVector...") {
            let outputDirectory = srcDirectory.appendingPathComponent(
                packageName.replacingOccurrences(of: ".", with: "/")
            )

            // CLI flag overrides entry, entry overrides common
            let strictValidation = strictPathValidationOverride
                || entry.strictPathValidation
                ?? params.common?.icons?.strictPathValidation
                ?? false
            let exporter = AndroidImageVectorExporter(
                outputDirectory: outputDirectory,
                config: .init(
                    packageName: packageName,
                    extensionTarget: entry.composeExtensionTarget,
                    generatePreview: true,
                    colorMappings: [:],
                    strictPathValidation: strictValidation
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

            let files = try await exporter.exportAsync(svgFiles: svgFiles)

            // Clear output directory if not filtering
            if filter == nil, granularCacheManager == nil {
                try? FileManager.default.removeItem(atPath: outputDirectory.path)
            }

            return files
        }

        try await ui.withSpinner("Writing Kotlin files to Android Studio project...") {
            try ExFigCommand.fileWriter.write(files: kotlinFiles)
        }

        // Cleanup temp directory
        try? FileManager.default.removeItem(at: tempDirectoryURL)

        await checkForUpdate(logger: ExFigCommand.logger)

        // Calculate skipped count for granular cache stats
        let skippedCount =
            granularCacheManager != nil
                ? loaderResult.allAssetMetadata.count - icons.count
                : 0

        ui.success("Done! Generated \(kotlinFiles.count) ImageVector files.")
        return PlatformExportResult(
            count: icons.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
