// swiftlint:disable type_name file_length

import ExFigCore
import Foundation
import XcodeExport

/// Exports images from Figma frames to iOS xcassets (PNG/HEIC) and Swift extensions.
///
/// Supports multiple workflows:
/// - PNG source → PNG/HEIC output
/// - SVG source → PNG/HEIC output (rasterization)
public struct iOSImagesExporter: ImagesExporter {
    public typealias Entry = iOSImagesEntry
    public typealias PlatformConfig = iOSPlatformConfig

    public init() {}

    public func exportImages(
        entries: [iOSImagesEntry],
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        var totalCount = 0

        for entry in entries {
            totalCount += try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(totalCount) images to Xcode project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let sourceFormat = entry.sourceFormat ?? .png
        let outputFormat = entry.effectiveOutputFormat

        switch (sourceFormat, outputFormat) {
        case (.svg, _):
            return try await exportSVGSource(
                entry: entry, platformConfig: platformConfig, context: context, outputFormat: outputFormat
            )
        case (.png, .heic):
            return try await exportPNGSourceHeic(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.png, _):
            return try await exportPNGSourceRaster(
                entry: entry, platformConfig: platformConfig, context: context
            )
        }
    }

    private func exportPNGSourceRaster(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, assetsURL) = try await loadAndProcess(
            entry: entry, platformConfig: platformConfig, context: context
        )

        let output = entry.makeXcodeImagesOutput(platformConfig: platformConfig, assetsURL: assetsURL)
        let exporter = XcodeImagesExporter(output: output)
        let localAndRemoteFiles = try exporter.export(
            assets: imagePairs, allAssetNames: nil, allAssetMetadata: nil, append: context.filter != nil
        )

        if context.filter == nil { try? FileManager.default.removeItem(atPath: assetsURL.path) }

        let localFiles = try await context.downloadFiles(localAndRemoteFiles, progressTitle: "Downloading images")

        try await context.withSpinner("Writing files to Xcode project...") {
            try context.writeFiles(localFiles)
        }

        return imagePairs.count
    }

    private func exportPNGSourceHeic(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, assetsURL) = try await loadAndProcess(
            entry: entry, platformConfig: platformConfig, context: context
        )

        let output = entry.makeXcodeImagesOutput(platformConfig: platformConfig, assetsURL: assetsURL)
        let exporter = XcodeImagesExporter(output: output)
        let localAndRemoteFiles = try exporter.exportForHeic(
            assets: imagePairs, allAssetNames: nil, allAssetMetadata: nil, append: context.filter != nil
        )

        if context.filter == nil { try? FileManager.default.removeItem(atPath: assetsURL.path) }

        var localFiles = try await context.downloadFiles(localAndRemoteFiles, progressTitle: "Downloading images")

        let pngFiles = localFiles.filter { $0.destination.file.pathExtension == "png" }
        if !pngFiles.isEmpty {
            localFiles = try await context.convertFormat(localFiles, to: .heic, progressTitle: "Converting to HEIC")
        }

        let filesToWrite = localFiles.filter { $0.destination.file.pathExtension != "heic" }
        try await context.withSpinner("Writing files to Xcode project...") {
            try context.writeFiles(filesToWrite)
        }

        return imagePairs.count
    }

    private func exportSVGSource(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext,
        outputFormat: ImageOutputFormat
    ) async throws -> Int {
        let (imagePairs, assetsURL) = try await loadAndProcessSVG(
            entry: entry, platformConfig: platformConfig, context: context
        )

        let svgRemoteFiles = iOSImagesExporterHelpers.makeSVGRemoteFiles(imagePairs: imagePairs, assetsURL: assetsURL)
        let downloadedSVGs = try await context.downloadFiles(svgRemoteFiles, progressTitle: "Downloading SVGs")

        if context.filter == nil { try? FileManager.default.removeItem(atPath: assetsURL.path) }

        let scales = entry.effectiveScales
        let rasterFiles = try await context.rasterizeSVGs(
            downloadedSVGs, scales: scales, to: outputFormat,
            progressTitle: "Rasterizing SVGs to \(outputFormat.rawValue.uppercased())"
        )

        let output = entry.makeXcodeImagesOutput(platformConfig: platformConfig, assetsURL: assetsURL)
        let exporter = XcodeImagesExporter(output: output)
        let extensionFiles = try exporter.exportSwiftExtensions(
            assets: imagePairs, allAssetNames: nil, allAssetMetadata: nil, append: context.filter != nil
        )

        let contentsJsonFiles = iOSImagesExporterHelpers.makeImagesetContentsJson(
            imagePairs: imagePairs, scales: scales, assetsURL: assetsURL,
            renderMode: entry.renderMode, fileExtension: outputFormat.rawValue
        )

        let folderContentsFile = iOSImagesExporterHelpers.makeFolderContentsJson(assetsURL: assetsURL)

        let filesToWrite = rasterFiles + contentsJsonFiles + extensionFiles + [folderContentsFile]
        try await context.withSpinner("Writing files to Xcode project...") {
            try context.writeFiles(filesToWrite)
        }

        return imagePairs.count
    }

    private func loadAndProcess(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.assetsFolder))...") {
            try await context.loadImages(from: entry.imagesSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing images for iOS...") {
            try context.processImages(
                images, platform: .ios,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp, nameStyle: entry.nameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let assetsURL = platformConfig.xcassetsPath.appendingPathComponent(entry.assetsFolder)
        return (processResult.imagePairs, assetsURL)
    }

    private func loadAndProcessSVG(
        entry: iOSImagesEntry,
        platformConfig: iOSPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching SVG images from Figma (\(entry.assetsFolder))...") {
            let input = entry.svgSourceInput()
            return try await context.loadImages(from: input)
        }

        let processResult = try await context.withSpinner("Processing images for iOS...") {
            try context.processImages(
                images, platform: .ios,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp, nameStyle: entry.nameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let assetsURL = platformConfig.xcassetsPath.appendingPathComponent(entry.assetsFolder)
        return (processResult.imagePairs, assetsURL)
    }
}

// MARK: - Entry Helpers

private extension iOSImagesEntry {
    func makeXcodeImagesOutput(platformConfig: iOSPlatformConfig, assetsURL: URL) -> XcodeImagesOutput {
        XcodeImagesOutput(
            assetsFolderURL: assetsURL,
            assetsInMainBundle: platformConfig.xcassetsInMainBundle,
            assetsInSwiftPackage: platformConfig.xcassetsInSwiftPackage,
            resourceBundleNames: platformConfig.resourceBundleNames,
            addObjcAttribute: platformConfig.addObjcAttribute,
            uiKitImageExtensionURL: imageSwift,
            swiftUIImageExtensionURL: swiftUIImageSwift,
            codeConnectSwiftURL: codeConnectSwift,
            templatesPath: platformConfig.templatesPath,
            renderMode: renderMode
        )
    }

    func svgSourceInput() -> ImagesSourceInput {
        ImagesSourceInput(
            fileId: "",
            darkFileId: nil,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: .svg,
            scales: [1.0],
            useSingleFile: true,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }
}

// MARK: - Static Helpers

private enum iOSImagesExporterHelpers {
    static func makeSVGRemoteFiles(imagePairs: [AssetPair<ImagePack>], assetsURL: URL) -> [FileContents] {
        var files: [FileContents] = []

        for pair in imagePairs {
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

            if let dark = pair.dark, let image = dark.images.first {
                let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")
                files.append(FileContents(
                    destination: Destination(
                        directory: imagesetDir,
                        file: URL(fileURLWithPath: "\(pair.light.name)D.svg")
                    ),
                    sourceURL: image.url, dark: true
                ))
            }
        }

        return files
    }

    static func makeImagesetContentsJson(
        imagePairs: [AssetPair<ImagePack>],
        scales: [Double],
        assetsURL: URL,
        renderMode: XcodeRenderMode?,
        fileExtension: String
    ) -> [FileContents] {
        imagePairs.compactMap { pair -> FileContents? in
            let imagesetDir = assetsURL.appendingPathComponent("\(pair.light.name).imageset")
            var imagesArray: [[String: Any]] = []

            for scale in scales {
                let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                imagesArray.append([
                    "filename": "\(pair.light.name)\(scaleSuffix).\(fileExtension)",
                    "idiom": "universal", "scale": scaleString,
                ])
            }

            if pair.dark != nil {
                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let scaleString = scale == 1.0 ? "1x" : "\(Int(scale))x"
                    imagesArray.append([
                        "appearances": [["appearance": "luminosity", "value": "dark"]],
                        "filename": "\(pair.light.name)D\(scaleSuffix).\(fileExtension)",
                        "idiom": "universal", "scale": scaleString,
                    ])
                }
            }

            var contentsJson: [String: Any] = [
                "images": imagesArray,
                "info": ["author": "xcode", "version": 1],
            ]

            if let renderMode, renderMode == .original || renderMode == .template {
                contentsJson["properties"] = ["template-rendering-intent": renderMode.rawValue]
            }

            guard let jsonData = try? JSONSerialization.data(
                withJSONObject: contentsJson, options: [.prettyPrinted, .sortedKeys]
            ) else { return nil }

            return FileContents(
                destination: Destination(directory: imagesetDir, file: URL(fileURLWithPath: "Contents.json")),
                data: jsonData
            )
        }
    }

    static func makeFolderContentsJson(assetsURL: URL) -> FileContents {
        FileContents(
            destination: Destination(directory: assetsURL, file: URL(fileURLWithPath: "Contents.json")),
            data: Data(#"{"info":{"author":"xcode","version":1}}"#.utf8)
        )
    }
}

// swiftlint:enable type_name file_length
