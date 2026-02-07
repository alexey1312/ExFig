import ExFigCore
import Foundation
import WebExport

/// Exports images from Figma frames to optimized web formats and React components.
///
/// Uses the internal WebExport module for TSX component generation.
public struct WebImagesExporter: ImagesExporter {
    public typealias Entry = WebImagesEntry
    public typealias PlatformConfig = WebPlatformConfig

    public init() {}

    public func exportImages(
        entries: [WebImagesEntry],
        platformConfig: WebPlatformConfig,
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
            context.success("Done! Exported \(totalCount) images to Web project.")
        }

        return ImagesExportResult.simple(count: totalCount)
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: WebImagesEntry,
        platformConfig: WebPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int {
        let (imagePairs, assetsDir, outputDir) = try await loadAndProcess(
            entry: entry, platformConfig: platformConfig, context: context
        )

        // Create WebOutput for component generation
        let output = WebOutput(
            outputDirectory: outputDir,
            imagesAssetsDirectory: assetsDir,
            templatesPath: platformConfig.templatesPath
        )

        let exporter = WebExport.WebImagesExporter(
            output: output,
            generateReactComponents: entry.effectiveGenerateReactComponents
        )

        let result = try exporter.export(images: imagePairs, allImageNames: nil)

        // Download assets
        let remoteFiles = result.assetFiles.filter { $0.sourceURL != nil }
        let downloadedFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading images")

        // Collect all files
        var allFiles: [FileContents] = result.componentFiles
        allFiles.append(contentsOf: downloadedFiles)
        if let barrelFile = result.barrelFile {
            allFiles.append(barrelFile)
        }

        // Clear output directory if not filtering
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDir.path)
        }

        let filesToWrite = allFiles
        try await context.withSpinner("Writing files to Web project...") {
            try context.writeFiles(filesToWrite)
        }

        return imagePairs.count
    }

    private func loadAndProcess(
        entry: WebImagesEntry,
        platformConfig: WebPlatformConfig,
        context: some ImagesExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL, URL) {
        let images = try await context.withSpinner("Fetching images from Figma (\(entry.outputDirectory))...") {
            try await context.loadImages(from: entry.imagesSourceInput())
        }

        let processResult = try await context.withSpinner("Processing images for Web...") {
            try context.processImages(
                images,
                platform: .web,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let assetsDir = entry.assetsDirectory.map { platformConfig.output.appendingPathComponent($0) }
            ?? platformConfig.output.appendingPathComponent("assets/images")
        let outputDir = platformConfig.output.appendingPathComponent(entry.outputDirectory)

        return (processResult.imagePairs, assetsDir, outputDir)
    }
}
