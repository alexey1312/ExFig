import Foundation

/// Converts raw SVG data to JSX-compatible format for React components.
public enum SVGToJSXConverter {
    /// Result of SVG to JSX conversion.
    public struct ConversionResult {
        /// The viewBox attribute value (e.g., "0 0 24 24")
        public let viewBox: String
        /// The inner SVG content converted to JSX syntax
        public let jsxContent: String
    }

    /// Converts SVG data to JSX format.
    ///
    /// - Parameter svgData: Raw SVG file data
    /// - Returns: ConversionResult with viewBox and JSX content
    /// - Throws: SVGToJSXError if conversion fails
    public static func convert(svgData: Data) throws -> ConversionResult {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            throw SVGToJSXError.invalidEncoding
        }

        let viewBox = try extractViewBox(from: svgString)
        let innerContent = try extractInnerContent(from: svgString)
        let jsxContent = convertAttributesToJSX(innerContent)

        return ConversionResult(viewBox: viewBox, jsxContent: jsxContent)
    }

    // MARK: - Private Helpers

    /// Extracts viewBox attribute from SVG element.
    private static func extractViewBox(from svg: String) throws -> String {
        // Match viewBox="..." with flexible whitespace
        let pattern = #"viewBox\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                  in: svg,
                  options: [],
                  range: NSRange(svg.startIndex..., in: svg)
              ),
              let viewBoxRange = Range(match.range(at: 1), in: svg)
        else {
            // Fallback: try to extract from width/height
            return try extractViewBoxFromDimensions(svg)
        }
        return String(svg[viewBoxRange])
    }

    /// Fallback: construct viewBox from width/height attributes.
    private static func extractViewBoxFromDimensions(_ svg: String) throws -> String {
        let widthPattern = #"<svg[^>]*\swidth\s*=\s*["'](\d+(?:\.\d+)?)"#
        let heightPattern = #"<svg[^>]*\sheight\s*=\s*["'](\d+(?:\.\d+)?)"#

        guard let widthRegex = try? NSRegularExpression(pattern: widthPattern, options: []),
              let heightRegex = try? NSRegularExpression(pattern: heightPattern, options: []),
              let widthMatch = widthRegex.firstMatch(
                  in: svg,
                  options: [],
                  range: NSRange(svg.startIndex..., in: svg)
              ),
              let heightMatch = heightRegex.firstMatch(
                  in: svg,
                  options: [],
                  range: NSRange(svg.startIndex..., in: svg)
              ),
              let widthRange = Range(widthMatch.range(at: 1), in: svg),
              let heightRange = Range(heightMatch.range(at: 1), in: svg)
        else {
            throw SVGToJSXError.missingViewBox
        }

        let width = String(svg[widthRange])
        let height = String(svg[heightRange])
        return "0 0 \(width) \(height)"
    }

    /// Extracts content between <svg> and </svg> tags.
    private static func extractInnerContent(from svg: String) throws -> String {
        // Find opening <svg tag
        guard let svgTagRange = svg.range(of: "<svg") else {
            throw SVGToJSXError.malformedSVG
        }

        // Find the closing > of the opening svg tag
        guard let openTagEndRange = svg.range(
            of: ">",
            options: [],
            range: svgTagRange.upperBound ..< svg.endIndex
        ) else {
            throw SVGToJSXError.malformedSVG
        }

        // Find closing </svg> tag
        guard let closeTagRange = svg.range(of: "</svg>", options: .backwards) else {
            throw SVGToJSXError.malformedSVG
        }

        // Extract inner content
        let innerContent = svg[openTagEndRange.upperBound ..< closeTagRange.lowerBound]
        return String(innerContent).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Converts HTML attributes to JSX format.
    private static func convertAttributesToJSX(_ content: String) -> String {
        var result = content

        // HTML to JSX attribute mappings
        let attributeMappings: [(html: String, jsx: String)] = [
            ("fill-rule", "fillRule"),
            ("fill-opacity", "fillOpacity"),
            ("stroke-width", "strokeWidth"),
            ("stroke-linecap", "strokeLinecap"),
            ("stroke-linejoin", "strokeLinejoin"),
            ("stroke-miterlimit", "strokeMiterlimit"),
            ("stroke-dasharray", "strokeDasharray"),
            ("stroke-dashoffset", "strokeDashoffset"),
            ("stroke-opacity", "strokeOpacity"),
            ("clip-path", "clipPath"),
            ("clip-rule", "clipRule"),
            ("font-family", "fontFamily"),
            ("font-size", "fontSize"),
            ("font-weight", "fontWeight"),
            ("font-style", "fontStyle"),
            ("text-anchor", "textAnchor"),
            ("text-decoration", "textDecoration"),
            ("dominant-baseline", "dominantBaseline"),
            ("alignment-baseline", "alignmentBaseline"),
            ("baseline-shift", "baselineShift"),
            ("stop-color", "stopColor"),
            ("stop-opacity", "stopOpacity"),
            ("flood-color", "floodColor"),
            ("flood-opacity", "floodOpacity"),
            ("color-interpolation", "colorInterpolation"),
            ("color-interpolation-filters", "colorInterpolationFilters"),
            ("enable-background", "enableBackground"),
            ("xlink:href", "xlinkHref"),
            ("xml:space", "xmlSpace"),
            ("class", "className"),
        ]

        for mapping in attributeMappings {
            // Match attribute="value" pattern with the HTML attribute name
            let pattern = "\\b\(mapping.html)="
            result = result.replacingOccurrences(
                of: pattern,
                with: "\(mapping.jsx)=",
                options: .regularExpression
            )
        }

        return result
    }
}

/// Errors that can occur during SVG to JSX conversion.
public enum SVGToJSXError: LocalizedError {
    case invalidEncoding
    case missingViewBox
    case malformedSVG

    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            "SVG data is not valid UTF-8"
        case .missingViewBox:
            "SVG missing viewBox attribute and dimensions"
        case .malformedSVG:
            "Malformed SVG structure"
        }
    }
}
