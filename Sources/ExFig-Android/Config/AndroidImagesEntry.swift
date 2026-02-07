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
        switch nameStyle {
        case .camelCase: return .camelCase
        case .snake_case: return .snakeCase
        case .pascalCase: return .pascalCase
        case .flatCase: return .flatCase
        case .kebab_case: return .kebabCase
        case .sCREAMING_SNAKE_CASE: return .screamingSnakeCase
        }
    }

    /// Converts generated ImageFormat to ExFigCore ImageOutputFormat.
    var coreOutputFormat: ImageOutputFormat {
        switch format {
        case .png: .png
        case .webp: .webp
        case .svg: .png // SVG doesn't map to output format, default to png
        }
    }
}
