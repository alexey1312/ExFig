import CResvg
import Foundation

// MARK: - LinearGradient

/// A linear gradient paint.
public struct LinearGradient: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The gradient ID.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_linear_gradient_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// Start X coordinate.
    public var x1: Float {
        resvg_linear_gradient_x1(ptr)
    }

    /// Start Y coordinate.
    public var y1: Float {
        resvg_linear_gradient_y1(ptr)
    }

    /// End X coordinate.
    public var x2: Float {
        resvg_linear_gradient_x2(ptr)
    }

    /// End Y coordinate.
    public var y2: Float {
        resvg_linear_gradient_y2(ptr)
    }

    /// The gradient transform.
    public var transform: Transform {
        Transform(resvg_linear_gradient_transform(ptr))
    }

    /// The spread method.
    public var spreadMethod: SpreadMethod {
        SpreadMethod(rawValue: resvg_linear_gradient_spread_method(ptr).rawValue) ?? .pad
    }

    /// The number of gradient stops.
    public var stopCount: Int {
        Int(resvg_linear_gradient_stops_count(ptr))
    }

    /// All gradient stops.
    public var stops: [GradientStop] {
        let count = stopCount
        var result: [GradientStop] = []
        result.reserveCapacity(count)
        for i in 0 ..< count {
            var stop = resvg_gradient_stop()
            if resvg_linear_gradient_stop_at(ptr, UInt(i), &stop) {
                result.append(GradientStop(stop))
            }
        }
        return result
    }

    /// Get a stop at a specific index.
    public func stop(at index: Int) -> GradientStop? {
        guard index >= 0, index < stopCount else { return nil }
        var stop = resvg_gradient_stop()
        guard resvg_linear_gradient_stop_at(ptr, UInt(index), &stop) else {
            return nil
        }
        return GradientStop(stop)
    }
}

// MARK: - RadialGradient

/// A radial gradient paint.
public struct RadialGradient: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The gradient ID.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_radial_gradient_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// Center X coordinate.
    public var cx: Float {
        resvg_radial_gradient_cx(ptr)
    }

    /// Center Y coordinate.
    public var cy: Float {
        resvg_radial_gradient_cy(ptr)
    }

    /// Radius.
    public var r: Float {
        resvg_radial_gradient_r(ptr)
    }

    /// Focal point X coordinate.
    public var fx: Float {
        resvg_radial_gradient_fx(ptr)
    }

    /// Focal point Y coordinate.
    public var fy: Float {
        resvg_radial_gradient_fy(ptr)
    }

    /// The gradient transform.
    public var transform: Transform {
        Transform(resvg_radial_gradient_transform(ptr))
    }

    /// The spread method.
    public var spreadMethod: SpreadMethod {
        SpreadMethod(rawValue: resvg_radial_gradient_spread_method(ptr).rawValue) ?? .pad
    }

    /// The number of gradient stops.
    public var stopCount: Int {
        Int(resvg_radial_gradient_stops_count(ptr))
    }

    /// All gradient stops.
    public var stops: [GradientStop] {
        let count = stopCount
        var result: [GradientStop] = []
        result.reserveCapacity(count)
        for i in 0 ..< count {
            var stop = resvg_gradient_stop()
            if resvg_radial_gradient_stop_at(ptr, UInt(i), &stop) {
                result.append(GradientStop(stop))
            }
        }
        return result
    }

    /// Get a stop at a specific index.
    public func stop(at index: Int) -> GradientStop? {
        guard index >= 0, index < stopCount else { return nil }
        var stop = resvg_gradient_stop()
        guard resvg_radial_gradient_stop_at(ptr, UInt(index), &stop) else {
            return nil
        }
        return GradientStop(stop)
    }
}

// MARK: - GradientStop

/// A color stop in a gradient.
public struct GradientStop: Sendable, Equatable {
    /// The offset position (0.0 to 1.0).
    public let offset: Float

    /// The color at this stop.
    public let color: Color

    init(_ stop: resvg_gradient_stop) {
        offset = stop.offset
        color = Color(r: stop.r, g: stop.g, b: stop.b, a: stop.a)
    }

    public init(offset: Float, color: Color) {
        self.offset = offset
        self.color = color
    }
}

// MARK: - SpreadMethod

/// Gradient spread method.
public enum SpreadMethod: UInt32, Sendable {
    case pad = 0
    case reflect = 1
    case `repeat` = 2
}
