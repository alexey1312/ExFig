import ExFigKit
import Foundation
import SwiftUI

// MARK: - Platform Type

/// Supported export platforms.
enum Platform: String, CaseIterable, Identifiable {
    case ios = "iOS"
    case android = "Android"
    case flutter = "Flutter"
    case web = "Web"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .ios: "apple.logo"
        case .android: "android.logo" // This doesn't exist, we'll use a generic one
        case .flutter: "f.circle"
        case .web: "globe"
        }
    }

    var iconName: String {
        switch self {
        case .ios: "apple.logo"
        case .android: "rectangle.stack"
        case .flutter: "f.circle"
        case .web: "globe"
        }
    }
}

// MARK: - Export Option

/// Configuration for a single export option.
struct ExportOption: Identifiable {
    let id = UUID()
    var enabled: Bool
    var name: String
    var value: String
    var description: String
    var type: OptionType

    enum OptionType {
        case text
        case path
        case toggle
        case picker([String])
    }
}

// MARK: - Platform Config

/// Configuration for a single platform.
struct PlatformConfig: Identifiable {
    let id = UUID()
    let platform: Platform
    var isEnabled: Bool
    var colorsEnabled: Bool
    var iconsEnabled: Bool
    var imagesEnabled: Bool
    var typographyEnabled: Bool

    // Platform-specific options
    var options: [ExportOption]

    static func defaultConfig(for platform: Platform) -> PlatformConfig {
        switch platform {
        case .ios: defaultIOSConfig()
        case .android: defaultAndroidConfig()
        case .flutter: defaultFlutterConfig()
        case .web: defaultWebConfig()
        }
    }

    private static func defaultIOSConfig() -> PlatformConfig {
        PlatformConfig(
            platform: .ios,
            isEnabled: false,
            colorsEnabled: true,
            iconsEnabled: true,
            imagesEnabled: true,
            typographyEnabled: true,
            options: [
                ExportOption(
                    enabled: true, name: "Assets Folder", value: "Assets.xcassets",
                    description: "Path to the .xcassets folder", type: .path
                ),
                ExportOption(
                    enabled: true, name: "Use Color Assets", value: "true",
                    description: "Generate color assets instead of code", type: .toggle
                ),
                ExportOption(
                    enabled: true, name: "Swift Extension", value: "UIColor+Generated.swift",
                    description: "Swift file for color extensions", type: .path
                ),
                ExportOption(
                    enabled: false, name: "SwiftUI Extension", value: "Color+Generated.swift",
                    description: "SwiftUI Color extension file", type: .path
                ),
            ]
        )
    }

    private static func defaultAndroidConfig() -> PlatformConfig {
        PlatformConfig(
            platform: .android,
            isEnabled: false,
            colorsEnabled: true,
            iconsEnabled: true,
            imagesEnabled: true,
            typographyEnabled: true,
            options: [
                ExportOption(
                    enabled: true, name: "Resources Path", value: "app/src/main/res",
                    description: "Path to Android resources folder", type: .path
                ),
                ExportOption(
                    enabled: true, name: "Colors XML", value: "colors.xml",
                    description: "Colors XML file name", type: .text
                ),
                ExportOption(
                    enabled: false, name: "Compose Package", value: "com.example.ui.theme",
                    description: "Package name for Compose colors", type: .text
                ),
                ExportOption(
                    enabled: true, name: "Vector Drawables", value: "true",
                    description: "Generate vector drawables for icons", type: .toggle
                ),
            ]
        )
    }

    private static func defaultFlutterConfig() -> PlatformConfig {
        PlatformConfig(
            platform: .flutter,
            isEnabled: false,
            colorsEnabled: true,
            iconsEnabled: true,
            imagesEnabled: true,
            typographyEnabled: true,
            options: [
                ExportOption(
                    enabled: true, name: "Output Path", value: "lib/generated",
                    description: "Path for generated Dart files", type: .path
                ),
                ExportOption(
                    enabled: true, name: "Colors Class", value: "AppColors",
                    description: "Class name for colors", type: .text
                ),
                ExportOption(
                    enabled: true, name: "Assets Path", value: "assets/images",
                    description: "Path for image assets", type: .path
                ),
            ]
        )
    }

    private static func defaultWebConfig() -> PlatformConfig {
        PlatformConfig(
            platform: .web,
            isEnabled: false,
            colorsEnabled: true,
            iconsEnabled: true,
            imagesEnabled: true,
            typographyEnabled: false,
            options: [
                ExportOption(
                    enabled: true, name: "Output Path", value: "src/design-tokens",
                    description: "Path for design tokens", type: .path
                ),
                ExportOption(
                    enabled: true, name: "Format", value: "css",
                    description: "Output format for design tokens", type: .picker(["css", "scss", "json", "js"])
                ),
                ExportOption(
                    enabled: true, name: "Icons Format", value: "svg",
                    description: "Format for icon exports", type: .picker(["svg", "png", "webp"])
                ),
            ]
        )
    }
}

// MARK: - Config View Model

/// View model for the configuration editor.
@MainActor
@Observable
final class ConfigViewModel {
    // MARK: - State

    var fileKey: String = ""
    var figmaFrameName: String = "Icons"
    var platforms: [PlatformConfig] = Platform.allCases.map { PlatformConfig.defaultConfig(for: $0) }

    // Common options
    var nameValidateRegexp: String = ""
    var nameReplaceRegexp: String = ""
    var nameStyle: NameStyle = .original

    // Validation
    var validationErrors: [String] = []

    // MARK: - Computed Properties

    var enabledPlatforms: [PlatformConfig] {
        platforms.filter(\.isEnabled)
    }

    var isValid: Bool {
        validate()
        return validationErrors.isEmpty
    }

    // MARK: - Validation

    @discardableResult
    func validate() -> Bool {
        validationErrors = []

        if fileKey.isEmpty {
            validationErrors.append("Figma file key is required")
        }

        if enabledPlatforms.isEmpty {
            validationErrors.append("At least one platform must be enabled")
        }

        for platform in enabledPlatforms {
            let assetEnabled = platform.colorsEnabled || platform.iconsEnabled
                || platform.imagesEnabled || platform.typographyEnabled

            if !assetEnabled {
                validationErrors.append("\(platform.platform.rawValue): At least one asset type must be enabled")
            }
        }

        return validationErrors.isEmpty
    }

    // MARK: - Import/Export YAML

    /// Export current configuration to YAML string.
    func exportToYAML() -> String {
        var lines: [String] = []

        // Figma configuration
        lines.append("figma:")
        lines.append("  fileId: \"\(fileKey)\"")
        lines.append("")

        // Common configuration
        if !figmaFrameName.isEmpty || !nameValidateRegexp.isEmpty || !nameReplaceRegexp.isEmpty {
            lines.append("common:")
            if !figmaFrameName.isEmpty {
                lines.append("  icons:")
                lines.append("    figmaFrameName: \"\(figmaFrameName)\"")
            }
            lines.append("")
        }

        // Platform configurations
        for platform in enabledPlatforms {
            lines.append("\(platform.platform.rawValue.lowercased()):")

            for option in platform.options where option.enabled {
                let key = option.name.lowercased().replacingOccurrences(of: " ", with: "")
                switch option.type {
                case .toggle:
                    lines.append("  \(key): \(option.value)")
                default:
                    lines.append("  \(key): \"\(option.value)\"")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Import configuration from YAML string.
    func importFromYAML(_ yaml: String) throws {
        let lines = yaml.components(separatedBy: .newlines)
        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !shouldSkipLine(trimmed) else { continue }

            if let section = parseSectionHeader(trimmed) {
                currentSection = section
                continue
            }

            if let (key, value) = parseKeyValue(trimmed) {
                applyValue(key: key, value: value, section: currentSection)
            }
        }
    }

    private func shouldSkipLine(_ line: String) -> Bool {
        line.isEmpty || line.hasPrefix("#")
    }

    private func parseSectionHeader(_ line: String) -> String? {
        guard !line.hasPrefix("-"), line.hasSuffix(":") else { return nil }
        return String(line.dropLast()).trimmingCharacters(in: .whitespaces)
    }

    private func parseKeyValue(_ line: String) -> (key: String, value: String)? {
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        var value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("\""), value.hasSuffix("\"") {
            value = String(value.dropFirst().dropLast())
        }
        return (key, value)
    }

    private func applyValue(key: String, value: String, section: String) {
        switch section {
        case "figma" where key == "fileId":
            fileKey = value
        case "common" where key == "figmaFrameName":
            figmaFrameName = value
        default:
            enablePlatformIfMatches(section: section)
        }
    }

    private func enablePlatformIfMatches(section: String) {
        if let index = platforms.firstIndex(where: { $0.platform.rawValue.lowercased() == section }) {
            platforms[index].isEnabled = true
        }
    }

    // MARK: - Platform Management

    func togglePlatform(_ platform: Platform) {
        if let index = platforms.firstIndex(where: { $0.platform == platform }) {
            platforms[index].isEnabled.toggle()
        }
    }
}

// MARK: - Name Style

/// Naming style for generated assets.
enum NameStyle: String, CaseIterable, Identifiable {
    case original = "Original"
    case camelCase
    case snakeCase = "snake_case"
    case kebabCase = "kebab-case"

    var id: String { rawValue }
}
