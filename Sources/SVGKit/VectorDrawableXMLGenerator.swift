// swiftlint:disable file_length
import Foundation

/// Generates Android Vector Drawable XML from parsed SVG
public struct VectorDrawableXMLGenerator: Sendable {
    private let autoMirrored: Bool

    public init(autoMirrored: Bool = false) {
        self.autoMirrored = autoMirrored
    }

    /// Generates Vector Drawable XML from a ParsedSVG
    /// - Parameter svg: The parsed SVG structure
    /// - Returns: Complete Vector Drawable XML string
    public func generate(from svg: ParsedSVG) -> String {
        var lines: [String] = []

        // XML declaration
        lines.append("<?xml version=\"1.0\" encoding=\"utf-8\"?>")

        // Check if gradients are used
        let needsAaptNamespace = hasGradients(svg)

        // Vector root element
        var vectorAttrs: [String] = []
        vectorAttrs.append("xmlns:android=\"http://schemas.android.com/apk/res/android\"")
        if needsAaptNamespace {
            vectorAttrs.append("xmlns:aapt=\"http://schemas.android.com/aapt\"")
        }
        vectorAttrs.append("android:width=\"\(formatDouble(svg.width))dp\"")
        vectorAttrs.append("android:height=\"\(formatDouble(svg.height))dp\"")
        vectorAttrs.append("android:viewportWidth=\"\(formatDouble(svg.viewportWidth))\"")
        vectorAttrs.append("android:viewportHeight=\"\(formatDouble(svg.viewportHeight))\"")

        if autoMirrored {
            vectorAttrs.append("android:autoMirrored=\"true\"")
        }

        lines.append("<vector")
        for (index, attr) in vectorAttrs.enumerated() {
            let prefix = "    "
            let suffix = index == vectorAttrs.count - 1 ? ">" : ""
            lines.append("\(prefix)\(attr)\(suffix)")
        }

        // Generate groups (if present)
        if let groups = svg.groups {
            for group in groups {
                generateGroup(group, into: &lines, indent: 1)
            }
        }

        // Generate flattened paths (for SVGs without groups or as fallback)
        if svg.groups == nil || svg.groups?.isEmpty == true {
            for path in svg.paths {
                generatePath(path, into: &lines, indent: 1)
            }
        }

        // Close vector
        lines.append("</vector>")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Methods

    private func generateGroup(_ group: SVGGroup, into lines: inout [String], indent: Int) {
        let indentStr = String(repeating: "    ", count: indent)
        let groupAttrs = transformAttributes(from: group.transform)

        appendGroupOpenTag(groupAttrs, indentStr: indentStr, into: &lines)
        appendClipPath(group.clipPath, indent: indent, into: &lines)

        for path in group.paths {
            generatePath(path, into: &lines, indent: indent + 1)
        }
        for childGroup in group.children {
            generateGroup(childGroup, into: &lines, indent: indent + 1)
        }

        lines.append("\(indentStr)</group>")
    }

    private func transformAttributes(from transform: SVGTransform?) -> [String] {
        guard let transform else { return [] }
        var attrs: [String] = []
        if let v = transform.translateX { attrs.append("android:translateX=\"\(formatDouble(v))\"") }
        if let v = transform.translateY { attrs.append("android:translateY=\"\(formatDouble(v))\"") }
        if let v = transform.scaleX { attrs.append("android:scaleX=\"\(formatDouble(v))\"") }
        if let v = transform.scaleY { attrs.append("android:scaleY=\"\(formatDouble(v))\"") }
        if let v = transform.rotation { attrs.append("android:rotation=\"\(formatDouble(v))\"") }
        if let v = transform.pivotX { attrs.append("android:pivotX=\"\(formatDouble(v))\"") }
        if let v = transform.pivotY { attrs.append("android:pivotY=\"\(formatDouble(v))\"") }
        return attrs
    }

    private func appendGroupOpenTag(_ attrs: [String], indentStr: String, into lines: inout [String]) {
        if attrs.isEmpty {
            lines.append("\(indentStr)<group>")
        } else {
            lines.append("\(indentStr)<group")
            for (index, attr) in attrs.enumerated() {
                let suffix = index == attrs.count - 1 ? ">" : ""
                lines.append("\(indentStr)    \(attr)\(suffix)")
            }
        }
    }

    private func appendClipPath(_ clipPath: String?, indent: Int, into lines: inout [String]) {
        guard let clipPath else { return }
        let indentStr = String(repeating: "    ", count: indent + 1)
        lines.append("\(indentStr)<clip-path")
        lines.append("\(indentStr)    android:pathData=\"\(clipPath)\"/>")
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func generatePath(_ path: SVGPath, into lines: inout [String], indent: Int) {
        let indentStr = String(repeating: "    ", count: indent)

        // Check if fill is a gradient
        let hasGradientFill = switch path.fillType {
        case .linearGradient, .radialGradient:
            true
        default:
            false
        }

        var pathAttrs: [String] = []

        // Path data
        pathAttrs.append("android:pathData=\"\(path.pathData)\"")

        // Fill color (only for solid fills or legacy)
        if !hasGradientFill {
            if let fill = path.fill {
                pathAttrs.append("android:fillColor=\"\(formatColor(fill))\"")
            } else if case let .solid(color) = path.fillType {
                pathAttrs.append("android:fillColor=\"\(formatColor(color))\"")
            }
        }

        // Fill alpha (opacity on path level)
        if let opacity = path.opacity {
            pathAttrs.append("android:fillAlpha=\"\(formatDouble(opacity))\"")
        }

        // Fill type
        if let fillRule = path.fillRule {
            let fillType = fillRule == .evenOdd ? "evenOdd" : "nonZero"
            pathAttrs.append("android:fillType=\"\(fillType)\"")
        }

        // Stroke color
        if let stroke = path.stroke {
            pathAttrs.append("android:strokeColor=\"\(formatColor(stroke))\"")
        }

        // Stroke width
        if let strokeWidth = path.strokeWidth {
            pathAttrs.append("android:strokeWidth=\"\(formatDouble(strokeWidth))\"")
        }

        // Stroke line cap
        if let strokeLineCap = path.strokeLineCap {
            pathAttrs.append("android:strokeLineCap=\"\(strokeLineCap.rawValue)\"")
        }

        // Stroke line join
        if let strokeLineJoin = path.strokeLineJoin {
            pathAttrs.append("android:strokeLineJoin=\"\(strokeLineJoin.rawValue)\"")
        }

        // Generate path element
        if hasGradientFill {
            // Path with nested gradient
            lines.append("\(indentStr)<path")
            for attr in pathAttrs {
                lines.append("\(indentStr)    \(attr)")
            }
            // Close path opening tag with >
            lines.append("\(indentStr)    >")

            // Generate gradient fill
            generateGradientFill(path.fillType, into: &lines, indent: indent + 1)

            lines.append("\(indentStr)</path>")
        } else {
            // Simple path
            lines.append("\(indentStr)<path")
            for (index, attr) in pathAttrs.enumerated() {
                let prefix = "\(indentStr)    "
                let suffix = index == pathAttrs.count - 1 ? "/>" : ""
                lines.append("\(prefix)\(attr)\(suffix)")
            }
        }
    }

    private func formatDouble(_ value: Double) -> String {
        // Format to remove unnecessary trailing zeros
        if value == value.rounded(), abs(value) < 10000 {
            return String(format: "%.0f", value)
        } else if abs(value - value.rounded()) < 0.0001 {
            return String(format: "%.0f", value)
        } else {
            let formatted = String(format: "%.4f", value)
            var result = formatted
            while result.hasSuffix("0"), !result.hasSuffix(".0") {
                result.removeLast()
            }
            if result.hasSuffix(".") {
                result.removeLast()
            }
            return result
        }
    }

    private func formatColor(_ color: SVGColor) -> String {
        if color.alpha < 1.0 {
            // Include alpha: #AARRGGBB
            let alphaInt = UInt8(color.alpha * 255)
            return String(format: "#%02X%02X%02X%02X", alphaInt, color.red, color.green, color.blue)
        } else {
            // No alpha: #RRGGBB
            return String(format: "#%02X%02X%02X", color.red, color.green, color.blue)
        }
    }

    // MARK: - Gradient Support

    private func hasGradients(_ svg: ParsedSVG) -> Bool {
        let pathHasGradient = svg.paths.contains { path in
            if case .linearGradient = path.fillType { return true }
            if case .radialGradient = path.fillType { return true }
            return false
        }
        if pathHasGradient { return true }

        return svg.groups?.contains { hasGradientsInGroup($0) } ?? false
    }

    private func hasGradientsInGroup(_ group: SVGGroup) -> Bool {
        let pathHasGradient = group.paths.contains { path in
            if case .linearGradient = path.fillType { return true }
            if case .radialGradient = path.fillType { return true }
            return false
        }
        if pathHasGradient { return true }

        return group.children.contains { hasGradientsInGroup($0) }
    }

    private func generateGradientFill(_ fill: SVGFill, into lines: inout [String], indent: Int) {
        let indentStr = String(repeating: "    ", count: indent)

        switch fill {
        case let .linearGradient(gradient):
            generateLinearGradient(gradient, into: &lines, indentStr: indentStr)
        case let .radialGradient(gradient):
            generateRadialGradient(gradient, into: &lines, indentStr: indentStr)
        default:
            break
        }
    }

    private func generateLinearGradient(_ gradient: SVGLinearGradient, into lines: inout [String], indentStr: String) {
        lines.append("\(indentStr)<aapt:attr name=\"android:fillColor\">")
        lines.append("\(indentStr)    <gradient")
        lines.append("\(indentStr)        android:type=\"linear\"")
        lines.append("\(indentStr)        android:startX=\"\(formatDouble(gradient.x1))\"")
        lines.append("\(indentStr)        android:startY=\"\(formatDouble(gradient.y1))\"")
        lines.append("\(indentStr)        android:endX=\"\(formatDouble(gradient.x2))\"")
        lines.append("\(indentStr)        android:endY=\"\(formatDouble(gradient.y2))\">")

        for stop in gradient.stops {
            let argb = colorToARGB(stop.color, opacity: stop.opacity)
            lines.append(
                "\(indentStr)        <item android:offset=\"\(formatDouble(stop.offset))\" android:color=\"\(argb)\"/>"
            )
        }

        lines.append("\(indentStr)    </gradient>")
        lines.append("\(indentStr)</aapt:attr>")
    }

    private func generateRadialGradient(_ gradient: SVGRadialGradient, into lines: inout [String], indentStr: String) {
        lines.append("\(indentStr)<aapt:attr name=\"android:fillColor\">")
        lines.append("\(indentStr)    <gradient")
        lines.append("\(indentStr)        android:type=\"radial\"")
        lines.append("\(indentStr)        android:centerX=\"\(formatDouble(gradient.cx))\"")
        lines.append("\(indentStr)        android:centerY=\"\(formatDouble(gradient.cy))\"")
        lines.append("\(indentStr)        android:gradientRadius=\"\(formatDouble(gradient.r))\">")

        for stop in gradient.stops {
            let argb = colorToARGB(stop.color, opacity: stop.opacity)
            lines.append(
                "\(indentStr)        <item android:offset=\"\(formatDouble(stop.offset))\" android:color=\"\(argb)\"/>"
            )
        }

        lines.append("\(indentStr)    </gradient>")
        lines.append("\(indentStr)</aapt:attr>")
    }

    private func colorToARGB(_ color: SVGColor, opacity: Double) -> String {
        let alpha = Int((opacity * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", alpha, color.red, color.green, color.blue)
    }
}
