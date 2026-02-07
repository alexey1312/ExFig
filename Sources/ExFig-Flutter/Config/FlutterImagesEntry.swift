import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias FlutterImagesEntry = Flutter.ImagesEntry

/// Typealias for generated Flutter ImageFormat.
public typealias FlutterImageFormat = Flutter.ImageFormat

// MARK: - Convenience Extensions

public extension Flutter.ImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: sourceFormat.flatMap { ImageSourceFormat(rawValue: $0.rawValue) } ?? .png,
            scales: effectiveScales,
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Returns an ImagesSourceInput configured for SVG source.
    func svgSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: .svg,
            scales: [1.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        guard let nameStyle else { return .snakeCase }
        switch nameStyle {
        case .camelCase: return .camelCase
        case .snake_case: return .snakeCase
        case .pascalCase: return .pascalCase
        case .flatCase: return .flatCase
        case .kebabCase: return .kebabCase
        case .sCREAMING_SNAKE_CASE: return .screamingSnakeCase
        }
    }

    /// Effective scales for Flutter.
    var effectiveScales: [Double] {
        scales?.map { Double($0) } ?? [1.0, 2.0, 3.0]
    }

    /// Effective output format.
    var effectiveFormat: Flutter.ImageFormat {
        format ?? .png
    }

    /// Format string for the output (png, webp, svg).
    var formatString: String {
        effectiveFormat.rawValue
    }

    /// Converts entry's WebP options to protocol-level WebpConverterOptions.
    var webpConverterOptions: WebpConverterOptions? {
        guard let opts = webpOptions else { return nil }
        return WebpConverterOptions(lossless: opts.encoding == .lossless, quality: opts.quality)
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved Figma file ID: entry override or global fallback.
    func resolvedFigmaFileId(fallback: String?) -> String? {
        figmaFileId ?? fallback
    }
}
