// swiftlint:disable file_length

import ExFigCore
import FlutterExport
import Foundation

/// Exports images from Figma frames to Flutter assets and Dart code.
///
/// Supports multiple workflows:
/// - SVG source → SVG output
/// - SVG source → WebP output (rasterization)
/// - PNG source → PNG/WebP output
public struct FlutterImagesExporter: ImagesExporter {
    public typealias Entry = FlutterImagesEntry
    public typealias PlatformConfig = FlutterPlatformConfig

    public init() {}

    public func exportImages(
        entries: [FlutterImagesEntry],
        platformConfig: FlutterPlatformConfig,
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
            context.success("Done! Exported \(totalCount) images to Flutter project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let sourceFormat = entry.sourceFormat ?? .png
        let outputFormat = entry.effectiveFormat

        switch (sourceFormat, outputFormat) {
        case (.svg, .svg):
            return try await exportSVGToSVG(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.svg, .webp):
            return try await exportSVGToWebp(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.svg, .png):
            return try await exportSVGToPNG(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.png, .webp):
            return try await exportPNGToWebp(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.png, .png):
            return try await exportPNGToPNG(
                entry: entry, platformConfig: platformConfig, context: context
            )
        case (.png, .svg):
            context.warning("Cannot convert PNG source to SVG. Use SVG source for vector output.")
            return 0
        }
    }
}

// MARK: - SVG to SVG

private extension FlutterImagesExporter {
    func exportSVGToSVG(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, assetsDirectory) = try await loadAndProcessSVG(entry: entry, context: context)

        let remoteFiles = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, assetsDirectory: assetsDirectory
        )
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")

        // Generate Dart file
        let dartFile = try generateDartFile(
            imagePairs: imagePairs,
            entry: entry,
            platformConfig: platformConfig,
            format: "svg",
            scales: [1.0]
        )

        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let allFiles = localFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        return imagePairs.count
    }
}

// MARK: - SVG to WebP

private extension FlutterImagesExporter {
    func exportSVGToWebp(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDir) = try await loadAndProcessSVGTemp(entry: entry, context: context)

        let remoteFiles = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, assetsDirectory: tempDir
        )
        let localSVGFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localSVGFiles)

        let scales = entry.effectiveScales
        let webpFiles = try await context.rasterizeSVGs(
            localSVGFiles, scales: scales, to: .webp,
            progressTitle: "Rasterizing SVGs to WebP"
        )

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let finalFiles = FlutterImagesHelpers.mapToFlutterScaleDirectories(
            webpFiles, assetsDirectory: assetsDirectory
        )

        let dartFile = try generateDartFile(
            imagePairs: imagePairs,
            entry: entry,
            platformConfig: platformConfig,
            format: "webp",
            scales: scales
        )

        let allFiles = finalFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        try? FileManager.default.removeItem(at: tempDir)
        return imagePairs.count
    }
}

// MARK: - SVG to PNG

private extension FlutterImagesExporter {
    func exportSVGToPNG(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDir) = try await loadAndProcessSVGTemp(entry: entry, context: context)

        let remoteFiles = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, assetsDirectory: tempDir
        )
        let localSVGFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localSVGFiles)

        let scales = entry.effectiveScales
        let pngFiles = try await context.rasterizeSVGs(
            localSVGFiles, scales: scales, to: .png,
            progressTitle: "Rasterizing SVGs to PNG"
        )

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let finalFiles = FlutterImagesHelpers.mapToFlutterScaleDirectories(
            pngFiles, assetsDirectory: assetsDirectory
        )

        let dartFile = try generateDartFile(
            imagePairs: imagePairs,
            entry: entry,
            platformConfig: platformConfig,
            format: "png",
            scales: scales
        )

        let allFiles = finalFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        try? FileManager.default.removeItem(at: tempDir)
        return imagePairs.count
    }
}

// MARK: - PNG to WebP

private extension FlutterImagesExporter {
    func exportPNGToWebp(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDir) = try await loadAndProcessPNG(entry: entry, context: context)

        let remoteFiles = try FlutterImagesHelpers.makeRasterRemoteFiles(
            imagePairs: imagePairs, tempDirectory: tempDir, scales: entry.effectiveScales
        )
        var localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading images")
        try context.writeFiles(localFiles)

        localFiles = try await context.convertFormat(localFiles, to: .webp, progressTitle: "Converting to WebP")

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let finalFiles = FlutterImagesHelpers.mapToFlutterScaleDirectories(
            localFiles, assetsDirectory: assetsDirectory
        )

        let dartFile = try generateDartFile(
            imagePairs: imagePairs,
            entry: entry,
            platformConfig: platformConfig,
            format: "webp",
            scales: entry.effectiveScales
        )

        let allFiles = finalFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        try? FileManager.default.removeItem(at: tempDir)
        return imagePairs.count
    }
}

// MARK: - PNG to PNG

private extension FlutterImagesExporter {
    func exportPNGToPNG(
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, assetsDirectory) = try await loadAndProcessPNGDirect(entry: entry, context: context)

        let output = FlutterOutput(
            outputDirectory: platformConfig.output,
            imagesAssetsDirectory: assetsDirectory,
            templatesPath: platformConfig.templatesPath,
            imagesClassName: entry.className
        )

        let exporter = FlutterExport.FlutterImagesExporter(
            output: output,
            outputFileName: entry.dartFile,
            scales: entry.effectiveScales,
            format: "png",
            nameStyle: entry.effectiveNameStyle
        )

        let (dartFile, assetFiles) = try exporter.export(
            images: imagePairs,
            allImageNames: nil,
            assetsPath: entry.output
        )

        let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading images")

        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        let allFiles = localFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        return imagePairs.count
    }
}

// MARK: - Load & Process Helpers

private extension FlutterImagesExporter {
    func loadAndProcessSVG(
        entry: FlutterImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            try await context.loadImages(from: entry.svgSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing images for Flutter...") {
            try context.processImages(
                images,
                platform: .flutter,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        return (processResult.imagePairs, assetsDirectory)
    }

    func loadAndProcessSVGTemp(
        entry: FlutterImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            try await context.loadImages(from: entry.svgSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing images for Flutter...") {
            try context.processImages(
                images,
                platform: .flutter,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (processResult.imagePairs, tempDir)
    }

    func loadAndProcessPNG(
        entry: FlutterImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            try await context.loadImages(from: entry.imagesSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing images for Flutter...") {
            try context.processImages(
                images,
                platform: .flutter,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (processResult.imagePairs, tempDir)
    }

    func loadAndProcessPNGDirect(
        entry: FlutterImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            try await context.loadImages(from: entry.imagesSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing images for Flutter...") {
            try context.processImages(
                images,
                platform: .flutter,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        return (processResult.imagePairs, assetsDirectory)
    }

    func generateDartFile(
        imagePairs: [AssetPair<ImagePack>],
        entry: FlutterImagesEntry,
        platformConfig: FlutterPlatformConfig,
        format: String,
        scales: [Double]
    ) throws -> FileContents {
        let assetsDirectory = URL(fileURLWithPath: entry.output)
        let output = FlutterOutput(
            outputDirectory: platformConfig.output,
            imagesAssetsDirectory: assetsDirectory,
            templatesPath: platformConfig.templatesPath,
            imagesClassName: entry.className
        )

        let exporter = FlutterExport.FlutterImagesExporter(
            output: output,
            outputFileName: entry.dartFile,
            scales: scales,
            format: format,
            nameStyle: entry.effectiveNameStyle
        )

        let (dartFile, _) = try exporter.export(
            images: imagePairs,
            allImageNames: nil,
            assetsPath: entry.output
        )

        return dartFile
    }
}

// MARK: - Static Helpers

private enum FlutterImagesHelpers {
    static func makeSVGRemoteFiles(
        imagePairs: [AssetPair<ImagePack>],
        assetsDirectory: URL
    ) -> [FileContents] {
        var files: [FileContents] = []

        for pair in imagePairs {
            for image in pair.light.images {
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                files.append(FileContents(
                    destination: Destination(directory: assetsDirectory, file: fileURL),
                    sourceURL: image.url
                ))
            }

            if let dark = pair.dark {
                let darkDir = assetsDirectory.appendingPathComponent("dark")
                for image in dark.images {
                    let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                    files.append(FileContents(
                        destination: Destination(directory: darkDir, file: fileURL),
                        sourceURL: image.url,
                        dark: true
                    ))
                }
            }
        }

        return files
    }

    static func makeRasterRemoteFiles(
        imagePairs: [AssetPair<ImagePack>],
        tempDirectory: URL,
        scales: [Double]
    ) throws -> [FileContents] {
        var files: [FileContents] = []

        for pair in imagePairs {
            for image in pair.light.images {
                let scale = image.scale.value
                guard scales.contains(scale) else { continue }

                guard let fileURL = URL(string: "\(image.name).png") else { continue }
                let scaleDir = tempDirectory.appendingPathComponent(String(scale))
                files.append(FileContents(
                    destination: Destination(directory: scaleDir, file: fileURL),
                    sourceURL: image.url,
                    scale: scale
                ))
            }

            if let dark = pair.dark {
                for image in dark.images {
                    let scale = image.scale.value
                    guard scales.contains(scale) else { continue }

                    guard let fileURL = URL(string: "\(image.name).png") else { continue }
                    let scaleDir = tempDirectory.appendingPathComponent("dark").appendingPathComponent(String(scale))
                    files.append(FileContents(
                        destination: Destination(directory: scaleDir, file: fileURL),
                        sourceURL: image.url,
                        scale: scale,
                        dark: true
                    ))
                }
            }
        }

        return files
    }

    static func mapToFlutterScaleDirectories(
        _ files: [FileContents],
        assetsDirectory: URL
    ) -> [FileContents] {
        files.compactMap { file -> FileContents? in
            guard let dataFile = file.dataFile else { return nil }

            // Flutter scale directories: 1x at root, 2x at 2.0x/, 3x at 3.0x/
            let scaleDirectory = file.scale == 1.0
                ? assetsDirectory
                : assetsDirectory.appendingPathComponent("\(file.scale)x")

            return FileContents(
                destination: Destination(directory: scaleDirectory, file: file.destination.file),
                dataFile: dataFile,
                scale: file.scale,
                dark: file.dark
            )
        }
    }
}

// swiftlint:enable file_length
