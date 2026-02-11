// swiftlint:disable file_length

import ExFigCore
import Foundation
import WebExport

/// Exports icons from Figma frames to SVG files and React TSX components.
///
/// Uses the internal WebExport module for TSX component generation.
public struct WebIconsExporter: IconsExporter {
    public typealias Entry = WebIconsEntry
    public typealias PlatformConfig = WebPlatformConfig

    public init() {}

    public func exportIcons(
        entries: [WebIconsEntry],
        platformConfig: WebPlatformConfig,
        context: some IconsExportContext
    ) async throws -> IconsExportResult {
        let counts = try await parallelMapEntries(entries) { entry in
            try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }
        let totalCount = counts.reduce(0, +)

        if !context.isBatchMode {
            context.success("Done! Exported \(totalCount) icons to Web project.")
        }

        return .simple(count: totalCount)
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: WebIconsEntry,
        platformConfig: WebPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        let (iconPairs, svgDir, outputDir) = try await loadAndProcess(
            entry: entry, platformConfig: platformConfig, context: context
        )

        // Create WebOutput for component generation (entry-level overrides take priority)
        let resolvedTemplatesPath = entry.resolvedTemplatesPath(fallback: platformConfig.templatesPath)
        let output = WebOutput(
            outputDirectory: outputDir,
            iconsAssetsDirectory: svgDir,
            templatesPath: resolvedTemplatesPath
        )

        let exporter = WebExport.WebIconsExporter(
            output: output,
            generateReactComponents: entry.effectiveGenerateReactComponents,
            iconSize: entry.effectiveIconSize
        )

        let result = try exporter.export(icons: iconPairs, allIconNames: nil)

        // Download SVGs
        let remoteFiles = result.assetFiles.filter { $0.sourceURL != nil }
        let downloadedFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")

        // Build SVG data map for TSX component generation
        var svgDataMap: [String: Data] = [:]
        for file in downloadedFiles where !file.dark {
            let fileName = file.destination.file.deletingPathExtension().lastPathComponent
            if let data = file.data {
                svgDataMap[fileName] = data
            }
        }

        // Generate React TSX components with real SVG content
        let componentResult = try exporter.generateReactComponentsFromSVGData(
            icons: iconPairs,
            svgDataMap: svgDataMap
        )

        // Log warnings for skipped icons
        if !componentResult.missingDataIcons.isEmpty {
            context.warning("Skipped \(componentResult.missingDataIcons.count) icons due to missing SVG data")
        }
        if !componentResult.conversionFailedIcons.isEmpty {
            context.warning("Failed to convert \(componentResult.conversionFailedIcons.count) icons to JSX")
        }

        // Collect all files
        var allFiles: [FileContents] = downloadedFiles
        allFiles.append(contentsOf: componentResult.files)
        if let typesFile = result.typesFile {
            allFiles.append(typesFile)
        }
        if let barrelFile = result.barrelFile {
            allFiles.append(barrelFile)
        }

        // Clear output directory if not filtering
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: svgDir.path)
        }

        let filesToWrite = allFiles
        try await context.withSpinner("Writing files to Web project...") {
            try context.writeFiles(filesToWrite)
        }

        return iconPairs.count
    }

    private func loadAndProcess(
        entry: WebIconsEntry,
        platformConfig: WebPlatformConfig,
        context: some IconsExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL, URL) {
        let icons = try await context.withSpinner("Fetching icons from Figma (\(entry.outputDirectory))...") {
            try await context.loadIcons(from: entry.iconsSourceInput())
        }

        let processResult = try await context.withSpinner("Processing icons for Web...") {
            try context.processIcons(
                icons,
                platform: .web,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let svgDir = entry.svgDirectory.map { platformConfig.output.appendingPathComponent($0) }
            ?? platformConfig.output.appendingPathComponent("assets/icons")
        let outputDir = platformConfig.output.appendingPathComponent(entry.outputDirectory)

        return (processResult.iconPairs, svgDir, outputDir)
    }
}

// swiftlint:enable file_length
