import Foundation

/// Replaces hex colors in SVG content based on a light→dark color map.
///
/// Used by ``VariableModeDarkGenerator`` to create dark SVG variants
/// by substituting resolved light colors with their dark counterparts.
enum SVGColorReplacer {
    /// Replaces hex colors in SVG content using the provided color map.
    ///
    /// - Parameters:
    ///   - svgContent: The SVG string to process.
    ///   - colorMap: A mapping of normalized 6-digit lowercase hex (no `#`) from light to dark.
    /// - Returns: The SVG string with colors replaced.
    static func replaceColors(in svgContent: String, colorMap: [String: String]) -> String {
        guard !colorMap.isEmpty else { return svgContent }

        var result = svgContent

        // Replace hex colors in SVG attributes: fill="#RRGGBB", stroke="#RRGGBB", stop-color="#RRGGBB"
        // and inline CSS: fill:#RRGGBB, stroke:#RRGGBB
        for (lightHex, darkHex) in colorMap {
            // Match both attribute and CSS property styles, case-insensitive
            let replacements: [(pattern: String, template: String)] = [
                // Attribute style: fill="#aabbcc" or stroke="#AABBCC"
                (
                    "(fill|stroke|stop-color|flood-color|lighting-color)(\\s*=\\s*[\"'])#\(lightHex)([\"'])",
                    "$1$2#\(darkHex)$3"
                ),
                // CSS property style: fill:#aabbcc or stroke:#AABBCC (in style attributes)
                (
                    "(fill|stroke|stop-color|flood-color|lighting-color)(\\s*:\\s*)#\(lightHex)",
                    "$1$2#\(darkHex)"
                ),
            ]

            for (pattern, template) in replacements {
                do {
                    let regex = try NSRegularExpression(
                        pattern: pattern,
                        options: .caseInsensitive
                    )
                    let range = NSRange(result.startIndex..., in: result)
                    result = regex.stringByReplacingMatches(
                        in: result,
                        range: range,
                        withTemplate: template
                    )
                } catch {
                    assertionFailure("Invalid regex pattern: \(pattern), error: \(error)")
                }
            }
        }

        return result
    }

    /// Normalizes a ``FigmaAPI.PaintColor`` (RGBA 0–1) to a 6-digit lowercase hex string without `#`.
    static func normalizeColor(r: Double, g: Double, b: Double) -> String {
        let ri = min(255, max(0, Int(round(r * 255))))
        let gi = min(255, max(0, Int(round(g * 255))))
        let bi = min(255, max(0, Int(round(b * 255))))
        return String(format: "%02x%02x%02x", ri, gi, bi)
    }
}
