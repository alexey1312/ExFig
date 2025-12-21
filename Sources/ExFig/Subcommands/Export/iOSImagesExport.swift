// swiftlint:disable file_length
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// MARK: - iOS Images Export

extension ExFigCommand.ExportImages {
    // swiftlint:disable function_body_length

    func exportiOSImages(
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
        return try await ComponentPreFetcher.withPreFetchedComponentsIfNeeded(
            client: client,
            params: params
        ) {
            try await processIOSImagesEntries(
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
    func processIOSImagesEntries(
        entries: [Params.iOS.ImagesEntry],
        ios: Params.iOS,
        client: Client,
        params: Params,
        ui: TerminalUI,
        granularCacheManager: GranularCacheManager?
    ) async throws -> PlatformExportResult {
        try await EntryProcessor.processEntries(entries: entries) { entry in
            try await exportiOSImagesEntry(
                entry: entry,
                ios: ios,
                client: client,
                params: params,
                ui: ui,
                granularCacheManager: granularCacheManager
            )
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportiOSImagesEntry(
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
            try ExFigCommand.fileWriter.write(files: localFiles)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        guard params.ios?.xcassetsInSwiftPackage == false else {
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: ExFigCommand.logger)
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(images.count) images.")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // MARK: - iOS SVG Source Export

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportiOSSVGSourceImagesEntry(
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
                // Read SVG data from memory or temp file
                let svgData: Data
                if let data = fileContents.data {
                    svgData = data
                } else if let dataFile = fileContents.dataFile {
                    svgData = try Data(contentsOf: dataFile)
                } else {
                    continue
                }
                let baseName = fileContents.destination.file.deletingPathExtension().lastPathComponent
                let imagesetDir = fileContents.destination.directory

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
                        ExFigCommand.logger.error("Failed to rasterize \(baseName) at \(scale)x: \(error)")
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
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        // Clean up old HEIC files in imagesets (when switching from HEIC to PNG format)
        for pngFile in pngFiles {
            let heicPath = pngFile.destination.url.path
                .replacingOccurrences(of: ".png", with: ".heic")
            try? FileManager.default.removeItem(atPath: heicPath)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        guard params.ios?.xcassetsInSwiftPackage == false else {
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: ExFigCommand.logger)
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(images.count) images (SVG source).")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    /// Creates remote file references for SVG downloads (iOS).
    func makeSVGRemoteFilesForIOS(
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
            // Use "D" suffix to match standard iOS naming convention (XcodeExportExtensions.swift)
            if let dark = pair.dark, let image = dark.images.first {
                let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")
                files.append(FileContents(
                    destination: Destination(
                        directory: imagesetDir,
                        file: URL(fileURLWithPath: "\(pair.light.name)D.svg")
                    ),
                    sourceURL: image.url,
                    dark: true
                ))
            }
        }

        return files
    }

    /// Creates Contents.json files for each imageset.
    func makeImagesetContentsJson(
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
            // Use "D" suffix to match standard iOS naming convention
            if pair.dark != nil {
                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                    imagesArray.append([
                        "appearances": [["appearance": "luminosity", "value": "dark"]],
                        "filename": "\(pair.light.name)D\(scaleSuffix).png",
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
    func resolveOutputFormat(
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
    func makeImagesetContentsJsonForHeic(
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
            // Use "D" suffix to match standard iOS naming convention
            if pair.dark != nil {
                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                    imagesArray.append([
                        "appearances": [["appearance": "luminosity", "value": "dark"]],
                        "filename": "\(pair.light.name)D\(scaleSuffix).heic",
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

    // MARK: - iOS SVG Source + HEIC Output Export

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportiOSSVGSourceHeicImagesEntry(
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
        let converter = HeicConverterFactory.createSvgToHeicConverter(from: entry.heicOptions)

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
                // Read SVG data from memory or temp file
                let svgData: Data
                if let data = fileContents.data {
                    svgData = data
                } else if let dataFile = fileContents.dataFile {
                    svgData = try Data(contentsOf: dataFile)
                } else {
                    continue
                }
                let baseName = fileContents.destination.file.deletingPathExtension().lastPathComponent
                let imagesetDir = fileContents.destination.directory

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
                        ExFigCommand.logger.error("Failed to rasterize \(baseName) at \(scale)x: \(error)")
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
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        // Clean up old PNG files in imagesets (when switching from PNG to HEIC format)
        for heicFile in heicFiles {
            let pngPath = heicFile.destination.url.path
                .replacingOccurrences(of: ".heic", with: ".png")
            try? FileManager.default.removeItem(atPath: pngPath)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        guard params.ios?.xcassetsInSwiftPackage == false else {
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: ExFigCommand.logger)
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(images.count) images (SVG source, HEIC output).")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // MARK: - iOS PNG Source + HEIC Output Export

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func exportiOSPngSourceHeicImagesEntry(
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
        // Track converted PNG paths to exclude from final write
        let convertedPngPaths = Set(pngFiles.map(\.destination.url.path))

        if !pngFiles.isEmpty {
            // Write PNG files to disk first (HEIC converter reads from disk)
            try ExFigCommand.fileWriter.write(files: pngFiles)

            let converter = HeicConverterFactory.createHeicConverter(from: entry.heicOptions)
            // Convert to proper file:// URLs (YAML-decoded URLs lack scheme)
            let filesToConvert = pngFiles.map { URL(fileURLWithPath: $0.destination.url.path) }
            try await ui.withProgress("Converting to HEIC", total: filesToConvert.count) { progress in
                try await converter.convertBatch(files: filesToConvert) { current, _ in
                    progress.update(current: current)
                }
            }
            // Delete source PNG files after successful conversion
            for pngFile in filesToConvert {
                try? FileManager.default.removeItem(at: pngFile)
            }
            // Update file references to use .heic extension (for stats/logging)
            localFiles = localFiles.map { file in
                if file.destination.file.pathExtension == "png" {
                    return file.changingExtension(newExtension: "heic")
                }
                return file
            }
        }

        // Write remaining files (Contents.json, Swift extensions)
        // Exclude converted images - HEIC files were already created by converter
        let filesToWrite = localFiles.filter { file in
            let originalPath = file.destination.url.path.replacingOccurrences(of: ".heic", with: ".png")
            return !convertedPngPaths.contains(originalPath)
        }
        try await ui.withSpinner("Writing files to Xcode project...") {
            try ExFigCommand.fileWriter.write(files: filesToWrite)
        }

        let skippedCount = granularCacheManager != nil
            ? loaderResult.allNames.count - images.count
            : 0

        guard params.ios?.xcassetsInSwiftPackage == false else {
            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: ExFigCommand.logger)
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(images.count) images (HEIC output).")
        return PlatformExportResult(
            count: images.count,
            hashes: loaderResult.computedHashes,
            skippedCount: skippedCount
        )
    }

    // swiftlint:enable function_body_length
}
