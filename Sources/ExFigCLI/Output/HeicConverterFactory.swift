import ExFigCore
import Foundation

/// Factory for creating HEIC and SVG-to-HEIC converters from format options.
enum HeicConverterFactory {
    /// Creates a HEIC converter from converter options.
    /// - Parameter options: Optional HEIC options specifying encoding and quality.
    /// - Returns: Configured HeicConverter instance.
    static func createHeicConverter(
        from options: HeicConverterOptions?
    ) -> HeicConverter {
        let quality = options?.quality ?? 90
        let isLossless = options?.encoding == .lossless

        if isLossless {
            return HeicConverter(encoding: .lossless)
        } else {
            return HeicConverter(encoding: .lossy(quality: quality))
        }
    }

    /// Creates an SVG-to-HEIC converter from converter options.
    /// - Parameter options: Optional HEIC options specifying encoding and quality.
    /// - Returns: Configured SvgToHeicConverter instance.
    static func createSvgToHeicConverter(
        from options: HeicConverterOptions?
    ) -> SvgToHeicConverter {
        let quality = options?.quality ?? 90
        let isLossless = options?.encoding == .lossless

        if isLossless {
            return SvgToHeicConverter(encoding: .lossless)
        } else {
            return SvgToHeicConverter(encoding: .lossy(quality: quality))
        }
    }
}
