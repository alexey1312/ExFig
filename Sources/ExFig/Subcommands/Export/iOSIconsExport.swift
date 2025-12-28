import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import XcodeExport

// MARK: - iOS Icons Export

extension ExFigCommand.ExportIcons {
    // swiftlint:disable function_body_length cyclomatic_complexity

    /// Exports iOS icons from Figma.
    /// - Parameters:
    ///   - client: The Figma API client.
    ///   - params: Export parameters.
    ///   - ui: Terminal UI for progress.
    ///   - granularCacheManager: Optional granular cache manager.
    /// - Returns: Platform export result.
    func exportiOSIcons(
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        guard let ios = params.ios,
              let iconsConfig = ios.icons
        else {
            ui.warning(.configMissing(platform: "ios", assetType: "icons"))
            return PlatformExportResult(count: 0, hashes: [:], skippedCount: 0)
        }

        // Get all entries from config (supports both single and multiple formats)
        let entries = iconsConfig.entries

        // Single entry - use direct processing (legacy behavior)
        if entries.count == 1 {
            return try await exportiOSIconsEntry(
                entry: entries[0],
                ios: ios,
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
            try await processIOSIconsEntries(
                entries: entries,
                ios: ios,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Helper to process multiple iOS icon entries sequentially.
    // swiftlint:disable:next function_parameter_count
    func processIOSIconsEntries(
        entries: [Params.iOS.IconsEntry],
        ios: Params.iOS,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportiOSIconsEntry(
                entry: entry,
                ios: ios,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // Exports icons for a single iOS icons entry.
    // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
    func exportiOSIconsEntry(
        entry: Params.iOS.IconsEntry,
        ios: Params.iOS,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        let loaderConfig = IconsLoaderConfig.forIOS(entry: entry, params: params)

        let loaderResult = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .ios,
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

        let processor = ImagesProcessor(
            platform: .ios,
            nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
            nameStyle: entry.nameStyle
        )

        let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
            try await ui.withSpinner("Processing icons...") {
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                return try (result.get(), result.warning)
            }
        if let iconsWarning {
            ui.warning(iconsWarning)
        }

        let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsURL,
            assetsInMainBundle: ios.xcassetsInMainBundle,
            assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
            resourceBundleNames: ios.resourceBundleNames,
            addObjcAttribute: ios.addObjcAttribute,
            preservesVectorRepresentation: entry.preservesVectorRepresentation,
            uiKitImageExtensionURL: entry.imageSwift,
            swiftUIImageExtensionURL: entry.swiftUIImageSwift,
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
                ) { current, total in
                    progress.update(current: current)
                    // Report to batch progress if in batch mode
                    if let callback = BatchProgressViewStorage.downloadProgressCallback {
                        Task { await callback(current, total) }
                    }
                }
            }
        } else {
            localAndRemoteFiles
        }

        try await ui.withSpinner("Writing files to Xcode project...") {
            try ExFigCommand.fileWriter.write(files: localFiles)
        }

        // Calculate skipped count for granular cache stats
        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - icons.count
            : 0

        guard params.ios?.xcassetsInSwiftPackage == false else {
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(icons.count) icons.")
        return PlatformExportResult(
            count: icons.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length cyclomatic_complexity
}
