// swiftlint:disable type_name file_length

import ExFigCore
import Foundation
import XcodeExport

/// Exports icons from Figma frames to iOS xcassets (PDF/SVG) and Swift extensions.
///
/// This exporter handles the full export cycle:
/// 1. Loading icons from Figma frames
/// 2. Processing icons with name validation and styling
/// 3. Generating xcassets image sets and Swift extensions
///
/// ## Usage
///
/// ```swift
/// let exporter = iOSIconsExporter()
/// let count = try await exporter.exportIcons(
///     entries: iconsEntries,
///     platformConfig: iosPlatformConfig,
///     context: iconsContext
/// )
/// ```
public struct iOSIconsExporter: IconsExporter {
    public typealias Entry = iOSIconsEntry
    public typealias PlatformConfig = iOSPlatformConfig

    public init() {}

    /// Exports icons from Figma to iOS project.
    ///
    /// - Parameters:
    ///   - entries: Array of icons configuration entries.
    ///   - platformConfig: iOS platform configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Total number of icons exported.
    public func exportIcons(
        entries: [iOSIconsEntry],
        platformConfig: iOSPlatformConfig,
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
            context.success("Done! Exported \(totalCount) icons to Xcode project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: iOSIconsEntry,
        platformConfig: iOSPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        // 1. Load icons from Figma
        let icons = try await context.withSpinner(
            "Fetching icons from Figma (\(entry.assetsFolder))..."
        ) {
            // Note: fileId comes from common config, passed via context
            try await context.loadIcons(from: entry.iconsSourceInput(fileId: ""))
        }

        // 2. Process icons
        let processResult = try await context.withSpinner("Processing icons for iOS...") {
            try context.processIcons(
                icons,
                platform: .ios,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.nameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let iconPairs = processResult.iconPairs

        // 3. Generate files
        let assetsURL = platformConfig.xcassetsPath.appendingPathComponent(entry.assetsFolder)

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsURL,
            assetsInMainBundle: platformConfig.xcassetsInMainBundle,
            assetsInSwiftPackage: platformConfig.xcassetsInSwiftPackage,
            resourceBundleNames: platformConfig.resourceBundleNames,
            addObjcAttribute: platformConfig.addObjcAttribute,
            preservesVectorRepresentation: entry.preservesVectorRepresentation,
            uiKitImageExtensionURL: entry.imageSwift,
            swiftUIImageExtensionURL: entry.swiftUIImageSwift,
            codeConnectSwiftURL: entry.codeConnectSwift,
            templatesPath: platformConfig.templatesPath
        )

        let exporter = XcodeIconsExporter(output: output)
        let localAndRemoteFiles = try exporter.export(
            icons: iconPairs,
            allIconNames: nil,
            allAssetMetadata: nil,
            append: context.filter != nil
        )

        // 4. Clean up old assets
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: assetsURL.path)
        }

        // 5. Download remote files
        let localFiles = try await context.downloadFiles(
            localAndRemoteFiles,
            progressTitle: "Downloading icons"
        )

        // 6. Write files
        try await context.withSpinner("Writing files to Xcode project...") {
            try context.writeFiles(localFiles)
        }

        return iconPairs.count
    }
}

// swiftlint:enable type_name file_length
