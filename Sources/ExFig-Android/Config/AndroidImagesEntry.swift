import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias AndroidImagesEntry = Android.ImagesEntry

/// Typealias for generated Android ImageFormat.
public typealias AndroidImageFormat = Android.ImageFormat

/// Typealias for generated WebpOptions.
public typealias WebpOptions = Android.WebpOptions

// MARK: - WebpOptions Convenience

public extension Android.WebpOptions {
    /// Whether to use lossless encoding.
    var lossless: Bool {
        encoding == .lossless
    }

    /// Converts to protocol-level WebpConverterOptions.
    var converterOptions: WebpConverterOptions {
        WebpConverterOptions(lossless: lossless, quality: quality)
    }
}

// MARK: - Convenience Extensions

public extension Android.ImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            figmaFileId: figmaFileId,
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

    /// Effective scales for Android.
    var effectiveScales: [Double] {
        scales?.map { Double($0) } ?? [1.0, 1.5, 2.0, 3.0, 4.0]
    }

    /// Converts entry's WebP options to protocol-level WebpConverterOptions.
    var webpConverterOptions: WebpConverterOptions? {
        webpOptions?.converterOptions
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        guard let nameStyle else { return .snakeCase }
        return nameStyle.coreNameStyle
    }

    /// Converts generated ImageFormat to ExFigCore ImageOutputFormat.
    ///
    /// - Note: Android images don't support SVG as output format.
    ///   When SVG is specified, falls back to PNG. A warning is logged at the export call site
    ///   in `AndroidImagesExport` when this fallback is triggered.
    var coreOutputFormat: ImageOutputFormat {
        switch format {
        case .png: .png
        case .webp: .webp
        case .svg: .png
        }
    }

    /// Whether the format is SVG (which falls back to PNG for images).
    var isSvgFallback: Bool {
        format == .svg
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved mainRes path: entry override or platform config fallback.
    func resolvedMainRes(fallback: URL) -> URL {
        mainRes.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved Figma file ID: entry override or global fallback.
    func resolvedFigmaFileId(fallback: String?) -> String? {
        figmaFileId ?? fallback
    }
}
