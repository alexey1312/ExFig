import Foundation

/// Factory for creating HEIC and SVG-to-HEIC converters from format options.
enum HeicConverterFactory {
    /// Creates a HEIC converter from format options.
    /// - Parameter options: Optional HEIC options specifying encoding and quality.
    /// - Returns: Configured HeicConverter instance.
    static func createHeicConverter(
        from options: PKLConfig.HeicOptions?
    ) -> HeicConverter {
        let quality = options?.resolvedQuality ?? 90
        let isLossless = options?.resolvedEncoding == .lossless

        if isLossless {
            return HeicConverter(encoding: .lossless)
        } else {
            return HeicConverter(encoding: .lossy(quality: quality))
        }
    }

    /// Creates an SVG-to-HEIC converter from format options.
    /// - Parameter options: Optional HEIC options specifying encoding and quality.
    /// - Returns: Configured SvgToHeicConverter instance.
    static func createSvgToHeicConverter(
        from options: PKLConfig.HeicOptions?
    ) -> SvgToHeicConverter {
        let quality = options?.resolvedQuality ?? 90
        let isLossless = options?.resolvedEncoding == .lossless

        if isLossless {
            return SvgToHeicConverter(encoding: .lossless)
        } else {
            return SvgToHeicConverter(encoding: .lossy(quality: quality))
        }
    }
}
