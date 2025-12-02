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

        // Vector root element
        var vectorAttrs: [String] = []
        vectorAttrs.append("xmlns:android=\"http://schemas.android.com/apk/res/android\"")
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

    private func generatePath(_ path: SVGPath, into lines: inout [String], indent: Int) {
        let indentStr = String(repeating: "    ", count: indent)

        var pathAttrs: [String] = []

        // Path data
        pathAttrs.append("android:pathData=\"\(path.pathData)\"")

        // Fill color
        if let fill = path.fill {
            pathAttrs.append("android:fillColor=\"\(formatColor(fill))\"")
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
        lines.append("\(indentStr)<path")
        for (index, attr) in pathAttrs.enumerated() {
            let prefix = "\(indentStr)    "
            let suffix = index == pathAttrs.count - 1 ? "/>" : ""
            lines.append("\(prefix)\(attr)\(suffix)")
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
}
