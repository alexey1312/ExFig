// swiftlint:disable file_length

import ArgumentParser
import ExFigCore
import Foundation

/// W3C Design Tokens spec version for export.
public enum W3CVersion: String, ExpressibleByArgument, CaseIterable, Sendable {
    /// Legacy format: hex strings, mode dicts, `$type: "asset"`.
    case v1
    /// W3C DTCG v2025.10: color objects, `$extensions`, no invented types.
    case v2025
}

/// Input structure for asset token export.
public struct AssetToken: Sendable {
    public let name: String
    public let url: String
    public let description: String?
    public let nodeId: String?
    public let fileId: String?

    public init(name: String, url: String, description: String?, nodeId: String? = nil, fileId: String? = nil) {
        self.name = name
        self.url = url
        self.description = description
        self.nodeId = nodeId
        self.fileId = fileId
    }
}

/// Exports design tokens in W3C Design Tokens format.
/// See: https://design-tokens.github.io/community-group/format/
public struct W3CTokensExporter: Sendable {
    public let version: W3CVersion

    public init(version: W3CVersion = .v2025) {
        self.version = version
    }

    // MARK: - Color Hex Conversion

    /// Converts RGBA color components (0.0-1.0) to 6-digit hex string (#RRGGBB).
    /// Alpha is NOT encoded in the hex string (per v2025.10 spec: hex is always 6 digits).
    public func colorToHex(r: Double, g: Double, b: Double) -> String {
        let red = Int(round(r * 255))
        let green = Int(round(g * 255))
        let blue = Int(round(b * 255))
        return String(format: "#%02x%02x%02x", red, green, blue)
    }

    /// Legacy hex conversion with alpha in the string (#RRGGBBAA for transparent colors).
    public func colorToHexLegacy(r: Double, g: Double, b: Double, a: Double) -> String {
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

    // MARK: - Color Object (v2025.10)

    /// Converts RGBA color to a v2025.10 Color Module object.
    ///
    /// Format: `{"colorSpace": "srgb", "components": [r,g,b], "hex": "#rrggbb"}`
    /// Alpha is included as a separate field only when != 1.0.
    public func colorToObject(r: Double, g: Double, b: Double, a: Double) -> [String: Any] {
        var obj: [String: Any] = [
            "colorSpace": "srgb",
            "components": [r, g, b],
            "hex": colorToHex(r: r, g: g, b: b),
        ]
        if a < 1.0 {
            obj["alpha"] = a
        }
        return obj
    }

    /// Converts an ExFigCore Color to a v2025.10 color object.
    public func colorToObject(_ color: Color) -> [String: Any] {
        colorToObject(r: color.red, g: color.green, b: color.blue, a: color.alpha)
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
    ///   - metadata: Optional Figma metadata per color (variableId, fileId)
    /// - Returns: Nested dictionary structure representing W3C tokens
    public func exportColors(
        colorsByMode: [String: [Color]],
        descriptions: [String: String] = [:],
        metadata: [String: ColorTokenMetadata] = [:]
    ) -> [String: Any] {
        switch version {
        case .v1:
            exportColorsV1(colorsByMode: colorsByMode, descriptions: descriptions)
        case .v2025:
            exportColorsV2025(
                colorsByMode: colorsByMode,
                descriptions: descriptions,
                metadata: metadata
            )
        }
    }

    // MARK: - Typography Export

    /// Exports text styles to W3C Design Tokens format.
    public func exportTypography(textStyles: [TextStyle]) -> [String: Any] {
        switch version {
        case .v1:
            exportTypographyV1(textStyles: textStyles)
        case .v2025:
            exportTypographyV2025(textStyles: textStyles)
        }
    }

    // MARK: - Assets Export

    /// Exports assets (icons, images) to W3C Design Tokens format.
    public func exportAssets(assets: [AssetToken]) -> [String: Any] {
        switch version {
        case .v1:
            exportAssetsV1(assets: assets)
        case .v2025:
            exportAssetsV2025(assets: assets)
        }
    }

    // MARK: - JSON Serialization

    /// Serializes tokens to JSON data.
    public func serializeToJSON(_ tokens: [String: Any], compact: Bool) throws -> Data {
        let options: JSONSerialization.WritingOptions = compact
            ? [.sortedKeys]
            : [.prettyPrinted, .sortedKeys]

        return try JSONSerialization.data(withJSONObject: tokens, options: options)
    }
}

// MARK: - Figma Metadata

/// Figma metadata for a color token.
public struct ColorTokenMetadata: Sendable {
    public let variableId: String?
    public let fileId: String?

    public init(variableId: String? = nil, fileId: String? = nil) {
        self.variableId = variableId
        self.fileId = fileId
    }
}

// MARK: - V2025 Implementation

extension W3CTokensExporter {
    private func exportColorsV2025(
        colorsByMode: [String: [Color]],
        descriptions: [String: String],
        metadata: [String: ColorTokenMetadata]
    ) -> [String: Any] {
        // Group colors by name across all modes: name -> [(modeName, Color)]
        var colorsByName: [String: [(mode: String, color: Color)]] = [:]

        for (modeName, colors) in colorsByMode {
            for color in colors {
                colorsByName[color.name, default: []].append((modeName, color))
            }
        }

        var tokens: [String: Any] = [:]

        for (name, modeColors) in colorsByName {
            let path = nameToHierarchy(name)
            var tokenValue: [String: Any] = ["$type": "color"]

            // $value is the default (first) mode as a color object
            let defaultColor = modeColors[0].color
            tokenValue["$value"] = colorToObject(defaultColor)

            // $description
            if let description = descriptions[name], !description.trimmingCharacters(in: .whitespaces).isEmpty {
                tokenValue["$description"] = description
            }

            // $extensions.com.exfig
            var exfigExtension: [String: Any] = [:]

            // Modes (only when >1 mode)
            if modeColors.count > 1 {
                var modes: [String: Any] = [:]
                for (modeName, color) in modeColors {
                    modes[modeName] = colorToObject(color)
                }
                exfigExtension["modes"] = modes
            }

            // Figma metadata
            if let meta = metadata[name] {
                if let variableId = meta.variableId {
                    exfigExtension["variableId"] = variableId
                }
                if let fileId = meta.fileId {
                    exfigExtension["fileId"] = fileId
                }
            }

            if !exfigExtension.isEmpty {
                tokenValue["$extensions"] = ["com.exfig": exfigExtension]
            }

            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }

    private func exportTypographyV2025(textStyles: [TextStyle]) -> [String: Any] {
        var tokens: [String: Any] = [:]

        for style in textStyles {
            let path = nameToHierarchy(style.name)
            var tokenValue: [String: Any] = ["$type": "typography"]

            // Composite $value uses v2025 formats
            var value: [String: Any] = [
                "fontFamily": [style.fontName],
                "fontSize": ["value": style.fontSize, "unit": "px"],
            ]

            if let lineHeight = style.lineHeight {
                // Convert px to ratio when fontSize is available
                let ratio = lineHeight / style.fontSize
                value["lineHeight"] = ratio
            }

            if style.letterSpacing != 0 {
                value["letterSpacing"] = ["value": style.letterSpacing, "unit": "px"]
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

            // Sub-tokens
            let basePath = path

            // fontFamily
            let fontFamilyToken: [String: Any] = [
                "$type": "fontFamily",
                "$value": [style.fontName],
            ]
            insertToken(into: &tokens, path: basePath + ["fontFamily"], value: fontFamilyToken)

            // fontSize
            let fontSizeToken: [String: Any] = [
                "$type": "dimension",
                "$value": ["value": style.fontSize, "unit": "px"],
            ]
            insertToken(into: &tokens, path: basePath + ["fontSize"], value: fontSizeToken)

            // lineHeight (only if set)
            if let lineHeight = style.lineHeight {
                let ratio = lineHeight / style.fontSize
                let lineHeightToken: [String: Any] = [
                    "$type": "number",
                    "$value": ratio,
                ]
                insertToken(into: &tokens, path: basePath + ["lineHeight"], value: lineHeightToken)
            }

            // letterSpacing (only if non-zero)
            if style.letterSpacing != 0 {
                let letterSpacingToken: [String: Any] = [
                    "$type": "dimension",
                    "$value": ["value": style.letterSpacing, "unit": "px"],
                ]
                insertToken(into: &tokens, path: basePath + ["letterSpacing"], value: letterSpacingToken)
            }
        }

        return tokens
    }

    private func exportAssetsV2025(assets: [AssetToken]) -> [String: Any] {
        var tokens: [String: Any] = [:]

        for asset in assets {
            let path = nameToHierarchy(asset.name)
            var tokenValue: [String: Any] = [:]

            if let description = asset.description, !description.isEmpty {
                tokenValue["$description"] = description
            }

            // No $type — asset is not a W3C type. Use $extensions.
            var exfigExtension: [String: Any] = ["assetUrl": asset.url]
            if let nodeId = asset.nodeId {
                exfigExtension["nodeId"] = nodeId
            }
            if let fileId = asset.fileId {
                exfigExtension["fileId"] = fileId
            }

            tokenValue["$extensions"] = ["com.exfig": exfigExtension]

            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }
}

// MARK: - V1 Implementation (Legacy)

extension W3CTokensExporter {
    private func exportColorsV1(
        colorsByMode: [String: [Color]],
        descriptions: [String: String]
    ) -> [String: Any] {
        var colorValues: [String: [String: String]] = [:]

        for (modeName, colors) in colorsByMode {
            for color in colors {
                let hex = colorToHexLegacy(r: color.red, g: color.green, b: color.blue, a: color.alpha)
                colorValues[color.name, default: [:]][modeName] = hex
            }
        }

        var tokens: [String: Any] = [:]

        for (name, modeValues) in colorValues {
            let path = nameToHierarchy(name)
            var tokenValue: [String: Any] = [
                "$type": "color",
                "$value": modeValues,
            ]

            if let description = descriptions[name], !description.isEmpty {
                tokenValue["$description"] = description
            }

            insertToken(into: &tokens, path: path, value: tokenValue)
        }

        return tokens
    }

    private func exportTypographyV1(textStyles: [TextStyle]) -> [String: Any] {
        var tokens: [String: Any] = [:]

        for style in textStyles {
            let path = nameToHierarchy(style.name)
            var tokenValue: [String: Any] = ["$type": "typography"]

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

    private func exportAssetsV1(assets: [AssetToken]) -> [String: Any] {
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
}

// MARK: - Private Helpers

extension W3CTokensExporter {
    func insertToken(into dict: inout [String: Any], path: [String], value: [String: Any]) {
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
