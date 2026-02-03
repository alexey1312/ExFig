import ExFigCore
import Foundation

/// Flutter images export configuration entry.
///
/// Supports multiple output formats:
/// - SVG (from Figma SVG source)
/// - PNG (from Figma PNG source)
/// - WebP (from PNG or SVG source)
public struct FlutterImagesEntry: Decodable, Sendable {
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

    // MARK: - Output (Flutter-specific)

    /// Output directory for assets (e.g., "assets/images").
    public let output: String

    /// Dart file name for generated code (e.g., "images.dart").
    public let dartFile: String?

    /// Class name for generated Dart code (e.g., "AppImages").
    public let className: String?

    /// Output format (png, webp, or svg).
    public let format: FlutterImageFormat?

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
        dartFile: String? = nil,
        className: String? = nil,
        format: FlutterImageFormat? = nil,
        webpOptions: WebpOptions? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.sourceFormat = sourceFormat
        self.scales = scales
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.output = output
        self.dartFile = dartFile
        self.className = className
        self.format = format
        self.webpOptions = webpOptions
    }
}

// MARK: - Flutter Image Format

/// Output format for Flutter images.
public enum FlutterImageFormat: String, Decodable, Sendable {
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
}

// MARK: - Convenience Extensions

public extension FlutterImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(fileId: String, darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            fileId: fileId,
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: sourceFormat ?? .png,
            scales: scales ?? [1.0, 2.0, 3.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Returns an ImagesSourceInput configured for SVG source.
    func svgSourceInput(fileId: String, darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            fileId: fileId,
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: .svg,
            scales: [1.0], // SVG doesn't need scales
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

    /// Effective scales for Flutter.
    var effectiveScales: [Double] {
        scales ?? [1.0, 2.0, 3.0]
    }

    /// Effective output format.
    var effectiveFormat: FlutterImageFormat {
        format ?? .png
    }

    /// Format string for the output (png, webp, svg).
    var formatString: String {
        effectiveFormat.rawValue
    }
}
