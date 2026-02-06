import ExFigCore
import Foundation

/// Android images export configuration entry.
///
/// Supports multiple output formats:
/// - PNG (from Figma PNG source)
/// - WebP (from PNG or SVG source)
/// - SVG/VectorDrawable (from SVG source)
public struct AndroidImagesEntry: Decodable, Sendable {
    // MARK: - Source (Figma Frame)

    /// Figma frame name containing images. Overrides common.images.figmaFrameName.
    public let figmaFrameName: String?

    /// Source format for fetching from Figma API (png or svg).
    public let sourceFormat: ImageSourceFormat?

    /// Scale factors for raster images.
    public let scales: [Double]?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering image names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    /// Naming style for generated identifiers.
    public let nameStyle: NameStyle?

    // MARK: - Output (Android-specific)

    /// Output directory name under res/ (e.g., "drawable-images" → res/drawable-images/).
    public let output: String

    /// Output format (png, webp, or svg).
    public let format: AndroidImageFormat

    /// WebP encoding options.
    public let webpOptions: WebpOptions?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        sourceFormat: ImageSourceFormat? = nil,
        scales: [Double]? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle? = nil,
        output: String,
        format: AndroidImageFormat,
        webpOptions: WebpOptions? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.sourceFormat = sourceFormat
        self.scales = scales
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.output = output
        self.format = format
        self.webpOptions = webpOptions
    }
}

// MARK: - Android Image Format

/// Output format for Android images.
public enum AndroidImageFormat: String, Decodable, Sendable {
    case png
    case webp
    case svg
}

// MARK: - WebP Options

/// Options for WebP encoding.
public struct WebpOptions: Decodable, Sendable {
    /// Use lossless compression.
    public let lossless: Bool?

    /// Compression quality (0-100). Only used for lossy compression.
    public let quality: Int?

    public init(lossless: Bool? = nil, quality: Int? = nil) {
        self.lossless = lossless
        self.quality = quality
    }

    /// Converts to protocol-level ``WebpConverterOptions``.
    public var converterOptions: WebpConverterOptions {
        WebpConverterOptions(lossless: lossless, quality: quality)
    }
}

// MARK: - Converter Options

public extension AndroidImagesEntry {
    /// Converts entry's WebP options to protocol-level ``WebpConverterOptions``.
    var webpConverterOptions: WebpConverterOptions? {
        webpOptions?.converterOptions
    }
}

// MARK: - Convenience Extensions

public extension AndroidImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: sourceFormat ?? .png,
            scales: scales ?? [1.0, 1.5, 2.0, 3.0, 4.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        nameStyle ?? .snakeCase
    }

    /// Effective scales for Android.
    var effectiveScales: [Double] {
        scales ?? [1.0, 1.5, 2.0, 3.0, 4.0]
    }
}
