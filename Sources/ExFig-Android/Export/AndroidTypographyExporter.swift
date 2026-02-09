import AndroidExport
import ExFigCore
import Foundation

/// Exports typography from Figma text styles to Android XML styles and Kotlin.
///
/// This exporter handles the full export cycle:
/// 1. Loading text styles from Figma file
/// 2. Processing text styles with name validation and styling
/// 3. Generating typography.xml and Kotlin Typography class
///
/// ## Usage
///
/// ```swift
/// let exporter = AndroidTypographyExporter()
/// let count = try await exporter.exportTypography(
///     entry: typographyEntry,
///     platformConfig: androidPlatformConfig,
///     context: typographyContext
/// )
/// ```
public struct AndroidTypographyExporter: TypographyExporter {
    public typealias Entry = AndroidTypographyEntry
    public typealias PlatformConfig = AndroidPlatformConfig

    public init() {}

    /// Exports typography from Figma to Android project.
    ///
    /// - Parameters:
    ///   - entry: Typography configuration entry.
    ///   - platformConfig: Android platform configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of text styles exported.
    public func exportTypography(
        entry: AndroidTypographyEntry,
        platformConfig: AndroidPlatformConfig,
        context: some TypographyExportContext
    ) async throws -> Int {
        // Validate source — per-entry fileId takes priority over platform-level
        guard let fileId = entry.fileId ?? platformConfig.figmaFileId else {
            throw AndroidTypographyExportError.figmaFileIdNotSpecified
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
        let processResult = try await context.withSpinner("Processing typography for Android...") {
            try context.processTypography(
                loadOutput,
                platform: .android,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.coreNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let textStyles = processResult.textStyles

        // 3. Export to Android
        try await context.withSpinner("Exporting typography to Android project...") {
            try exportToAndroid(
                textStyles: textStyles,
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(textStyles.count) text styles to Android project.")
        }

        return textStyles.count
    }

    // MARK: - Private

    private func exportToAndroid(
        textStyles: [TextStyle],
        entry: AndroidTypographyEntry,
        platformConfig: AndroidPlatformConfig,
        context: some TypographyExportContext
    ) throws {
        // Create output configuration
        let output = AndroidOutput(
            xmlOutputDirectory: platformConfig.mainRes,
            xmlResourcePackage: platformConfig.resourcePackage,
            srcDirectory: platformConfig.mainSrc,
            packageName: entry.composePackageName,
            colorKotlinURL: nil,
            templatesPath: platformConfig.templatesPath
        )

        // Export
        let exporter = AndroidExport.AndroidTypographyExporter(output: output)
        let files = try exporter.exportFonts(textStyles: textStyles)

        // Clean up old typography.xml before writing
        let fileURL = platformConfig.mainRes.appendingPathComponent("values/typography.xml")
        try? FileManager.default.removeItem(atPath: fileURL.path)

        // Write files
        try context.writeFiles(files)
    }
}

// MARK: - Errors

/// Errors that can occur during Android typography export.
public enum AndroidTypographyExportError: LocalizedError {
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
