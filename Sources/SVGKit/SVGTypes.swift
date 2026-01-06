import Foundation

/// Represents a transform applied to an SVG group or element
public struct SVGTransform: Equatable, Sendable {
    public let translateX: Double?
    public let translateY: Double?
    public let scaleX: Double?
    public let scaleY: Double?
    public let rotation: Double?
    public let pivotX: Double?
    public let pivotY: Double?
    public let skewX: Double?
    public let skewY: Double?

    public init(
        translateX: Double? = nil,
        translateY: Double? = nil,
        scaleX: Double? = nil,
        scaleY: Double? = nil,
        rotation: Double? = nil,
        pivotX: Double? = nil,
        pivotY: Double? = nil,
        skewX: Double? = nil,
        skewY: Double? = nil
    ) {
        self.translateX = translateX
        self.translateY = translateY
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.rotation = rotation
        self.pivotX = pivotX
        self.pivotY = pivotY
        self.skewX = skewX
        self.skewY = skewY
    }

    private static let transformRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: #"(translate|scale|rotate|matrix|skewX|skewY)\s*\(([^)]+)\)"#, options: [])
    }()

    /// Parses an SVG transform attribute string
    /// Supports: translate, scale, rotate
    public static func parse(_ string: String) -> SVGTransform? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let matches = transformRegex.matches(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed))
        guard !matches.isEmpty else { return nil }

        var result = ParsedTransformValues()
        for match in matches {
            result.apply(match: match, in: trimmed)
        }

        guard result.hasValidTransform else { return nil }

        return result.toTransform()
    }

    static func parseValues(_ args: String) -> [Double] {
        args
            .split { $0.isWhitespace || $0 == "," }
            .compactMap { Double($0) }
    }
}

// MARK: - ParsedTransformValues Helper

private struct ParsedTransformValues {
    var translateX: Double?
    var translateY: Double?
    var scaleX: Double?
    var scaleY: Double?
    var rotation: Double?
    var pivotX: Double?
    var pivotY: Double?
    var skewX: Double?
    var skewY: Double?

    var hasValidTransform: Bool {
        translateX != nil || translateY != nil || scaleX != nil || scaleY != nil ||
            rotation != nil || skewX != nil || skewY != nil
    }

    mutating func apply(match: NSTextCheckingResult, in string: String) {
        guard let typeRange = Range(match.range(at: 1), in: string),
              let argsRange = Range(match.range(at: 2), in: string)
        else {
            return
        }

        let type = String(string[typeRange])
        let values = SVGTransform.parseValues(String(string[argsRange]))

        switch type {
        case "translate":
            applyTranslate(values)
        case "scale":
            applyScale(values)
        case "rotate":
            applyRotate(values)
        case "matrix":
            applyMatrix(values)
        case "skewX":
            applySkewX(values)
        case "skewY":
            applySkewY(values)
        default:
            break
        }
    }

    private mutating func applyTranslate(_ values: [Double]) {
        guard !values.isEmpty else { return }
        translateX = values[0]
        translateY = values.count > 1 ? values[1] : 0
    }

    private mutating func applyScale(_ values: [Double]) {
        guard !values.isEmpty else { return }
        scaleX = values[0]
        scaleY = values.count > 1 ? values[1] : values[0]
    }

    private mutating func applyRotate(_ values: [Double]) {
        guard !values.isEmpty else { return }
        rotation = values[0]
        if values.count >= 3 {
            pivotX = values[1]
            pivotY = values[2]
        }
    }

    private mutating func applyMatrix(_ values: [Double]) {
        // matrix(a, b, c, d, e, f) where:
        // a = scaleX * cos(rotation), b = scaleX * sin(rotation)
        // c = -scaleY * sin(rotation), d = scaleY * cos(rotation)
        // e = translateX, f = translateY
        guard values.count == 6 else { return }
        let (a, b, c, d, e, f) = (values[0], values[1], values[2], values[3], values[4], values[5])

        // Translation is straightforward
        translateX = e
        translateY = f

        // Extract scale from matrix
        scaleX = sqrt(a * a + b * b)
        scaleY = sqrt(c * c + d * d)

        // Determine sign of scaleY based on determinant
        let det = a * d - b * c
        if det < 0 {
            scaleY = -(scaleY ?? 1)
        }

        // Extract rotation (in degrees)
        rotation = atan2(b, a) * 180 / .pi
    }

    private mutating func applySkewX(_ values: [Double]) {
        guard let angle = values.first else { return }
        skewX = angle
    }

    private mutating func applySkewY(_ values: [Double]) {
        guard let angle = values.first else { return }
        skewY = angle
    }

    func toTransform() -> SVGTransform {
        SVGTransform(
            translateX: translateX,
            translateY: translateY,
            scaleX: scaleX,
            scaleY: scaleY,
            rotation: rotation,
            pivotX: pivotX,
            pivotY: pivotY,
            skewX: skewX,
            skewY: skewY
        )
    }
}

// MARK: - Gradient Types

/// Gradient color stop
public struct SVGGradientStop: Sendable, Equatable {
    public let offset: Double
    public let color: SVGColor
    public let opacity: Double

    public init(offset: Double, color: SVGColor, opacity: Double = 1.0) {
        self.offset = offset
        self.color = color
        self.opacity = opacity
    }
}

/// Linear gradient definition
public struct SVGLinearGradient: Sendable, Equatable {
    public let id: String
    public let x1, y1, x2, y2: Double
    public let stops: [SVGGradientStop]
    public let spreadMethod: SpreadMethod
    public let gradientTransform: SVGTransform?

    public enum SpreadMethod: String, Sendable {
        case pad
        case reflect
        case repeating = "repeat"
    }

    public init(
        id: String,
        x1: Double, y1: Double,
        x2: Double, y2: Double,
        stops: [SVGGradientStop],
        spreadMethod: SpreadMethod = .pad,
        gradientTransform: SVGTransform? = nil
    ) {
        self.id = id
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.stops = stops
        self.spreadMethod = spreadMethod
        self.gradientTransform = gradientTransform
    }
}

/// Radial gradient definition
public struct SVGRadialGradient: Sendable, Equatable {
    public let id: String
    public let cx, cy, r: Double
    public let fx, fy: Double?
    public let stops: [SVGGradientStop]
    public let spreadMethod: SVGLinearGradient.SpreadMethod
    public let gradientTransform: SVGTransform?

    public init(
        id: String,
        cx: Double, cy: Double,
        r: Double,
        fx: Double? = nil, fy: Double? = nil,
        stops: [SVGGradientStop],
        spreadMethod: SVGLinearGradient.SpreadMethod = .pad,
        gradientTransform: SVGTransform? = nil
    ) {
        self.id = id
        self.cx = cx
        self.cy = cy
        self.r = r
        self.fx = fx
        self.fy = fy
        self.stops = stops
        self.spreadMethod = spreadMethod
        self.gradientTransform = gradientTransform
    }
}

/// Fill type - solid color, gradient, or none
public enum SVGFill: Sendable, Equatable {
    case none
    case solid(SVGColor)
    case linearGradient(SVGLinearGradient)
    case radialGradient(SVGRadialGradient)
}

// MARK: - Group Types

/// Represents a group element in SVG with optional transform, clip-path, and nested children
public struct SVGGroup: Equatable, Sendable {
    public let transform: SVGTransform?
    public let clipPath: String?
    public let paths: [SVGPath]
    public let children: [SVGGroup]
    public let opacity: Double?
    /// Ordered elements within the group (preserves SVG document order)
    public let elements: [SVGElement]

    public init(
        transform: SVGTransform? = nil,
        clipPath: String? = nil,
        paths: [SVGPath] = [],
        children: [SVGGroup] = [],
        opacity: Double? = nil,
        elements: [SVGElement] = []
    ) {
        self.transform = transform
        self.clipPath = clipPath
        self.paths = paths
        self.children = children
        self.opacity = opacity
        self.elements = elements
    }
}

// MARK: - Element Order

/// Represents an element in SVG document order (path or group)
public enum SVGElement: Equatable, Sendable {
    case path(SVGPath)
    case group(SVGGroup)
}
