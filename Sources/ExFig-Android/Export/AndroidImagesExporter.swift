// swiftlint:disable file_length

import AndroidExport
import ExFigCore
import Foundation
import SVGKit

/// Exports images from Figma frames to Android drawable resources.
///
/// Supports multiple workflows:
/// - PNG source → PNG/WebP output
/// - SVG source → VectorDrawable XML output
/// - SVG source → WebP output (rasterization)
public struct AndroidImagesExporter: ImagesExporter {
    public typealias Entry = AndroidImagesEntry
    public typealias PlatformConfig = AndroidPlatformConfig

    public init() {}

    public func exportImages(
        entries: [AndroidImagesEntry],
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> ImagesExportResult {
        var totalCount = 0

        for entry in entries {
            totalCount += try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(totalCount) images to Android project.")
        }

        return ImagesExportResult.simple(count: totalCount)
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let sourceFormat = entry.sourceFormat ?? .png
        let outputFormat = entry.format

        switch (sourceFormat, outputFormat) {
        case (.svg, .svg):
            return try await exportSVGToVectorDrawable(
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
            context.warning("Cannot convert PNG source to VectorDrawable. Use SVG source for vector output.")
            return 0
        }
    }
}

// MARK: - SVG to VectorDrawable

private extension AndroidImagesExporter {
    func exportSVGToVectorDrawable(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDirs) = try await loadAndProcessSVG(entry: entry, context: context)

        let remoteFiles = AndroidImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, lightDir: tempDirs.light, darkDir: tempDirs.dark
        )
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localFiles)

        // Convert to VectorDrawable
        let converter = NativeVectorDrawableConverter(strictPathValidation: false)
        try await context.withSpinner("Converting SVGs to vector drawables...") {
            if FileManager.default.fileExists(atPath: tempDirs.light.path) {
                try await converter.convertAsync(inputDirectoryUrl: tempDirs.light, rtlFiles: [])
            }
            if FileManager.default.fileExists(atPath: tempDirs.dark.path) {
                try await converter.convertAsync(inputDirectoryUrl: tempDirs.dark, rtlFiles: [])
            }
        }

        let (lightDir, darkDir) = outputDirectories(entry: entry, platformConfig: platformConfig)
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: lightDir.path)
            try? FileManager.default.removeItem(atPath: darkDir.path)
        }

        let xmlFiles = localFiles.map { file -> FileContents in
            let dir = file.dark ? darkDir : lightDir
            let source = file.destination.url.deletingPathExtension().appendingPathExtension("xml")
            let fileURL = file.destination.file.deletingPathExtension().appendingPathExtension("xml")
            return FileContents(destination: Destination(directory: dir, file: fileURL), dataFile: source)
        }

        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(xmlFiles)
        }

        try? FileManager.default.removeItem(at: tempDirs.light)
        try? FileManager.default.removeItem(at: tempDirs.dark)

        return imagePairs.count
    }
}

// MARK: - SVG to WebP

private extension AndroidImagesExporter {
    func exportSVGToWebp(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDirs) = try await loadAndProcessSVG(entry: entry, context: context)

        let remoteFiles = AndroidImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, lightDir: tempDirs.light, darkDir: tempDirs.dark
        )
        let localSVGFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localSVGFiles)

        let scales = entry.effectiveScales
        let webpFiles = try await context.rasterizeSVGs(
            localSVGFiles, scales: scales, to: .webp,
            progressTitle: "Rasterizing SVGs to WebP"
        )

        if context.filter == nil {
            let outputDir = platformConfig.mainRes.appendingPathComponent(entry.output)
            try? FileManager.default.removeItem(atPath: outputDir.path)
        }

        let isSingleScale = scales.count == 1
        let finalFiles = webpFiles.compactMap { file -> FileContents? in
            guard let dataFile = file.dataFile else { return nil }
            let dirName = Drawable.scaleToDrawableName(file.scale, dark: file.dark, singleScale: isSingleScale)
            let directory = platformConfig.mainRes
                .appendingPathComponent(entry.output)
                .appendingPathComponent(dirName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: file.destination.file),
                dataFile: dataFile
            )
        }

        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(finalFiles)
        }

        try? FileManager.default.removeItem(at: tempDirs.light)
        try? FileManager.default.removeItem(at: tempDirs.dark)

        return imagePairs.count
    }
}

// MARK: - SVG to PNG

private extension AndroidImagesExporter {
    func exportSVGToPNG(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDirs) = try await loadAndProcessSVG(entry: entry, context: context)

        let remoteFiles = AndroidImagesHelpers.makeSVGRemoteFiles(
            imagePairs: imagePairs, lightDir: tempDirs.light, darkDir: tempDirs.dark
        )
        let localSVGFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localSVGFiles)

        let scales = entry.effectiveScales
        let pngFiles = try await context.rasterizeSVGs(
            localSVGFiles, scales: scales, to: .png,
            progressTitle: "Rasterizing SVGs to PNG"
        )

        if context.filter == nil {
            let outputDir = platformConfig.mainRes.appendingPathComponent(entry.output)
            try? FileManager.default.removeItem(atPath: outputDir.path)
        }

        let isSingleScale = scales.count == 1
        let finalFiles = pngFiles.compactMap { file -> FileContents? in
            guard let dataFile = file.dataFile else { return nil }
            let dirName = Drawable.scaleToDrawableName(file.scale, dark: file.dark, singleScale: isSingleScale)
            let directory = platformConfig.mainRes
                .appendingPathComponent(entry.output)
                .appendingPathComponent(dirName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: file.destination.file),
                dataFile: dataFile
            )
        }

        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(finalFiles)
        }

        try? FileManager.default.removeItem(at: tempDirs.light)
        try? FileManager.default.removeItem(at: tempDirs.dark)

        return imagePairs.count
    }
}

// MARK: - PNG to WebP

private extension AndroidImagesExporter {
    func exportPNGToWebp(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDir) = try await loadAndProcessPNG(entry: entry, context: context)

        let remoteFiles = try AndroidImagesHelpers.makeRasterRemoteFiles(
            imagePairs: imagePairs, outputDirectory: tempDir
        )
        var localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading images")
        try context.writeFiles(localFiles)

        // Convert PNG to WebP
        localFiles = try await context.convertFormat(
            localFiles, to: .webp,
            heicOptions: nil, webpOptions: entry.webpConverterOptions,
            progressTitle: "Converting to WebP"
        )

        if context.filter == nil {
            let outputDir = platformConfig.mainRes.appendingPathComponent(entry.output)
            try? FileManager.default.removeItem(atPath: outputDir.path)
        }

        let scales = entry.effectiveScales
        let isSingleScale = scales.count == 1
        let finalFiles = localFiles.map { file -> FileContents in
            let dirName = Drawable.scaleToDrawableName(file.scale, dark: file.dark, singleScale: isSingleScale)
            let directory = platformConfig.mainRes
                .appendingPathComponent(entry.output)
                .appendingPathComponent(dirName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: file.destination.file),
                dataFile: file.destination.url
            )
        }

        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(finalFiles)
        }

        try? FileManager.default.removeItem(at: tempDir)

        return imagePairs.count
    }
}

// MARK: - PNG to PNG

private extension AndroidImagesExporter {
    func exportPNGToPNG(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, tempDir) = try await loadAndProcessPNG(entry: entry, context: context)

        let remoteFiles = try AndroidImagesHelpers.makeRasterRemoteFiles(
            imagePairs: imagePairs, outputDirectory: tempDir
        )
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading images")
        try context.writeFiles(localFiles)

        if context.filter == nil {
            let outputDir = platformConfig.mainRes.appendingPathComponent(entry.output)
            try? FileManager.default.removeItem(atPath: outputDir.path)
        }

        let scales = entry.effectiveScales
        let isSingleScale = scales.count == 1
        let finalFiles = localFiles.map { file -> FileContents in
            let dirName = Drawable.scaleToDrawableName(file.scale, dark: file.dark, singleScale: isSingleScale)
            let directory = platformConfig.mainRes
                .appendingPathComponent(entry.output)
                .appendingPathComponent(dirName, isDirectory: true)
            return FileContents(
                destination: Destination(directory: directory, file: file.destination.file),
                dataFile: file.destination.url
            )
        }

        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(finalFiles)
        }

        try? FileManager.default.removeItem(at: tempDir)

        return imagePairs.count
    }
}

// MARK: - Load & Process

private extension AndroidImagesExporter {
    func loadAndProcessSVG(
        entry: AndroidImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], (light: URL, dark: URL)) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            let input = ImagesSourceInput(
                frameName: entry.figmaFrameName ?? "Images",
                sourceFormat: .svg,
                scales: [1.0],
                useSingleFile: true,
                darkModeSuffix: "_dark",
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp
            )
            return try await context.loadImages(from: input)
        }

        let processResult = try await context.withSpinner("Processing images for Android...") {
            try context.processImages(
                images,
                platform: .android,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: .snakeCase
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let tempLight = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempDark = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (processResult.imagePairs, (light: tempLight, dark: tempDark))
    }

    func loadAndProcessPNG(
        entry: AndroidImagesEntry,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.output))...") {
            try await context.loadImages(from: entry.imagesSourceInput())
        }

        let processResult = try await context.withSpinner("Processing images for Android...") {
            try context.processImages(
                images,
                platform: .android,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: .snakeCase
            )
        }

        if let warning = processResult.warning { context.warning(warning) }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (processResult.imagePairs, tempDir)
    }

    func outputDirectories(
        entry: AndroidImagesEntry,
        platformConfig: AndroidPlatformConfig
    ) -> (light: URL, dark: URL) {
        let lightDir = platformConfig.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable", isDirectory: true)
        let darkDir = platformConfig.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable-night", isDirectory: true)
        return (lightDir, darkDir)
    }
}

// MARK: - Static Helpers

private enum AndroidImagesHelpers {
    static func makeSVGRemoteFiles(
        imagePairs: [AssetPair<ImagePack>],
        lightDir: URL,
        darkDir: URL
    ) -> [FileContents] {
        var files: [FileContents] = []

        for pair in imagePairs {
            for image in pair.light.images {
                let fileURL = URL(fileURLWithPath: "\(image.name).svg")
                files.append(FileContents(
                    destination: Destination(directory: lightDir, file: fileURL),
                    sourceURL: image.url
                ))
            }

            if let dark = pair.dark {
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
        outputDirectory: URL
    ) throws -> [FileContents] {
        var files: [FileContents] = []

        for pair in imagePairs {
            try files.append(contentsOf: makeRemoteFiles(
                images: pair.light.images, dark: false, outputDirectory: outputDirectory
            ))

            if let dark = pair.dark {
                try files.append(contentsOf: makeRemoteFiles(
                    images: dark.images, dark: true, outputDirectory: outputDirectory
                ))
            }
        }

        return files
    }

    static func makeRemoteFiles(
        images: [Image],
        dark: Bool,
        outputDirectory: URL
    ) throws -> [FileContents] {
        try images.map { image -> FileContents in
            guard let name = image.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let fileURL = URL(string: "\(name).\(image.format)")
            else {
                throw AndroidImagesExporterError.invalidFileName(image.name)
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
}

// MARK: - Error

enum AndroidImagesExporterError: LocalizedError {
    case invalidFileName(String)

    var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        }
    }
}

// swiftlint:enable file_length
