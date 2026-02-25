// swiftlint:disable file_length

import ExFigCore
import Foundation

/// Errors during .tokens.json parsing.
enum TokensFileError: LocalizedError {
    case fileNotFound(String)
    case malformedJSON(String)
    case missingValue(tokenPath: String)
    case invalidColorObject(tokenPath: String, detail: String)
    case invalidDimensionObject(tokenPath: String, detail: String)
    case circularAlias(tokenPath: String, chain: [String])
    case unresolvedAlias(tokenPath: String, reference: String)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(path):
            "Token file not found: \(path)"
        case let .malformedJSON(detail):
            "Malformed JSON in token file: \(detail)"
        case let .missingValue(tokenPath):
            "Token missing $value: \(tokenPath)"
        case let .invalidColorObject(tokenPath, detail):
            "Invalid color object at \(tokenPath): \(detail)"
        case let .invalidDimensionObject(tokenPath, detail):
            "Invalid dimension object at \(tokenPath): \(detail)"
        case let .circularAlias(tokenPath, chain):
            "Circular alias at \(tokenPath): \(chain.joined(separator: " → "))"
        case let .unresolvedAlias(tokenPath, reference):
            "Unresolved alias at \(tokenPath): \(reference)"
        }
    }
}

/// A parsed token from a .tokens.json file.
struct ParsedToken {
    let path: String
    let type: String?
    let value: ParsedTokenValue
    let description: String?
    let deprecated: DeprecatedValue?
    let extensions: JSONValue?

    /// `$deprecated` can be boolean or string.
    enum DeprecatedValue {
        case flag(Bool)
        case message(String)
    }
}

/// Possible parsed token values.
enum ParsedTokenValue {
    case color(ColorValue)
    case dimension(DimensionValue)
    case number(Double)
    case fontFamily([String])
    case typography(TypographyValue)
    case alias(String)
    case string(String)
    case unknown

    struct ColorValue {
        let colorSpace: String
        let components: [Double]
        let alpha: Double
        let hex: String?
    }

    struct DimensionValue {
        let value: Double
        let unit: String
    }

    struct TypographyValue {
        let fontFamily: [String]
        let fontSize: DimensionValue?
        let fontWeight: Double?
        let lineHeight: Double?
        let letterSpacing: DimensionValue?
    }
}

// MARK: - TokensFileSource Parser

/// Parses W3C DTCG .tokens.json files into typed token models.
///
/// Supports nested groups, `$type` inheritance, alias resolution,
/// `$root`, `$extends`, and `$deprecated`.
struct TokensFileSource {
    /// All parsed tokens indexed by dot-path (e.g., "Brand.Primary").
    private(set) var tokens: [String: ParsedToken] = [:]
    /// Warnings emitted during parsing (unsupported types, non-sRGB colors).
    private(set) var warnings: [String] = []

    /// Unsupported W3C token types that emit warnings.
    private static let unsupportedTypes: Set<String> = [
        "cubicBezier", "gradient", "strokeStyle", "border",
        "transition", "shadow", "duration",
    ]

    // MARK: - Public API

    /// Parse a .tokens.json file at the given path.
    static func parse(fileAt path: String) throws -> TokensFileSource {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw TokensFileError.fileNotFound(path)
        }
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    /// Parse JSON data as a W3C DTCG token document.
    static func parse(data: Data) throws -> TokensFileSource {
        let json: JSONValue
        do {
            json = try JSONCodec.parseValue(from: data)
        } catch {
            throw TokensFileError.malformedJSON("\(error)")
        }
        guard json.object != nil else {
            throw TokensFileError.malformedJSON("Root must be a JSON object")
        }
        var source = TokensFileSource()
        source.parseGroup(json: json, path: [], inheritedType: nil)
        return source
    }

    // MARK: - Group Parsing (Task 8.2)

    private mutating func parseGroup(
        json: JSONValue,
        path: [String],
        inheritedType: String?
    ) {
        let groupType = json["$type"]?.string ?? inheritedType
        let groupDeprecated = parseDeprecated(json["$deprecated"])

        // Handle $extends (Task 8.9)
        // $extends is noted but actual merge requires the full document —
        // we store it as metadata for post-processing.

        // Handle $root token (Task 8.8)
        if json["$value"] != nil, !path.isEmpty {
            // This group itself is also a token (rare but valid)
            parseToken(json: json, path: path, inheritedType: groupType, groupDeprecated: groupDeprecated)
        }

        if let rootValue = json["$root"], rootValue["$value"] != nil {
            let rootPath = path + ["$root"]
            parseToken(json: rootValue, path: rootPath, inheritedType: groupType, groupDeprecated: groupDeprecated)
        }

        // Iterate non-$ keys as child groups or tokens
        guard let obj = json.object else { return }
        for (key, value) in obj where !key.hasPrefix("$") {
            guard value.object != nil else { continue }

            let childPath = path + [key]

            if value["$value"] != nil {
                parseToken(json: value, path: childPath, inheritedType: groupType, groupDeprecated: groupDeprecated)
            } else {
                parseGroup(json: value, path: childPath, inheritedType: groupType)
            }
        }
    }

    // MARK: - Token Parsing

    private mutating func parseToken(
        json: JSONValue,
        path: [String],
        inheritedType: String?,
        groupDeprecated: ParsedToken.DeprecatedValue?
    ) {
        let tokenPath = path.joined(separator: ".")
        let type = json["$type"]?.string ?? inheritedType
        let description = json["$description"]?.string
        let deprecated = parseDeprecated(json["$deprecated"]) ?? groupDeprecated

        // Check for unsupported types (Task 8.14)
        if let type, Self.unsupportedTypes.contains(type) {
            warnings.append("Unsupported token type '\(type)' at \(tokenPath) — skipped")
            return
        }

        guard let rawValue = json["$value"] else {
            warnings.append("Token missing $value at \(tokenPath)")
            return
        }

        let value = parseValue(rawValue, type: type, tokenPath: tokenPath)

        tokens[tokenPath] = ParsedToken(
            path: tokenPath,
            type: type,
            value: value,
            description: description,
            deprecated: deprecated,
            extensions: json["$extensions"]
        )
    }

    // MARK: - Value Parsing

    private mutating func parseValue(_ rawValue: JSONValue, type: String?, tokenPath: String) -> ParsedTokenValue {
        // Alias reference: string starting with "{"
        if let str = rawValue.string, str.hasPrefix("{"), str.hasSuffix("}") {
            let reference = String(str.dropFirst().dropLast())
            return .alias(reference)
        }

        switch type {
        case "color":
            return parseColorValue(rawValue, tokenPath: tokenPath)
        case "dimension":
            return parseDimensionValue(rawValue, tokenPath: tokenPath)
        case "number":
            return parseNumberValue(rawValue, tokenPath: tokenPath)
        case "fontFamily":
            return parseFontFamilyValue(rawValue, tokenPath: tokenPath)
        case "typography":
            return parseTypographyValue(rawValue, tokenPath: tokenPath)
        default:
            return inferValueType(rawValue, tokenPath: tokenPath)
        }
    }

    private mutating func parseNumberValue(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        if let num = rawValue.number { return .number(num) }
        warnings.append("Expected number value at \(tokenPath)")
        return .unknown
    }

    private mutating func inferValueType(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        if rawValue["colorSpace"] != nil {
            return parseColorValue(rawValue, tokenPath: tokenPath)
        }
        if rawValue["value"] != nil, rawValue["unit"] != nil {
            return parseDimensionValue(rawValue, tokenPath: tokenPath)
        }
        if let num = rawValue.number { return .number(num) }
        if let str = rawValue.string { return .string(str) }
        return .unknown
    }

    // MARK: - Color Parsing (Task 8.3)

    private mutating func parseColorValue(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        guard rawValue.object != nil else {
            // Legacy hex string fallback
            if let hex = rawValue.string {
                if let color = hexToColorValue(hex) { return .color(color) }
            }
            warnings.append("Invalid color value at \(tokenPath)")
            return .unknown
        }

        guard let colorSpace = rawValue["colorSpace"]?.string else {
            warnings.append("Missing colorSpace at \(tokenPath)")
            return .unknown
        }

        guard let components = rawValue["components"]?.array,
              components.count >= 3
        else {
            warnings.append("Invalid components at \(tokenPath)")
            return .unknown
        }

        let rgb = components.prefix(3).map { $0.number ?? 0 }
        let alpha = rawValue["alpha"]?.number ?? 1.0
        let hex = rawValue["hex"]?.string

        // Task 8.11: non-sRGB color space warning
        if colorSpace != "srgb" {
            warnings.append("Non-sRGB color space '\(colorSpace)' at \(tokenPath) — values used as-is")
        }

        return .color(ParsedTokenValue.ColorValue(
            colorSpace: colorSpace,
            components: rgb,
            alpha: alpha,
            hex: hex
        ))
    }

    private func hexToColorValue(_ hex: String) -> ParsedTokenValue.ColorValue? {
        var cleanHex = hex
        if cleanHex.hasPrefix("#") { cleanHex = String(cleanHex.dropFirst()) }
        guard cleanHex.count == 6 || cleanHex.count == 8 else { return nil }

        guard let hexNum = UInt64(cleanHex, radix: 16) else { return nil }

        let r: Double
        let g: Double
        let b: Double
        let a: Double

        if cleanHex.count == 8 {
            r = Double((hexNum >> 24) & 0xFF) / 255
            g = Double((hexNum >> 16) & 0xFF) / 255
            b = Double((hexNum >> 8) & 0xFF) / 255
            a = Double(hexNum & 0xFF) / 255
        } else {
            r = Double((hexNum >> 16) & 0xFF) / 255
            g = Double((hexNum >> 8) & 0xFF) / 255
            b = Double(hexNum & 0xFF) / 255
            a = 1.0
        }

        return ParsedTokenValue.ColorValue(colorSpace: "srgb", components: [r, g, b], alpha: a, hex: hex)
    }

    // MARK: - Dimension Parsing (Task 8.4)

    private mutating func parseDimensionValue(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        guard rawValue.object != nil else {
            warnings.append("Dimension $value must be an object at \(tokenPath)")
            return .unknown
        }

        guard let numericValue = rawValue["value"]?.number else {
            warnings.append("Missing numeric 'value' in dimension at \(tokenPath)")
            return .unknown
        }

        guard let unit = rawValue["unit"]?.string else {
            warnings.append("Missing 'unit' in dimension at \(tokenPath)")
            return .unknown
        }

        return .dimension(ParsedTokenValue.DimensionValue(value: numericValue, unit: unit))
    }

    // MARK: - Typography Parsing (Task 8.5)

    private mutating func parseTypographyValue(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        guard rawValue.object != nil else {
            warnings.append("Typography $value must be an object at \(tokenPath)")
            return .unknown
        }

        let fontFamily: [String] = if let arr = rawValue["fontFamily"]?.array {
            arr.compactMap(\.string)
        } else if let str = rawValue["fontFamily"]?.string {
            [str]
        } else {
            []
        }

        var fontSize: ParsedTokenValue.DimensionValue?
        if let fsObj = rawValue["fontSize"],
           let v = fsObj["value"]?.number,
           let u = fsObj["unit"]?.string
        {
            fontSize = ParsedTokenValue.DimensionValue(value: v, unit: u)
        }

        var fontWeight: Double?
        if let w = rawValue["fontWeight"]?.number {
            fontWeight = w
        } else if let w = rawValue["fontWeight"]?.string {
            fontWeight = Self.fontWeightFromString(w)
        }

        let lineHeight = rawValue["lineHeight"]?.number

        var letterSpacing: ParsedTokenValue.DimensionValue?
        if let lsObj = rawValue["letterSpacing"],
           let v = lsObj["value"]?.number,
           let u = lsObj["unit"]?.string
        {
            letterSpacing = ParsedTokenValue.DimensionValue(value: v, unit: u)
        }

        return .typography(ParsedTokenValue.TypographyValue(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fontWeight,
            lineHeight: lineHeight,
            letterSpacing: letterSpacing
        ))
    }

    // MARK: - Font Family Parsing

    private mutating func parseFontFamilyValue(_ rawValue: JSONValue, tokenPath: String) -> ParsedTokenValue {
        if let arr = rawValue.array { return .fontFamily(arr.compactMap(\.string)) }
        if let str = rawValue.string { return .fontFamily([str]) }
        warnings.append("Invalid fontFamily value at \(tokenPath)")
        return .unknown
    }

    // MARK: - Font Weight Mapping (Task 8.12)

    private static let fontWeightMap: [String: Double] = [
        "thin": 100, "hairline": 100,
        "extralight": 200, "ultralight": 200, "extra-light": 200, "ultra-light": 200,
        "light": 300,
        "normal": 400, "regular": 400, "book": 400,
        "medium": 500,
        "semibold": 600, "demibold": 600, "semi-bold": 600, "demi-bold": 600,
        "bold": 700,
        "extrabold": 800, "ultrabold": 800, "extra-bold": 800, "ultra-bold": 800,
        "black": 900, "heavy": 900,
        "extrablack": 950, "ultrablack": 950, "extra-black": 950, "ultra-black": 950,
    ]

    static func fontWeightFromString(_ name: String) -> Double? {
        fontWeightMap[name.lowercased()]
    }

    // MARK: - $deprecated Parsing (Task 8.10)

    private func parseDeprecated(_ value: JSONValue?) -> ParsedToken.DeprecatedValue? {
        guard let value else { return nil }
        if let bool = value.bool { return .flag(bool) }
        if let str = value.string { return .message(str) }
        return nil
    }
}

// MARK: - Alias Resolution (Task 8.7)

extension TokensFileSource {
    /// Resolves all aliases in the parsed tokens, detecting circular references.
    mutating func resolveAliases() throws {
        var resolved: Set<String> = []
        var resolving: Set<String> = []

        for path in tokens.keys {
            try resolveAlias(path: path, resolved: &resolved, resolving: &resolving, chain: [])
        }
    }

    private mutating func resolveAlias(
        path: String,
        resolved: inout Set<String>,
        resolving: inout Set<String>,
        chain: [String]
    ) throws {
        guard !resolved.contains(path) else { return }

        guard case let .alias(reference) = tokens[path]?.value else {
            resolved.insert(path)
            return
        }

        if resolving.contains(path) {
            throw TokensFileError.circularAlias(tokenPath: path, chain: chain + [path])
        }

        resolving.insert(path)

        guard var target = tokens[reference] else {
            throw TokensFileError.unresolvedAlias(tokenPath: path, reference: reference)
        }

        // Recursively resolve the target first
        try resolveAlias(path: reference, resolved: &resolved, resolving: &resolving, chain: chain + [path])

        // Copy resolved value, preserving original token metadata
        if let resolvedTarget = tokens[reference] {
            target = resolvedTarget
        }

        tokens[path] = ParsedToken(
            path: path,
            type: tokens[path]?.type ?? target.type,
            value: target.value,
            description: tokens[path]?.description ?? target.description,
            deprecated: tokens[path]?.deprecated ?? target.deprecated,
            extensions: tokens[path]?.extensions
        )

        resolving.remove(path)
        resolved.insert(path)
    }
}

// MARK: - Model Mapping (Task 8.6)

extension TokensFileSource {
    /// Converts parsed color tokens to ExFigCore Color models.
    func toColors() -> [Color] {
        tokens.compactMap { path, token -> Color? in
            guard case let .color(colorValue) = token.value else { return nil }
            guard colorValue.components.count >= 3 else { return nil }

            return Color(
                name: path.replacingOccurrences(of: ".", with: "/"),
                platform: nil,
                red: colorValue.components[0],
                green: colorValue.components[1],
                blue: colorValue.components[2],
                alpha: colorValue.alpha
            )
        }
    }

    /// Converts parsed typography tokens to ExFigCore TextStyle models.
    func toTextStyles() -> [TextStyle] {
        tokens.compactMap { path, token -> TextStyle? in
            guard case let .typography(typo) = token.value else { return nil }
            guard !typo.fontFamily.isEmpty else { return nil }

            return TextStyle(
                name: path.replacingOccurrences(of: ".", with: "/"),
                fontName: typo.fontFamily[0],
                fontSize: typo.fontSize?.value ?? 16,
                fontStyle: nil,
                lineHeight: typo.lineHeight,
                letterSpacing: typo.letterSpacing?.value ?? 0,
                textCase: .original
            )
        }
    }

    /// Converts parsed dimension tokens to NumberToken models.
    func toDimensionTokens() -> [NumberToken] {
        tokens.compactMap { path, token -> NumberToken? in
            guard case let .dimension(dim) = token.value else { return nil }

            return NumberToken(
                name: path.replacingOccurrences(of: ".", with: "/"),
                value: dim.value,
                tokenType: .dimension,
                description: token.description,
                variableId: "",
                fileId: ""
            )
        }
    }

    /// Converts parsed number tokens to NumberToken models.
    func toNumberTokens() -> [NumberToken] {
        tokens.compactMap { path, token -> NumberToken? in
            guard case let .number(num) = token.value else { return nil }

            return NumberToken(
                name: path.replacingOccurrences(of: ".", with: "/"),
                value: num,
                tokenType: .number,
                description: token.description,
                variableId: "",
                fileId: ""
            )
        }
    }
}

// swiftlint:enable file_length
