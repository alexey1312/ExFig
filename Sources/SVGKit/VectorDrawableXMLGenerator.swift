// swiftlint:disable file_length type_body_length
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

        generateElements(svg, into: &lines)

        // Close vector
        lines.append("</vector>")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Methods

    private func generateElements(_ svg: ParsedSVG, into lines: inout [String]) {
        if !svg.elements.isEmpty {
            for element in svg.elements {
                switch element {
                case let .path(path):
                    generatePath(path, into: &lines, indent: 1)
                case let .group(group):
                    generateGroup(group, into: &lines, indent: 1)
                }
            }
        } else if let groups = svg.groups, !groups.isEmpty {
            generateLegacyElements(svg, groups: groups, into: &lines)
        } else {
            for path in svg.paths {
                generatePath(path, into: &lines, indent: 1)
            }
        }
    }

    private func generateLegacyElements(_ svg: ParsedSVG, groups: [SVGGroup], into lines: inout [String]) {
        let groupPathDatas = collectPathDatasFromGroups(groups)
        for path in svg.paths where !groupPathDatas.contains(path.pathData) {
            generatePath(path, into: &lines, indent: 1)
        }
        for group in groups {
            generateGroup(group, into: &lines, indent: 1)
        }
    }

    private func generateGroup(_ group: SVGGroup, into lines: inout [String], indent: Int) {
        let indentStr = String(repeating: "    ", count: indent)
        let groupAttrs = transformAttributes(from: group.transform)

        appendGroupOpenTag(groupAttrs, indentStr: indentStr, into: &lines)
        appendClipPath(group.clipPath, indent: indent, into: &lines)

        // Generate elements in document order (preserves correct layer order)
        if !group.elements.isEmpty {
            for element in group.elements {
                switch element {
                case let .path(path):
                    generatePath(path, into: &lines, indent: indent + 1)
                case let .group(childGroup):
                    generateGroup(childGroup, into: &lines, indent: indent + 1)
                }
            }
        } else {
            // Fallback for backward compatibility when elements array is empty
            for path in group.paths {
                generatePath(path, into: &lines, indent: indent + 1)
            }
            for childGroup in group.children {
                generateGroup(childGroup, into: &lines, indent: indent + 1)
            }
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
            } else if path.stroke == nil {
                // SVG spec: missing fill attribute defaults to black
                pathAttrs.append("android:fillColor=\"#FF000000\"")
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

    /// Recursively collects all path data strings from groups to identify which paths are inside groups
    private func collectPathDatasFromGroups(_ groups: [SVGGroup]) -> Set<String> {
        var pathDatas = Set<String>()
        for group in groups {
            collectPathDatasFromGroup(group, into: &pathDatas)
        }
        return pathDatas
    }

    private func collectPathDatasFromGroup(_ group: SVGGroup, into pathDatas: inout Set<String>) {
        for path in group.paths {
            pathDatas.insert(path.pathData)
        }
        for child in group.children {
            collectPathDatasFromGroup(child, into: &pathDatas)
        }
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
        // Apply gradientTransform if present
        var x1 = gradient.x1
        var y1 = gradient.y1
        var x2 = gradient.x2
        var y2 = gradient.y2

        if let transform = gradient.gradientTransform {
            (x1, y1) = applyTransformToPoint(x: x1, y: y1, transform: transform)
            (x2, y2) = applyTransformToPoint(x: x2, y: y2, transform: transform)
        }

        lines.append("\(indentStr)<aapt:attr name=\"android:fillColor\">")
        lines.append("\(indentStr)    <gradient")
        lines.append("\(indentStr)        android:type=\"linear\"")
        lines.append("\(indentStr)        android:startX=\"\(formatDouble(x1))\"")
        lines.append("\(indentStr)        android:startY=\"\(formatDouble(y1))\"")
        lines.append("\(indentStr)        android:endX=\"\(formatDouble(x2))\"")
        lines.append("\(indentStr)        android:endY=\"\(formatDouble(y2))\">")

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
        // Apply gradientTransform if present
        var cx = gradient.cx
        var cy = gradient.cy
        var r = gradient.r

        if let transform = gradient.gradientTransform {
            (cx, cy) = applyTransformToPoint(x: cx, y: cy, transform: transform)
            // Scale radius by average of scaleX and scaleY (approximation for non-uniform scaling)
            let scaleX = transform.scaleX ?? 1.0
            let scaleY = transform.scaleY ?? 1.0
            r *= (abs(scaleX) + abs(scaleY)) / 2.0
        }

        lines.append("\(indentStr)<aapt:attr name=\"android:fillColor\">")
        lines.append("\(indentStr)    <gradient")
        lines.append("\(indentStr)        android:type=\"radial\"")
        lines.append("\(indentStr)        android:centerX=\"\(formatDouble(cx))\"")
        lines.append("\(indentStr)        android:centerY=\"\(formatDouble(cy))\"")
        lines.append("\(indentStr)        android:gradientRadius=\"\(formatDouble(r))\">")

        for stop in gradient.stops {
            let argb = colorToARGB(stop.color, opacity: stop.opacity)
            lines.append(
                "\(indentStr)        <item android:offset=\"\(formatDouble(stop.offset))\" android:color=\"\(argb)\"/>"
            )
        }

        lines.append("\(indentStr)    </gradient>")
        lines.append("\(indentStr)</aapt:attr>")
    }

    /// Applies an SVG transform to a point
    private func applyTransformToPoint(x: Double, y: Double, transform: SVGTransform) -> (Double, Double) {
        var newX = x
        var newY = y

        // Apply scale
        if let scaleX = transform.scaleX {
            newX *= scaleX
        }
        if let scaleY = transform.scaleY {
            newY *= scaleY
        }

        // Apply rotation (around origin or pivot point)
        if let rotation = transform.rotation {
            let radians = rotation * .pi / 180.0
            let cosR = cos(radians)
            let sinR = sin(radians)
            let pivotX = transform.pivotX ?? 0
            let pivotY = transform.pivotY ?? 0

            let dx = newX - pivotX
            let dy = newY - pivotY
            newX = pivotX + dx * cosR - dy * sinR
            newY = pivotY + dx * sinR + dy * cosR
        }

        // Apply translation
        if let translateX = transform.translateX {
            newX += translateX
        }
        if let translateY = transform.translateY {
            newY += translateY
        }

        return (newX, newY)
    }

    private func colorToARGB(_ color: SVGColor, opacity: Double) -> String {
        let alpha = Int((opacity * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", alpha, color.red, color.green, color.blue)
    }
}
