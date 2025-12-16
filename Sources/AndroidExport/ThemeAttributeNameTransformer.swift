import ExFigCore
import Foundation

/// Transforms XML color names to Android theme attribute names.
///
/// The transformation follows this algorithm:
/// 1. Strip configured prefixes from start of name
/// 2. Convert to target case style (default: PascalCase)
/// 3. Prepend prefix (default: "color")
///
/// Example transformations with default settings:
/// - `background_primary` → `colorBackgroundPrimary`
/// - `text_and_icon_primary` → `colorTextAndIconPrimary`
///
/// With `stripPrefixes: ["extensions_"]`:
/// - `extensions_background_error` → `colorBackgroundError`
public struct ThemeAttributeNameTransformer: Sendable {
    private let stripPrefixes: [String]
    private let style: NameStyle
    private let prefix: String

    /// Creates a theme attribute name transformer.
    /// - Parameters:
    ///   - stripPrefixes: Prefixes to remove from the start of color names.
    ///   - style: Target case style for the result (default: PascalCase).
    ///   - prefix: Prefix to prepend to the result (default: "color").
    public init(
        stripPrefixes: [String] = [],
        style: NameStyle = .pascalCase,
        prefix: String = "color"
    ) {
        self.stripPrefixes = stripPrefixes
        self.style = style
        self.prefix = prefix
    }

    /// Transforms an XML color name to a theme attribute name.
    ///
    /// - Parameter xmlName: The snake_case color name from XML (e.g., "background_primary")
    /// - Returns: The theme attribute name (e.g., "colorBackgroundPrimary")
    public func transform(_ xmlName: String) -> String {
        var name = xmlName

        // Step 1: Strip matching prefix from start (only first match)
        if let matchingPrefix = stripPrefixes.first(where: { name.hasPrefix($0) }) {
            name = String(name.dropFirst(matchingPrefix.count))
        }

        // Step 2: Convert to target case style
        let caseConverted = convertToStyle(name, style: style)

        // Step 3: Prepend prefix with appropriate casing
        return prependPrefix(to: caseConverted, prefix: prefix, style: style)
    }

    // MARK: - Private

    private func convertToStyle(_ input: String, style: NameStyle) -> String {
        switch style {
        case .pascalCase:
            input.camelCased()
        case .camelCase:
            input.lowerCamelCased()
        case .snakeCase:
            input.snakeCased()
        case .kebabCase:
            input.kebabCased()
        case .screamingSnakeCase:
            input.screamingSnakeCased()
        }
    }

    private func prependPrefix(to value: String, prefix: String, style: NameStyle) -> String {
        guard !prefix.isEmpty else { return value }

        switch style {
        case .pascalCase:
            // prefix + PascalValue → prefixPascalValue (e.g., "color" + "BackgroundPrimary")
            return prefix + value
        case .camelCase:
            // prefix + camelValue → prefixCamelValue
            return prefix + value.camelCased()
        case .snakeCase:
            // prefix + snake_value → prefix_snake_value
            return prefix + "_" + value
        case .kebabCase:
            // prefix + kebab-value → prefix-kebab-value
            return prefix + "-" + value
        case .screamingSnakeCase:
            // PREFIX + SCREAMING_VALUE → PREFIX_SCREAMING_VALUE
            return prefix.uppercased() + "_" + value
        }
    }
}
