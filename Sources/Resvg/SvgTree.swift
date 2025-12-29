import CResvg
import Foundation

/// A parsed SVG tree that provides access to all elements.
///
/// This class owns the underlying resvg tree and manages its lifetime.
/// All node references (Group, Path, etc.) are only valid while this tree is alive.
///
/// Example usage:
/// ```swift
/// let tree = try SvgTree(data: svgData)
/// let root = tree.root
/// for child in root.children {
///     switch child.nodeType {
///     case .group:
///         // Handle group
///     case .path:
///         // Handle path
///     case .image:
///         // Handle image
///     case .text:
///         // Handle text
///     }
/// }
/// ```
public final class SvgTree: @unchecked Sendable {
    let ptr: OpaquePointer

    /// Parses SVG data into a tree.
    ///
    /// - Parameter data: Raw SVG data (UTF-8 or gzip compressed)
    /// - Throws: `ResvgError` on parsing failure
    public init(data: Data) throws {
        guard let opt = resvg_options_create() else {
            throw ResvgError.unknownError(code: -1)
        }
        defer { resvg_options_destroy(opt) }

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

        if let error = ResvgError.fromCode(result) {
            throw error
        }

        guard let tree else {
            throw ResvgError.parsingFailed
        }

        ptr = tree
    }

    /// Parses SVG from a file.
    ///
    /// - Parameter url: Path to SVG file
    /// - Throws: `ResvgError` on parsing failure
    public convenience init(file url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    deinit {
        resvg_tree_destroy(ptr)
    }

    /// The root group of the SVG tree.
    public var root: Group {
        let rootPtr = resvg_tree_root(ptr)!
        return Group(rootPtr, tree: self)
    }

    /// The size of the SVG image.
    public var size: (width: Double, height: Double) {
        let s = resvg_get_image_size(ptr)
        return (Double(s.width), Double(s.height))
    }

    /// Whether the SVG is empty (no renderable content).
    public var isEmpty: Bool {
        resvg_is_image_empty(ptr)
    }

    /// Exports the tree back to normalized SVG string.
    public func toSvgString() throws -> String {
        var len: UInt = 0
        guard let svgPtr = resvg_tree_to_svg(ptr, &len) else {
            throw ResvgError.svgExportFailed
        }
        defer { resvg_svg_string_destroy(svgPtr) }
        return String(cString: svgPtr)
    }
}

// MARK: - Node Type

/// The type of a node in the SVG tree.
public enum NodeType: UInt32, Sendable {
    case group = 0
    case path = 1
    case image = 2
    case text = 3
}

// MARK: - Transform

/// An affine transform matrix.
public struct Transform: Sendable, Equatable {
    public let a: Float
    public let b: Float
    public let c: Float
    public let d: Float
    public let e: Float
    public let f: Float

    /// Identity transform.
    public static let identity = Transform(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)

    public init(a: Float, b: Float, c: Float, d: Float, e: Float, f: Float) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
        self.f = f
    }

    init(_ t: resvg_transform) {
        a = t.a
        b = t.b
        c = t.c
        d = t.d
        e = t.e
        f = t.f
    }

    /// Whether this is an identity transform.
    public var isIdentity: Bool {
        a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0
    }
}

// MARK: - Color

/// An RGBA color.
public struct Color: Sendable, Equatable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
    public let a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(_ c: resvg_color) {
        r = c.r
        g = c.g
        b = c.b
        a = c.a
    }
}

// MARK: - Rect

/// A rectangle with position and size.
public struct Rect: Sendable, Equatable {
    public let x: Float
    public let y: Float
    public let width: Float
    public let height: Float

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(_ r: resvg_rect) {
        x = r.x
        y = r.y
        width = r.width
        height = r.height
    }
}

// MARK: - Size

/// A size with width and height.
public struct Size: Sendable, Equatable {
    public let width: Float
    public let height: Float

    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    init(_ s: resvg_size) {
        width = s.width
        height = s.height
    }
}
