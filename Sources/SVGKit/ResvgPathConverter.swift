import Foundation
import Resvg

/// Converts resvg Path segments to SVG path data string format.
///
/// This utility enables extracting path data from the resvg Tree Traversal API
/// for use in clip-path and mask conversion to VectorDrawable format.
public enum ResvgPathConverter {
    /// Converts an array of resvg PathSegments to SVG path data string.
    ///
    /// - Parameter segments: Array of PathSegment from resvg Path
    /// - Returns: SVG path data string (d attribute format)
    ///
    /// Example:
    /// ```swift
    /// let tree = try SvgTree(data: svgData)
    /// if let mask = tree.root.mask {
    ///     for child in mask.root.children {
    ///         if let path = child.asPath() {
    ///             let pathData = ResvgPathConverter.toPathString(path.segments)
    ///             // Use pathData for VectorDrawable clip-path
    ///         }
    ///     }
    /// }
    /// ```
    public static func toPathString(_ segments: [PathSegment]) -> String {
        var parts: [String] = []
        parts.reserveCapacity(segments.count)

        for segment in segments {
            switch segment.type {
            case .moveTo:
                parts.append("M\(formatFloat(segment.x)),\(formatFloat(segment.y))")
            case .lineTo:
                parts.append("L\(formatFloat(segment.x)),\(formatFloat(segment.y))")
            case .quadTo:
                parts.append(
                    "Q\(formatFloat(segment.x1)),\(formatFloat(segment.y1)) " +
                    "\(formatFloat(segment.x)),\(formatFloat(segment.y))"
                )
            case .cubicTo:
                parts.append(
                    "C\(formatFloat(segment.x1)),\(formatFloat(segment.y1)) " +
                    "\(formatFloat(segment.x2)),\(formatFloat(segment.y2)) " +
                    "\(formatFloat(segment.x)),\(formatFloat(segment.y))"
                )
            case .close:
                parts.append("Z")
            }
        }
        return parts.joined()
    }

    /// Converts a resvg Path to SVG path data string.
    ///
    /// - Parameter path: resvg Path from Tree Traversal API
    /// - Returns: SVG path data string (d attribute format)
    public static func toPathString(_ path: Resvg.Path) -> String {
        toPathString(path.segments)
    }

    /// Extracts the first path data from a mask's content.
    ///
    /// Figma uses masks instead of clip-paths for rounded corners on flags.
    /// This helper extracts the path data from the first path in the mask,
    /// which can then be used as a clip-path in VectorDrawable.
    ///
    /// - Parameter mask: Mask from Group.mask
    /// - Returns: SVG path data string, or nil if mask has no path children
    public static func extractPathFromMask(_ mask: Mask) -> String? {
        extractPathFromGroup(mask.root)
    }

    /// Extracts the first path data from a clip-path's content.
    ///
    /// - Parameter clipPath: ClipPath from Group.clipPath
    /// - Returns: SVG path data string, or nil if clip-path has no path children
    public static func extractPathFromClipPath(_ clipPath: ClipPath) -> String? {
        extractPathFromGroup(clipPath.root)
    }

    /// Extracts the first path data from a group's children.
    ///
    /// - Parameter group: Group to search for paths
    /// - Returns: SVG path data string from first path found, or nil if none
    public static func extractPathFromGroup(_ group: Group) -> String? {
        for child in group.children {
            if let path = child.asPath() {
                return toPathString(path)
            }
            if let childGroup = child.asGroup() {
                if let pathData = extractPathFromGroup(childGroup) {
                    return pathData
                }
            }
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Formats a Float to string, removing unnecessary trailing zeros.
    private static func formatFloat(_ value: Float) -> String {
        if value == Float(Int(value)) {
            return String(Int(value))
        }
        // Format with up to 4 decimal places, trimming trailing zeros
        let formatted = String(format: "%.4f", value)
        return formatted
            .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
    }
}
