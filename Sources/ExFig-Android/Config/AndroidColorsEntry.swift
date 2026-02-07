import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias AndroidColorsEntry = Android.ColorsEntry

/// Typealias for generated ThemeAttributes.
public typealias ThemeAttributes = Android.ThemeAttributes

/// Typealias for generated NameTransform.
public typealias NameTransform = Android.NameTransform

// MARK: - ThemeAttributes Convenience

public extension Android.ThemeAttributes {
    var isEnabled: Bool {
        enabled ?? false
    }

    var resolvedMarkerStart: String {
        markerStart ?? "FIGMA COLORS MARKER START"
    }

    var resolvedMarkerEnd: String {
        markerEnd ?? "FIGMA COLORS MARKER END"
    }

    var shouldAutoCreateMarkers: Bool {
        autoCreateMarkers ?? false
    }

    var resolvedAttrsFile: String {
        attrsFile ?? "values/attrs.xml"
    }

    var resolvedStylesFile: String {
        stylesFile ?? "values/styles.xml"
    }

    var resolvedStylesNightFile: String {
        stylesNightFile ?? "values-night/styles.xml"
    }
}

// MARK: - NameTransform Convenience

public extension Android.NameTransform {
    var resolvedStyle: NameStyle {
        guard let style else { return .pascalCase }
        return style.coreNameStyle
    }

    var resolvedPrefix: String {
        prefix ?? "color"
    }

    var resolvedStripPrefixes: [String] {
        stripPrefixes ?? []
    }
}

// MARK: - ColorsEntry Convenience

public extension Android.ColorsEntry {
    /// Path to generate Compose Color Kotlin file as URL.
    var colorKotlinURL: URL? {
        colorKotlin.map { URL(fileURLWithPath: $0) }
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved mainRes path: entry override or platform config fallback.
    func resolvedMainRes(fallback: URL) -> URL {
        mainRes.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved mainSrc path: entry override or platform config fallback.
    func resolvedMainSrc(fallback: URL?) -> URL? {
        mainSrc.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }
}
