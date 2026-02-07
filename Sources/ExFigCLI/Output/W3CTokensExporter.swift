import ExFigCore
import Foundation

/// Input structure for asset token export.
public struct AssetToken: Sendable {
    public let name: String
    public let url: String
    public let description: String?

    public init(name: String, url: String, description: String?) {
        self.name = name
        self.url = url
        self.description = description
    }
}

/// Exports design tokens in W3C Design Tokens format.
/// See: https://design-tokens.github.io/community-group/format/
public struct W3CTokensExporter: Sendable {
    public init() {}

    // MARK: - Color Hex Conversion

    /// Converts RGBA color components (0.0-1.0) to hex string.
    /// Returns #RRGGBB for opaque colors, #RRGGBBAA for colors with transparency.
    public func colorToHex(r: Double, g: Double, b: Double, a: Double) -> String {
        let red = Int(round(r * 255))
        let green = Int(round(g * 255))
        let blue = Int(round(b * 255))

        if a >= 1.0 {
            return String(format: "#%02x%02x%02x", red, green, blue)
        } else {
            let alpha = Int(round(a * 255))
            return String(format: "#%02x%02x%02x%02x", red, green, blue, alpha)
        }
    }

    // MARK: - Name Hierarchy

    /// Converts a slash-separated name into path components.
    /// Example: "Background/Primary" → ["Background", "Primary"]
    public func nameToHierarchy(_ name: String) -> [String] {
        name.split(separator: "/").map(String.init)
    }

    // MARK: - Colors Export

    /// Exports colors to W3C Design Tokens format.
    ///
    /// - Parameters:
    ///   - colorsByMode: Dictionary mapping mode names (e.g., "Light", "Dark") to arrays of colors
    ///   - descriptions: Optional dictionary mapping color names to descriptions
    /// - Returns: Nested dictionary structure representing W3C tokens
    public func exportColors(
        colorsByMode: [String: [Color]],
        descriptions: [String: String] = [:]
    ) -> [String: Any] {
        // Group colors by name across all modes
        var colorValues: [String: [String: String]] = [:] // name -> mode -> hex

        for (modeName, colors) in colorsByMode {
            for color in colors {
                let hex = colorToHex(r: color.red, g: color.green, b: color.blue, a: color.alpha)
                colorValues[color.name, default: [:]][modeName] = hex
            }
        }

        // Build nested token structure
        var tokens: [String: Any] = [:]

        for (name, modeValues) in colorValues {
            let path = nameToHierarchy(name)
            var tokenValue: [String: Any] = [
                "$type": "color",
            ]

            // Always use dict format for consistency (mode name -> hex value)
            tokenValue["$value"] = modeValues

            if let description = descriptions[name], !description.isEmpty {
                tokenValue["$description"] = description
            }

            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }

    // MARK: - Typography Export

    /// Exports text styles to W3C Design Tokens format.
    ///
    /// - Parameter textStyles: Array of text styles to export
    /// - Returns: Nested dictionary structure representing W3C tokens
    public func exportTypography(textStyles: [TextStyle]) -> [String: Any] {
        var tokens: [String: Any] = [:]

        for style in textStyles {
            let path = nameToHierarchy(style.name)
            var tokenValue: [String: Any] = [
                "$type": "typography",
            ]

            var value: [String: Any] = [
                "fontFamily": style.fontName,
                "fontSize": style.fontSize,
            ]

            if let lineHeight = style.lineHeight {
                value["lineHeight"] = lineHeight
            }

            if style.letterSpacing != 0 {
                value["letterSpacing"] = style.letterSpacing
            }

            switch style.textCase {
            case .uppercased:
                value["textTransform"] = "uppercase"
            case .lowercased:
                value["textTransform"] = "lowercase"
            case .original:
                break
            }

            tokenValue["$value"] = value
            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }

    // MARK: - Assets Export

    /// Exports assets (icons, images) to W3C Design Tokens format.
    ///
    /// - Parameter assets: Array of asset tokens to export
    /// - Returns: Nested dictionary structure representing W3C tokens
    public func exportAssets(assets: [AssetToken]) -> [String: Any] {
        var tokens: [String: Any] = [:]

        for asset in assets {
            let path = nameToHierarchy(asset.name)
            var tokenValue: [String: Any] = [
                "$type": "asset",
                "$value": asset.url,
            ]

            if let description = asset.description, !description.isEmpty {
                tokenValue["$description"] = description
            }

            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }

    // MARK: - JSON Serialization

    /// Serializes tokens to JSON data.
    ///
    /// - Parameters:
    ///   - tokens: Token dictionary to serialize
    ///   - compact: If true, outputs minified JSON; otherwise pretty-printed
    /// - Returns: JSON data
    public func serializeToJSON(_ tokens: [String: Any], compact: Bool) throws -> Data {
        let options: JSONSerialization.WritingOptions = compact
            ? [.sortedKeys]
            : [.prettyPrinted, .sortedKeys]

        return try JSONSerialization.data(withJSONObject: tokens, options: options)
    }

    // MARK: - Private Helpers

    private func insertToken(into dict: inout [String: Any], path: [String], value: [String: Any]) {
        guard !path.isEmpty else { return }

        if path.count == 1 {
            dict[path[0]] = value
        } else {
            let key = path[0]
            var nested = (dict[key] as? [String: Any]) ?? [:]
            insertToken(into: &nested, path: Array(path.dropFirst()), value: value)
            dict[key] = nested
        }
    }
}
