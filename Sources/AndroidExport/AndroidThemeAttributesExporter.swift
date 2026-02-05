import ExFigCore
import Foundation
import OrderedCollections

/// Represents a collision where multiple XML color names map to the same theme attribute name.
public struct ThemeAttributeCollision: Sendable, Equatable {
    /// The theme attribute name that had a collision.
    public let attributeName: String

    /// The XML color name that was kept (first occurrence).
    public let keptXmlName: String

    /// The XML color name that was discarded (subsequent occurrence).
    public let discardedXmlName: String

    public init(attributeName: String, keptXmlName: String, discardedXmlName: String) {
        self.attributeName = attributeName
        self.keptXmlName = keptXmlName
        self.discardedXmlName = discardedXmlName
    }
}

/// Result of theme attributes export containing generated content for attrs.xml and styles.xml.
public struct ThemeAttributesExportResult: Sendable {
    /// Content for attrs.xml (lines to insert between markers).
    /// Example: `    <attr name="colorBackgroundPrimary" format="color" />`
    public let attrsContent: String

    /// Content for styles.xml light mode (lines to insert between markers).
    /// Example: `        <item name="colorBackgroundPrimary">@color/background_primary</item>`
    public let stylesContent: String

    /// Theme attribute names mapped to their XML color names (insertion order preserved).
    /// Example: `["colorBackgroundPrimary": "background_primary"]`
    public let attributeMap: OrderedDictionary<String, String>

    /// Collisions detected during export (multiple XML names → same attribute name).
    public let collisions: [ThemeAttributeCollision]

    /// Number of attributes generated.
    public var count: Int {
        attributeMap.count
    }

    /// Whether any collisions were detected.
    public var hasCollisions: Bool {
        !collisions.isEmpty
    }

    public init(
        attrsContent: String,
        stylesContent: String,
        attributeMap: OrderedDictionary<String, String>,
        collisions: [ThemeAttributeCollision] = []
    ) {
        self.attrsContent = attrsContent
        self.stylesContent = stylesContent
        self.attributeMap = attributeMap
        self.collisions = collisions
    }
}

/// Exports Android theme attributes from color pairs.
///
/// This exporter generates:
/// - `attrs.xml` declarations: `<attr name="colorXxx" format="color" />`
/// - `styles.xml` items: `<item name="colorXxx">@color/xxx</item>`
///
/// The name transformation converts XML color names (snake_case) to theme attribute names
/// (typically PascalCase with "color" prefix).
///
/// Example:
/// ```swift
/// let exporter = AndroidThemeAttributesExporter(
///     stripPrefixes: ["extensions_"],
///     style: .pascalCase,
///     prefix: "color"
/// )
/// let result = exporter.export(colorPairs: colorPairs)
/// // result.attrsContent contains lines for attrs.xml
/// // result.stylesContent contains lines for styles.xml
/// ```
public struct AndroidThemeAttributesExporter: Sendable {
    private let nameTransformer: ThemeAttributeNameTransformer

    /// Indentation for attr elements in attrs.xml (4 spaces).
    private let attrIndent = "    "

    /// Indentation for item elements in styles.xml (8 spaces - inside <style> tag).
    private let itemIndent = "        "

    /// Creates a theme attributes exporter.
    ///
    /// - Parameters:
    ///   - stripPrefixes: Prefixes to remove from color names before transformation.
    ///   - style: Target case style for attribute names (default: PascalCase).
    ///   - prefix: Prefix to add to attribute names (default: "color").
    public init(
        stripPrefixes: [String] = [],
        style: NameStyle = .pascalCase,
        prefix: String = "color"
    ) {
        nameTransformer = ThemeAttributeNameTransformer(
            stripPrefixes: stripPrefixes,
            style: style,
            prefix: prefix
        )
    }

    /// Creates a theme attributes exporter with a pre-configured transformer.
    ///
    /// - Parameter transformer: The name transformer to use.
    public init(transformer: ThemeAttributeNameTransformer) {
        nameTransformer = transformer
    }

    /// Exports theme attributes from color pairs.
    ///
    /// Generates content for both `attrs.xml` and `styles.xml` files.
    /// The colors are sorted alphabetically by their theme attribute name.
    ///
    /// - Parameter colorPairs: Color pairs to export (light colors are used for names).
    /// - Returns: Export result containing generated content for both files.
    public func export(colorPairs: [AssetPair<Color>]) -> ThemeAttributesExportResult {
        var attributeMap: OrderedDictionary<String, String> = [:]
        var collisions: [ThemeAttributeCollision] = []
        var attrLines: [String] = []
        var styleLines: [String] = []

        // Process each color pair
        for colorPair in colorPairs {
            let xmlName = colorPair.light.name
            let attrName = nameTransformer.transform(xmlName)

            // Check for collision (duplicate attribute name)
            if let existingXmlName = attributeMap[attrName] {
                collisions.append(ThemeAttributeCollision(
                    attributeName: attrName,
                    keptXmlName: existingXmlName,
                    discardedXmlName: xmlName
                ))
                continue // Skip duplicate
            }

            attributeMap[attrName] = xmlName

            // attrs.xml line: <attr name="colorXxx" format="color" />
            attrLines.append("\(attrIndent)<attr name=\"\(attrName)\" format=\"color\" />")

            // styles.xml line: <item name="colorXxx">@color/xxx</item>
            styleLines.append("\(itemIndent)<item name=\"\(attrName)\">@color/\(xmlName)</item>")
        }

        // Sort by attribute name for consistent output
        let sortedAttrLines = attrLines.sorted()
        let sortedStyleLines = styleLines.sorted()

        return ThemeAttributesExportResult(
            attrsContent: sortedAttrLines.joined(separator: "\n"),
            stylesContent: sortedStyleLines.joined(separator: "\n"),
            attributeMap: attributeMap,
            collisions: collisions
        )
    }
}
