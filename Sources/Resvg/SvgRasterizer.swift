import CResvg
import Foundation

/// Result of SVG rasterization containing RGBA pixel data
public struct RasterizedSvg: Sendable {
    public let width: Int
    public let height: Int
    public let rgba: [UInt8]

    /// Total number of bytes (should equal width * height * 4)
    public var byteCount: Int { rgba.count }

    public init(width: Int, height: Int, rgba: [UInt8]) {
        self.width = width
        self.height = height
        self.rgba = rgba
    }
}

/// Rasterizes SVG images to RGBA pixel data using resvg
///
/// Uses the resvg library (Rust-based, high-quality SVG renderer) via C bindings.
/// Supports all standard SVG features and produces identical results across platforms.
public struct SvgRasterizer: Sendable {
    public init() {}

    /// Rasterizes an SVG file to RGBA pixel data
    /// - Parameters:
    ///   - url: Path to SVG file
    ///   - scale: Scale factor for output resolution (1.0 = native size)
    /// - Returns: Rasterized image with width, height, and RGBA bytes
    /// - Throws: `ResvgError` on failure
    public func rasterize(file url: URL, scale: Double = 1.0) throws -> RasterizedSvg {
        let data = try Data(contentsOf: url)
        return try rasterize(data: data, scale: scale)
    }

    /// Rasterizes SVG data to RGBA pixel data
    /// - Parameters:
    ///   - data: SVG file data (UTF-8 string or gzip compressed)
    ///   - scale: Scale factor for output resolution (1.0 = native size)
    /// - Returns: Rasterized image with width, height, and RGBA bytes
    /// - Throws: `ResvgError` on failure
    public func rasterize(data: Data, scale: Double = 1.0) throws -> RasterizedSvg {
        // Create options
        guard let opt = resvg_options_create() else {
            throw ResvgError.unknownError(code: -1)
        }
        defer { resvg_options_destroy(opt) }

        // Parse SVG tree
        var tree: OpaquePointer?
        let result = data.withUnsafeBytes { ptr -> Int32 in
            guard let baseAddress = ptr.baseAddress else {
                return Int32(RESVG_ERROR_PARSING_FAILED.rawValue)
            }
            return resvg_parse_tree_from_data(
                baseAddress.assumingMemoryBound(to: CChar.self),
                UInt(ptr.count),
                opt,
                &tree
            )
        }

        // Check for parsing errors
        if let error = ResvgError.fromCode(result) {
            throw error
        }

        guard let tree else {
            throw ResvgError.parsingFailed
        }
        defer { resvg_tree_destroy(tree) }

        // Check if image is empty
        if resvg_is_image_empty(tree) {
            throw ResvgError.emptyImage
        }

        // Get original size and compute scaled dimensions
        let size = resvg_get_image_size(tree)
        let width = Int(Double(size.width) * scale)
        let height = Int(Double(size.height) * scale)

        guard width > 0, height > 0 else {
            throw ResvgError.invalidSize
        }

        // Allocate pixmap buffer
        var pixmap = [UInt8](repeating: 0, count: width * height * 4)

        // Create transform for scaling
        let transform = resvg_transform(
            a: Float(scale),
            b: 0,
            c: 0,
            d: Float(scale),
            e: 0,
            f: 0
        )

        // Render SVG to pixmap
        pixmap.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            resvg_render(
                tree,
                transform,
                UInt32(width),
                UInt32(height),
                baseAddress.assumingMemoryBound(to: CChar.self)
            )
        }

        // Unpremultiply alpha (resvg outputs premultiplied RGBA)
        unpremultiplyAlpha(&pixmap)

        return RasterizedSvg(width: width, height: height, rgba: pixmap)
    }

    /// Unpremultiplies alpha values to get correct RGB values
    ///
    /// resvg outputs premultiplied RGBA where RGB = RGB * alpha.
    /// We need straight alpha (RGB independent of alpha) for WebP encoding.
    private func unpremultiplyAlpha(_ rgba: inout [UInt8]) {
        let pixelCount = rgba.count / 4
        for i in 0 ..< pixelCount {
            let offset = i * 4
            let alpha = rgba[offset + 3]

            if alpha > 0, alpha < 255 {
                let alphaFloat = Float(alpha) / 255.0
                rgba[offset] = UInt8(min(255, Float(rgba[offset]) / alphaFloat))
                rgba[offset + 1] = UInt8(min(255, Float(rgba[offset + 1]) / alphaFloat))
                rgba[offset + 2] = UInt8(min(255, Float(rgba[offset + 2]) / alphaFloat))
            }
        }
    }
}
