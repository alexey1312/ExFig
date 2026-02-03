import ExFigCore
import FlutterExport
import Foundation

/// Exports icons from Figma frames to Flutter SVG assets and Dart code.
///
/// Uses the internal FlutterExport module for Dart code generation.
public struct FlutterIconsExporter: IconsExporter {
    public typealias Entry = FlutterIconsEntry
    public typealias PlatformConfig = FlutterPlatformConfig

    public init() {}

    public func exportIcons(
        entries: [FlutterIconsEntry],
        platformConfig: FlutterPlatformConfig,
        context: some IconsExportContext
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
            context.success("Done! Exported \(totalCount) icons to Flutter project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: FlutterIconsEntry,
        platformConfig: FlutterPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        let (iconPairs, assetsDirectory) = try await loadAndProcess(entry: entry, context: context)

        // Create FlutterOutput for Dart code generation
        let output = FlutterOutput(
            outputDirectory: platformConfig.output,
            iconsAssetsDirectory: assetsDirectory,
            templatesPath: platformConfig.templatesPath,
            iconsClassName: entry.className
        )

        let exporter = FlutterExport.FlutterIconsExporter(
            output: output,
            outputFileName: entry.dartFile,
            nameStyle: entry.effectiveNameStyle
        )

        let (dartFile, assetFiles) = try exporter.export(
            icons: iconPairs,
            allIconNames: nil,
            assetsPath: entry.output
        )

        // Download SVG files
        let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")

        // Clear output directory if not filtering
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsDirectory.path)
        }

        // Write all files
        let allFiles = localFiles + [dartFile]

        try await context.withSpinner("Writing files to Flutter project...") {
            try context.writeFiles(allFiles)
        }

        return iconPairs.count
    }

    private func loadAndProcess(
        entry: FlutterIconsEntry,
        context: some IconsExportContext
    ) async throws -> ([AssetPair<ImagePack>], URL) {
        let icons = try await context.withSpinner("Fetching icons from Figma (\(entry.output))...") {
            try await context.loadIcons(from: entry.iconsSourceInput(fileId: ""))
        }

        let processResult = try await context.withSpinner("Processing icons for Flutter...") {
            try context.processIcons(
                icons,
                platform: .flutter,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let assetsDirectory = URL(fileURLWithPath: entry.output)
        return (processResult.iconPairs, assetsDirectory)
    }
}
