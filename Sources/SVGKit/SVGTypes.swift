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

    public init(
        translateX: Double? = nil,
        translateY: Double? = nil,
        scaleX: Double? = nil,
        scaleY: Double? = nil,
        rotation: Double? = nil,
        pivotX: Double? = nil,
        pivotY: Double? = nil
    ) {
        self.translateX = translateX
        self.translateY = translateY
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.rotation = rotation
        self.pivotX = pivotX
        self.pivotY = pivotY
    }

    /// Parses an SVG transform attribute string
    /// Supports: translate, scale, rotate
    public static func parse(_ string: String) -> SVGTransform? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let transformPattern = #"(translate|scale|rotate|matrix|skewX|skewY)\s*\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: transformPattern, options: []) else {
            return nil
        }

        let matches = regex.matches(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed))
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

    var hasValidTransform: Bool {
        translateX != nil || translateY != nil || scaleX != nil || scaleY != nil || rotation != nil
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

    func toTransform() -> SVGTransform {
        SVGTransform(
            translateX: translateX,
            translateY: translateY,
            scaleX: scaleX,
            scaleY: scaleY,
            rotation: rotation,
            pivotX: pivotX,
            pivotY: pivotY
        )
    }
}

/// Represents a group element in SVG with optional transform, clip-path, and nested children
public struct SVGGroup: Equatable, Sendable {
    public let transform: SVGTransform?
    public let clipPath: String?
    public let paths: [SVGPath]
    public let children: [SVGGroup]
    public let opacity: Double?

    public init(
        transform: SVGTransform? = nil,
        clipPath: String? = nil,
        paths: [SVGPath] = [],
        children: [SVGGroup] = [],
        opacity: Double? = nil
    ) {
        self.transform = transform
        self.clipPath = clipPath
        self.paths = paths
        self.children = children
        self.opacity = opacity
    }
}
