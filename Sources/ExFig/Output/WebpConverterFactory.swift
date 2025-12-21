import Foundation

/// Factory for creating WebP and SVG-to-WebP converters from format options.
enum WebpConverterFactory {
    /// Creates a WebP converter from format options.
    /// - Parameter options: Optional format options specifying encoding and quality.
    /// - Returns: Configured WebpConverter instance.
    static func createWebpConverter(
        from options: Params.Android.Images.FormatOptions?
    ) -> WebpConverter {
        guard let options else {
            // Default: lossy with quality 90
            return WebpConverter(encoding: .lossy(quality: 90))
        }

        switch (options.encoding, options.quality) {
        case (.lossless, _):
            return WebpConverter(encoding: .lossless)
        case let (.lossy, quality?):
            return WebpConverter(encoding: .lossy(quality: quality))
        case (.lossy, .none):
            // Lossy without quality specified - use default 90
            return WebpConverter(encoding: .lossy(quality: 90))
        }
    }

    /// Creates an SVG-to-WebP converter from format options.
    /// - Parameter options: Optional format options specifying encoding and quality.
    /// - Returns: Configured SvgToWebpConverter instance.
    static func createSvgToWebpConverter(
        from options: Params.Android.Images.FormatOptions?
    ) -> SvgToWebpConverter {
        guard let options else {
            // Default: lossy with quality 90
            return SvgToWebpConverter(encoding: .lossy(quality: 90))
        }

        switch (options.encoding, options.quality) {
        case (.lossless, _):
            return SvgToWebpConverter(encoding: .lossless)
        case let (.lossy, quality?):
            return SvgToWebpConverter(encoding: .lossy(quality: quality))
        case (.lossy, .none):
            return SvgToWebpConverter(encoding: .lossy(quality: 90))
        }
    }
}
