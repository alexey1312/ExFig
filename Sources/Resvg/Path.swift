import CResvg
import Foundation

// MARK: - Path

/// A path element in the SVG tree.
///
/// Paths contain bezier curves with optional fill and stroke styling.
public struct Path: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The element ID (from `id` attribute), or empty string if none.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_path_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The relative transform of this path.
    public var transform: Transform {
        Transform(resvg_path_transform(ptr))
    }

    /// The absolute transform including all ancestor transforms.
    public var absoluteTransform: Transform {
        Transform(resvg_path_abs_transform(ptr))
    }

    /// Whether this path is visible.
    public var isVisible: Bool {
        resvg_path_is_visible(ptr)
    }

    /// The number of path segments.
    public var segmentCount: Int {
        Int(resvg_path_data_len(ptr))
    }

    /// Get all path segments.
    public var segments: [PathSegment] {
        let count = segmentCount
        var result: [PathSegment] = []
        result.reserveCapacity(count)
        for i in 0 ..< count {
            var seg = resvg_path_segment()
            if resvg_path_data_segment(ptr, UInt(i), &seg) {
                result.append(PathSegment(seg))
            }
        }
        return result
    }

    /// Get a segment at a specific index.
    public func segment(at index: Int) -> PathSegment? {
        guard index >= 0, index < segmentCount else { return nil }
        var seg = resvg_path_segment()
        guard resvg_path_data_segment(ptr, UInt(index), &seg) else {
            return nil
        }
        return PathSegment(seg)
    }

    /// Whether this path has a fill.
    public var hasFill: Bool {
        resvg_path_has_fill(ptr)
    }

    /// Whether this path has a stroke.
    public var hasStroke: Bool {
        resvg_path_has_stroke(ptr)
    }

    /// The fill of this path, if any.
    public var fill: Fill? {
        guard let fillPtr = resvg_path_fill(ptr) else {
            return nil
        }
        return Fill(fillPtr, tree: tree)
    }

    /// The stroke of this path, if any.
    public var stroke: Stroke? {
        guard let strokePtr = resvg_path_stroke(ptr) else {
            return nil
        }
        return Stroke(strokePtr, tree: tree)
    }
}

// MARK: - PathSegment

/// A segment in a path.
public struct PathSegment: Sendable, Equatable {
    /// The type of segment.
    public let type: SegmentType

    /// The end point X coordinate.
    public let x: Float

    /// The end point Y coordinate.
    public let y: Float

    /// First control point X (for quad/cubic curves).
    public let x1: Float

    /// First control point Y (for quad/cubic curves).
    public let y1: Float

    /// Second control point X (for cubic curves).
    public let x2: Float

    /// Second control point Y (for cubic curves).
    public let y2: Float

    init(_ seg: resvg_path_segment) {
        type = SegmentType(rawValue: seg.seg_type.rawValue) ?? .moveTo
        x = seg.x
        y = seg.y
        x1 = seg.x1
        y1 = seg.y1
        x2 = seg.x2
        y2 = seg.y2
    }
}

/// Path segment types.
public enum SegmentType: UInt32, Sendable {
    case moveTo = 0
    case lineTo = 1
    case quadTo = 2
    case cubicTo = 3
    case close = 4
}

// MARK: - Fill

/// Fill properties of a path.
public struct Fill: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The type of paint used for this fill.
    public var paintType: PaintType {
        PaintType(rawValue: resvg_fill_paint_type(ptr).rawValue) ?? .color
    }

    /// The solid color if paintType is .color.
    public var color: Color {
        Color(resvg_fill_color(ptr))
    }

    /// The fill opacity (0.0 to 1.0).
    public var opacity: Float {
        resvg_fill_opacity(ptr)
    }

    /// The fill rule.
    public var rule: FillRule {
        FillRule(rawValue: resvg_fill_get_rule(ptr).rawValue) ?? .nonZero
    }

    /// The linear gradient if paintType is .linearGradient.
    public var linearGradient: LinearGradient? {
        guard let lgPtr = resvg_fill_linear_gradient(ptr) else {
            return nil
        }
        return LinearGradient(lgPtr, tree: tree)
    }

    /// The radial gradient if paintType is .radialGradient.
    public var radialGradient: RadialGradient? {
        guard let rgPtr = resvg_fill_radial_gradient(ptr) else {
            return nil
        }
        return RadialGradient(rgPtr, tree: tree)
    }
}

/// Fill rule.
public enum FillRule: UInt32, Sendable {
    case nonZero = 0
    case evenOdd = 1
}

// MARK: - Stroke

/// Stroke properties of a path.
public struct Stroke: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The type of paint used for this stroke.
    public var paintType: PaintType {
        PaintType(rawValue: resvg_stroke_paint_type(ptr).rawValue) ?? .color
    }

    /// The solid color if paintType is .color.
    public var color: Color {
        Color(resvg_stroke_color(ptr))
    }

    /// The stroke opacity (0.0 to 1.0).
    public var opacity: Float {
        resvg_stroke_opacity(ptr)
    }

    /// The stroke width.
    public var width: Float {
        resvg_stroke_width(ptr)
    }

    /// The line cap style.
    public var lineCap: LineCap {
        LineCap(rawValue: resvg_stroke_linecap(ptr).rawValue) ?? .butt
    }

    /// The line join style.
    public var lineJoin: LineJoin {
        LineJoin(rawValue: resvg_stroke_linejoin(ptr).rawValue) ?? .miter
    }

    /// The miter limit.
    public var miterLimit: Float {
        resvg_stroke_miter_limit(ptr)
    }

    /// The dash array.
    public var dashArray: [Float] {
        let count = Int(resvg_stroke_dasharray_len(ptr))
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 0 ..< count {
            result.append(resvg_stroke_dasharray_at(ptr, UInt(i)))
        }
        return result
    }

    /// The dash offset.
    public var dashOffset: Float {
        resvg_stroke_dashoffset(ptr)
    }

    /// The linear gradient if paintType is .linearGradient.
    public var linearGradient: LinearGradient? {
        guard let lgPtr = resvg_stroke_linear_gradient(ptr) else {
            return nil
        }
        return LinearGradient(lgPtr, tree: tree)
    }

    /// The radial gradient if paintType is .radialGradient.
    public var radialGradient: RadialGradient? {
        guard let rgPtr = resvg_stroke_radial_gradient(ptr) else {
            return nil
        }
        return RadialGradient(rgPtr, tree: tree)
    }
}

/// Line cap styles.
public enum LineCap: UInt32, Sendable {
    case butt = 0
    case round = 1
    case square = 2
}

/// Line join styles.
public enum LineJoin: UInt32, Sendable {
    case miter = 0
    case round = 1
    case bevel = 2
}

// MARK: - PaintType

/// The type of paint used for fill or stroke.
public enum PaintType: UInt32, Sendable {
    case color = 0
    case linearGradient = 1
    case radialGradient = 2
    case pattern = 3
}
