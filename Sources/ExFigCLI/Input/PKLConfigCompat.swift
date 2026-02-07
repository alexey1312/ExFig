import ExFigConfig
import Foundation

// MARK: - PKLConfig Type Alias

/// Backward-compatible type alias for the old `PKLConfig` type.
/// Maps to `ExFig.ModuleImpl` from the pkl-swift generated code.
typealias PKLConfig = ExFig.ModuleImpl

// MARK: - Nested Type Aliases

/// Provides `PKLConfig.Figma`, `PKLConfig.Common`, etc. namespacing
/// for backward compatibility with code that used the old PKLConfig struct.
extension ExFig.ModuleImpl {
    typealias Figma = ExFigConfig.Figma.FigmaConfig
    typealias Common = ExFigConfig.Common.CommonConfig
    typealias iOS = ExFigConfig.iOS.iOSConfig
    typealias Android = ExFigConfig.Android.AndroidConfig
    typealias Flutter = ExFigConfig.Flutter.FlutterConfig
    typealias Web = ExFigConfig.Web.WebConfig
}

// MARK: - Common Nested Type Aliases

extension Common.CommonConfig {
    typealias VariablesColors = ExFigConfig.Common.VariablesColors
    typealias Cache = ExFigConfig.Common.Cache
    typealias Colors = ExFigConfig.Common.Colors
    typealias Icons = ExFigConfig.Common.Icons
    typealias Images = ExFigConfig.Common.Images
}

// MARK: - Cache Computed Properties

extension Common.Cache {
    /// Backward-compatible property. The generated type uses `enabled`,
    /// but old code referenced `isEnabled`.
    var isEnabled: Bool {
        enabled ?? false
    }
}

// MARK: - ColorsConfiguration Compatibility

// The old PKLConfig had `ColorsConfiguration` wrapper types with `.entries` and `.isMultiple`.
// Now colors are `[ColorsEntry]?` directly. These extensions on the platform config types
// provide backward-compatible access patterns.

extension iOS.iOSConfig {
    /// Backward-compatible wrapper for colors configuration.
    struct ColorsConfiguration {
        let entries: [iOS.ColorsEntry]
        var isMultiple: Bool {
            entries.count > 1
        }
    }

    /// Returns a backward-compatible ColorsConfiguration wrapper if colors are defined.
    var colorsConfiguration: ColorsConfiguration? {
        colors.map { ColorsConfiguration(entries: $0) }
    }
}

extension Android.AndroidConfig {
    /// Backward-compatible wrapper for colors configuration.
    struct ColorsConfiguration {
        let entries: [Android.ColorsEntry]
        var isMultiple: Bool {
            entries.count > 1
        }
    }

    /// Returns a backward-compatible ColorsConfiguration wrapper if colors are defined.
    var colorsConfiguration: ColorsConfiguration? {
        colors.map { ColorsConfiguration(entries: $0) }
    }
}

extension Flutter.FlutterConfig {
    /// Backward-compatible wrapper for colors configuration.
    struct ColorsConfiguration {
        let entries: [Flutter.ColorsEntry]
        var isMultiple: Bool {
            entries.count > 1
        }
    }

    /// Returns a backward-compatible ColorsConfiguration wrapper if colors are defined.
    var colorsConfiguration: ColorsConfiguration? {
        colors.map { ColorsConfiguration(entries: $0) }
    }
}

extension Web.WebConfig {
    /// Backward-compatible wrapper for colors configuration.
    struct ColorsConfiguration {
        let entries: [Web.ColorsEntry]
        var isMultiple: Bool {
            entries.count > 1
        }
    }

    /// Returns a backward-compatible ColorsConfiguration wrapper if colors are defined.
    var colorsConfiguration: ColorsConfiguration? {
        colors.map { ColorsConfiguration(entries: $0) }
    }
}

// MARK: - Icons/Images Configuration Compatibility

extension iOS.iOSConfig {
    /// Backward-compatible wrapper for icons configuration.
    struct IconsConfiguration {
        let entries: [iOS.IconsEntry]
    }

    /// Returns a backward-compatible IconsConfiguration wrapper if icons are defined.
    var iconsConfiguration: IconsConfiguration? {
        icons.map { IconsConfiguration(entries: $0) }
    }
}

extension Android.AndroidConfig {
    /// Backward-compatible wrapper for icons configuration.
    struct IconsConfiguration {
        let entries: [Android.IconsEntry]
    }

    /// Returns a backward-compatible IconsConfiguration wrapper if icons are defined.
    var iconsConfiguration: IconsConfiguration? {
        icons.map { IconsConfiguration(entries: $0) }
    }
}

extension Flutter.FlutterConfig {
    /// Backward-compatible wrapper for icons configuration.
    struct IconsConfiguration {
        let entries: [Flutter.IconsEntry]
    }

    /// Returns a backward-compatible IconsConfiguration wrapper if icons are defined.
    var iconsConfiguration: IconsConfiguration? {
        icons.map { IconsConfiguration(entries: $0) }
    }
}

extension Web.WebConfig {
    /// Backward-compatible wrapper for icons configuration.
    struct IconsConfiguration {
        let entries: [Web.IconsEntry]
    }

    /// Returns a backward-compatible IconsConfiguration wrapper if icons are defined.
    var iconsConfiguration: IconsConfiguration? {
        icons.map { IconsConfiguration(entries: $0) }
    }
}

// MARK: - URL Bridging for iOS

extension iOS.iOSConfig {
    /// xcassetsPath as URL (backward compat - old PKLConfig stored as URL).
    var xcassetsPathURL: URL? {
        xcassetsPath.map { URL(fileURLWithPath: $0) }
    }

    /// templatesPath as URL.
    var templatesPathURL: URL? {
        templatesPath.map { URL(fileURLWithPath: $0) }
    }
}

// MARK: - URL Bridging for Android

extension Android.AndroidConfig {
    /// mainRes as URL (backward compat - old PKLConfig stored as URL).
    var mainResURL: URL {
        URL(fileURLWithPath: mainRes)
    }

    /// mainSrc as URL.
    var mainSrcURL: URL? {
        mainSrc.map { URL(fileURLWithPath: $0) }
    }

    /// templatesPath as URL.
    var templatesPathURL: URL? {
        templatesPath.map { URL(fileURLWithPath: $0) }
    }
}

// MARK: - URL Bridging for Flutter

extension Flutter.FlutterConfig {
    /// output as URL (backward compat - old PKLConfig stored as URL).
    var outputURL: URL {
        URL(fileURLWithPath: output)
    }

    /// templatesPath as URL.
    var templatesPathURL: URL? {
        templatesPath.map { URL(fileURLWithPath: $0) }
    }
}

// MARK: - URL Bridging for Web

extension Web.WebConfig {
    /// output as URL (backward compat - old PKLConfig stored as URL).
    var outputURL: URL {
        URL(fileURLWithPath: output)
    }

    /// templatesPath as URL.
    var templatesPathURL: URL? {
        templatesPath.map { URL(fileURLWithPath: $0) }
    }
}

// MARK: - ThemeAttributes Compatibility

extension Android.ThemeAttributes {
    /// Backward-compatible property. The generated type uses `enabled`.
    var isEnabled: Bool {
        enabled ?? false
    }
}
