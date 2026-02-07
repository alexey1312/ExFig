import ExFigCore
import Foundation

/// Factory for creating WebP and SVG-to-WebP converters from format options.
enum WebpConverterFactory {
    /// Creates a WebP converter from converter options.
    /// - Parameter options: Optional format options specifying encoding and quality.
    /// - Returns: Configured WebpConverter instance.
    static func createWebpConverter(
        from options: WebpConverterOptions?
    ) -> WebpConverter {
        guard let options else {
            // Default: lossy with quality 90
            return WebpConverter(encoding: .lossy(quality: 90))
        }

        if options.lossless == true {
            return WebpConverter(encoding: .lossless)
        } else if let quality = options.quality {
            return WebpConverter(encoding: .lossy(quality: quality))
        } else {
            return WebpConverter(encoding: .lossy(quality: 90))
        }
    }

    /// Creates an SVG-to-WebP converter from converter options.
    /// - Parameter options: Optional format options specifying encoding and quality.
    /// - Returns: Configured SvgToWebpConverter instance.
    static func createSvgToWebpConverter(
        from options: WebpConverterOptions?
    ) -> SvgToWebpConverter {
        guard let options else {
            // Default: lossy with quality 90
            return SvgToWebpConverter(encoding: .lossy(quality: 90))
        }

        if options.lossless == true {
            return SvgToWebpConverter(encoding: .lossless)
        } else if let quality = options.quality {
            return SvgToWebpConverter(encoding: .lossy(quality: quality))
        } else {
            return SvgToWebpConverter(encoding: .lossy(quality: 90))
        }
    }
}
