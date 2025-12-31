import CResvg
import Foundation

/// Normalizes SVG data using usvg (part of resvg)
///
/// Normalization applies SVG spec defaults and resolves references:
/// - Missing fill attributes default to black (#000000)
/// - CSS styles are resolved and inlined
/// - `<use>` references are expanded inline
/// - clip-path elements are resolved
/// - Transforms are applied and simplified
///
/// This produces a simplified SVG that can be parsed without
/// needing full SVG/CSS spec compliance.
public struct SvgNormalizer: Sendable {
    public init() {}

    /// Normalizes SVG data using usvg
    ///
    /// - Parameter data: Raw SVG data (UTF-8 or gzip compressed)
    /// - Returns: Normalized SVG data as UTF-8
    /// - Throws: `ResvgError` on parsing or export failure
    public func normalize(_ data: Data) throws -> Data {
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

        // Export normalized SVG
        var len: UInt = 0
        guard let svgPtr = resvg_tree_to_svg(tree, &len) else {
            throw ResvgError.svgExportFailed
        }
        defer { resvg_svg_string_destroy(svgPtr) }

        // Copy to Swift Data
        return Data(bytes: svgPtr, count: Int(len))
    }

    /// Normalizes SVG from a file
    ///
    /// - Parameter url: Path to SVG file
    /// - Returns: Normalized SVG data as UTF-8
    /// - Throws: `ResvgError` on parsing or export failure
    public func normalize(file url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        return try normalize(data)
    }

    /// Normalizes SVG and returns as String
    ///
    /// - Parameter data: Raw SVG data (UTF-8 or gzip compressed)
    /// - Returns: Normalized SVG as UTF-8 string
    /// - Throws: `ResvgError` on parsing or export failure
    public func normalizeToString(_ data: Data) throws -> String {
        let normalized = try normalize(data)
        guard let string = String(data: normalized, encoding: .utf8) else {
            throw ResvgError.notUtf8String
        }
        return string
    }
}
