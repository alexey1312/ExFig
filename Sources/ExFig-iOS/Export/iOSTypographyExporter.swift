// swiftlint:disable type_name

import ExFigCore
import Foundation
import XcodeExport

/// Exports typography from Figma text styles to iOS Swift font extensions.
///
/// This exporter handles the full export cycle:
/// 1. Loading text styles from Figma file
/// 2. Processing text styles with name validation and styling
/// 3. Generating UIFont and SwiftUI Font extensions
///
/// ## Usage
///
/// ```swift
/// let exporter = iOSTypographyExporter()
/// let count = try await exporter.exportTypography(
///     entry: typographyEntry,
///     platformConfig: iosPlatformConfig,
///     context: typographyContext
/// )
/// ```
public struct iOSTypographyExporter: TypographyExporter {
    public typealias Entry = iOSTypographyEntry
    public typealias PlatformConfig = iOSPlatformConfig

    public init() {}

    /// Exports typography from Figma to iOS project.
    ///
    /// - Parameters:
    ///   - entry: Typography configuration entry.
    ///   - platformConfig: iOS platform configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of text styles exported.
    public func exportTypography(
        entry: iOSTypographyEntry,
        platformConfig: iOSPlatformConfig,
        context: some TypographyExportContext
    ) async throws -> Int {
        // Validate source
        guard let fileId = platformConfig.figmaFileId else {
            throw iOSTypographyExportError.figmaFileIdNotSpecified
        }

        // 1. Load text styles from Figma
        let loadOutput = try await context.withSpinner("Fetching text styles from Figma...") {
            try await context.loadTypography(
                from: TypographySourceInput(
                    fileId: fileId,
                    timeout: platformConfig.figmaTimeout
                )
            )
        }

        // 2. Process text styles
        let processResult = try await context.withSpinner("Processing typography for iOS...") {
            try context.processTypography(
                loadOutput,
                platform: .ios,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: entry.coreNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let textStyles = processResult.textStyles

        // 3. Export to Xcode
        try await context.withSpinner("Exporting typography to Xcode project...") {
            try exportToXcode(
                textStyles: textStyles,
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(textStyles.count) text styles to Xcode project.")
        }

        return textStyles.count
    }

    // MARK: - Private

    private func exportToXcode(
        textStyles: [TextStyle],
        entry: iOSTypographyEntry,
        platformConfig: iOSPlatformConfig,
        context: some TypographyExportContext
    ) throws {
        // Create output configuration
        let fontUrls = XcodeTypographyOutput.FontURLs(
            fontExtensionURL: entry.fontSwiftURL,
            swiftUIFontExtensionURL: entry.swiftUIFontSwiftURL
        )
        let labelUrls = XcodeTypographyOutput.LabelURLs(
            labelsDirectory: entry.labelsDirectoryURL,
            labelStyleExtensionsURL: entry.labelStyleSwiftURL
        )
        let urls = XcodeTypographyOutput.URLs(
            fonts: fontUrls,
            labels: labelUrls
        )
        let output = XcodeTypographyOutput(
            urls: urls,
            generateLabels: entry.generateLabels,
            addObjcAttribute: platformConfig.addObjcAttribute,
            templatesPath: platformConfig.templatesPath
        )

        // Export
        let exporter = XcodeTypographyExporter(output: output)
        let files = try exporter.export(textStyles: textStyles)

        // Write files
        try context.writeFiles(files)
    }
}

// MARK: - Errors

/// Errors that can occur during iOS typography export.
public enum iOSTypographyExportError: LocalizedError {
    /// Figma file ID not specified.
    case figmaFileIdNotSpecified

    public var errorDescription: String? {
        switch self {
        case .figmaFileIdNotSpecified:
            "figma.lightFileId is required for typography export"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .figmaFileIdNotSpecified:
            "Add 'lightFileId' to your figma configuration section"
        }
    }
}

// swiftlint:enable type_name
