// swiftlint:disable type_name file_length

import ExFigCore
import Foundation
import XcodeExport

/// Exports icons from Figma frames to iOS xcassets (PDF/SVG) and Swift extensions.
///
/// This exporter handles the full export cycle:
/// 1. Loading icons from Figma frames (with optional granular cache)
/// 2. Processing icons with name validation and styling
/// 3. Generating xcassets image sets and Swift extensions
///
/// ## Usage
///
/// ```swift
/// let exporter = iOSIconsExporter()
/// let result = try await exporter.exportIcons(
///     entries: iconsEntries,
///     platformConfig: iosPlatformConfig,
///     context: iconsContext
/// )
/// ```
///
/// ## Granular Cache Support
///
/// When the context conforms to `IconsExportContextWithGranularCache` and
/// granular cache is enabled, the exporter will:
/// - Only export changed icons (based on content hash)
/// - Return computed hashes for cache update
/// - Still generate templates with all icon names
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
    /// - Returns: Export result with count and granular cache information.
    public func exportIcons(
        entries: [iOSIconsEntry],
        platformConfig: iOSPlatformConfig,
        context: some IconsExportContext
    ) async throws -> IconsExportResult {
        var results: [IconsExportResult] = []

        for entry in entries {
            let result = try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
            results.append(result)
        }

        let merged = IconsExportResult.merge(results)

        if !context.isBatchMode {
            context.success("Done! Exported \(merged.count) icons to Xcode project.")
        }

        return merged
    }

    // MARK: - Private

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func exportSingleEntry(
        entry: iOSIconsEntry,
        platformConfig: iOSPlatformConfig,
        context: some IconsExportContext
    ) async throws -> IconsExportResult {
        // Check if context supports granular cache
        let granularCacheContext = context as? (any IconsExportContextWithGranularCache)
        let useGranularCache = granularCacheContext?.isGranularCacheEnabled ?? false

        // 1. Load icons from Figma (with or without granular cache)
        let loadResult: IconsLoadOutputWithHashes
        if useGranularCache, let gcContext = granularCacheContext {
            loadResult = try await gcContext.withSpinner(
                "Fetching icons from Figma (\(entry.assetsFolder))..."
            ) {
                try await gcContext.loadIconsWithGranularCache(
                    from: entry.iconsSourceInput(fileId: ""),
                    onProgress: nil
                )
            }

            // If all icons unchanged, skip export but return metadata
            if loadResult.allSkipped {
                context.success("All icons unchanged (granular cache). Skipping export.")
                return IconsExportResult(
                    count: 0,
                    skippedCount: loadResult.allAssetMetadata.count,
                    computedHashes: loadResult.computedHashes,
                    allAssetMetadata: loadResult.allAssetMetadata
                )
            }
        } else {
            // Regular loading (no granular cache)
            let icons = try await context.withSpinner(
                "Fetching icons from Figma (\(entry.assetsFolder))..."
            ) {
                try await context.loadIcons(from: entry.iconsSourceInput(fileId: ""))
            }
            loadResult = IconsLoadOutputWithHashes(
                light: icons.light,
                dark: icons.dark
            )
        }

        // 2. Process icons
        let processResult = try await context.withSpinner("Processing icons for iOS...") {
            try context.processIcons(
                loadResult.asLoadOutput,
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

        // For granular cache: process all icon names for templates
        let allIconNames: [String]?
        let allAssetMetadata: [AssetMetadata]?
        if useGranularCache, let gcContext = granularCacheContext {
            allIconNames = gcContext.processIconNames(
                loadResult.allAssetMetadata.map(\.name),
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.nameStyle
            )
            allAssetMetadata = loadResult.allAssetMetadata.map { meta in
                AssetMetadata(
                    name: gcContext.processIconNames(
                        [meta.name],
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp,
                        nameStyle: entry.nameStyle
                    ).first ?? meta.name,
                    nodeId: meta.nodeId,
                    fileId: meta.fileId
                )
            }
        } else {
            allIconNames = nil
            allAssetMetadata = nil
        }

        let localAndRemoteFiles = try exporter.export(
            icons: iconPairs,
            allIconNames: allIconNames,
            allAssetMetadata: allAssetMetadata,
            append: context.filter != nil
        )

        // 4. Clean up old assets (only if not using filter and not granular cache)
        if context.filter == nil, !useGranularCache {
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

        // Calculate skipped count for granular cache stats
        let skippedCount = useGranularCache
            ? loadResult.allAssetMetadata.count - iconPairs.count
            : 0

        return IconsExportResult(
            count: iconPairs.count,
            skippedCount: skippedCount,
            computedHashes: loadResult.computedHashes,
            allAssetMetadata: loadResult.allAssetMetadata
        )
    }
}

// swiftlint:enable type_name file_length
