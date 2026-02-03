// swiftlint:disable type_name file_length

import ExFigCore
import Foundation
import XcodeExport

/// Exports colors from Figma Variables to iOS xcassets and Swift extensions.
///
/// This exporter handles the full export cycle:
/// 1. Loading colors from Figma Variables API
/// 2. Processing colors with name validation and styling
/// 3. Generating xcassets color sets and Swift extensions
///
/// ## Usage
///
/// ```swift
/// let exporter = iOSColorsExporter()
/// let count = try await exporter.exportColors(
///     entries: colorsEntries,
///     platformConfig: iosPlatformConfig,
///     context: colorsContext
/// )
/// ```
public struct iOSColorsExporter: ColorsExporter {
    public typealias Entry = iOSColorsEntry
    public typealias PlatformConfig = iOSPlatformConfig

    public init() {}

    /// Exports colors from Figma to iOS project.
    ///
    /// - Parameters:
    ///   - entries: Array of colors configuration entries.
    ///   - platformConfig: iOS platform configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Total number of colors exported.
    public func exportColors(
        entries: [iOSColorsEntry],
        platformConfig: iOSPlatformConfig,
        context: some ColorsExportContext
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
            context.success("Done! Exported \(totalCount) colors to Xcode project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: iOSColorsEntry,
        platformConfig: iOSPlatformConfig,
        context: some ColorsExportContext
    ) async throws -> Int {
        // 1. Load colors from Figma
        let colors = try await context.withSpinner(
            "Fetching colors from Figma (\(entry.tokensCollectionName))..."
        ) {
            try await context.loadColors(from: entry.colorsSourceInput)
        }

        // 2. Process colors
        let processResult = try await context.withSpinner("Processing colors for iOS...") {
            try context.processColors(
                colors,
                platform: .ios,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.nameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let colorPairs = processResult.colorPairs

        // 3. Export to Xcode
        try await context.withSpinner("Exporting colors to Xcode project...") {
            try exportToXcode(
                colorPairs: colorPairs,
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        return colorPairs.count
    }

    private func exportToXcode(
        colorPairs: [AssetPair<Color>],
        entry: iOSColorsEntry,
        platformConfig: iOSPlatformConfig,
        context: some ColorsExportContext
    ) throws {
        // Build assets URL
        var colorsURL: URL?
        if entry.useColorAssets {
            guard let folder = entry.assetsFolder else {
                throw iOSColorsExportError.assetsFolderNotSpecified
            }
            colorsURL = platformConfig.xcassetsPath.appendingPathComponent(folder)
        }

        // Create output configuration
        let output = XcodeColorsOutput(
            assetsColorsURL: colorsURL,
            assetsInMainBundle: platformConfig.xcassetsInMainBundle,
            assetsInSwiftPackage: platformConfig.xcassetsInSwiftPackage,
            resourceBundleNames: platformConfig.resourceBundleNames,
            addObjcAttribute: platformConfig.addObjcAttribute,
            colorSwiftURL: entry.colorSwift,
            swiftuiColorSwiftURL: entry.swiftuiColorSwift,
            groupUsingNamespace: entry.groupUsingNamespace,
            templatesPath: platformConfig.templatesPath
        )

        // Export
        let exporter = XcodeColorExporter(output: output)
        let files = try exporter.export(colorPairs: colorPairs)

        // Clean up old assets
        if entry.useColorAssets, let url = colorsURL {
            try? FileManager.default.removeItem(atPath: url.path)
        }

        // Write files
        try context.writeFiles(files)
    }
}

// MARK: - Errors

/// Errors that can occur during iOS colors export.
public enum iOSColorsExportError: LocalizedError {
    /// Assets folder not specified when useColorAssets is true.
    case assetsFolderNotSpecified

    public var errorDescription: String? {
        switch self {
        case .assetsFolderNotSpecified:
            "assetsFolder is required when useColorAssets is true"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .assetsFolderNotSpecified:
            "Add 'assetsFolder' to your iOS colors configuration"
        }
    }
}

// swiftlint:enable type_name file_length
