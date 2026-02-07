import Foundation

// MARK: - HEIC Converter Options

/// Protocol-level HEIC converter options.
///
/// Used to pass HEIC encoding configuration from platform entry types
/// through ``ImagesExportContext`` to the actual converter factories.
/// Defined at the ExFigCore level so platform plugins can use it
/// without depending on ExFigConfig/PKLConfig.
public struct HeicConverterOptions: Sendable {
    /// HEIC encoding mode.
    public enum Encoding: String, Sendable {
        case lossy
        case lossless
    }

    /// Encoding mode (lossy or lossless).
    public let encoding: Encoding?

    /// Compression quality (0-100). Only used for lossy encoding.
    public let quality: Int?

    public init(encoding: Encoding? = nil, quality: Int? = nil) {
        self.encoding = encoding
        self.quality = quality
    }
}

// MARK: - WebP Converter Options

/// Protocol-level WebP converter options.
///
/// Used to pass WebP encoding configuration from platform entry types
/// through ``ImagesExportContext`` to the actual converter factories.
/// Defined at the ExFigCore level so platform plugins can use it
/// without depending on ExFigConfig/PKLConfig.
public struct WebpConverterOptions: Sendable {
    /// Whether to use lossless compression.
    public let lossless: Bool?

    /// Compression quality (0-100). Only used for lossy compression.
    public let quality: Int?

    public init(lossless: Bool? = nil, quality: Int? = nil) {
        self.lossless = lossless
        self.quality = quality
    }
}
