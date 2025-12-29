// swiftlint:disable file_length
import ExFigCore
import ExFigKit
import Foundation
import SwiftUI

// MARK: - Config Error

/// Errors that can occur when building export configuration.
enum ConfigError: LocalizedError {
    case invalidConfiguration([String])
    case missingOutputDirectory
    case paramsEncodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(errors):
            "Invalid configuration: \(errors.joined(separator: ", "))"
        case .missingOutputDirectory:
            "Output directory must be specified"
        case let .paramsEncodingFailed(error):
            "Failed to encode params: \(error.localizedDescription)"
        }
    }
}

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
        case .android: "rectangle.stack"
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
                    enabled: true, name: "CSS File", value: "colors.css",
                    description: "CSS file for colors", type: .path
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

    // Output directory for exports
    var outputDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop")
        .appendingPathComponent("ExFigExport")

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
        lines.append("  lightFileId: \"\(fileKey)\"")
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
        case "figma" where key == "lightFileId":
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

    // MARK: - Build Params

    /// Convert GUI configuration to Params struct for export.
    ///
    /// Uses JSON encoding/decoding to construct Params since the
    /// synthesized memberwise initializers are internal.
    ///
    /// - Parameter outputDirectory: Directory where exported files will be written.
    /// - Returns: Params struct ready for ExportCoordinator.
    /// - Throws: ConfigError if configuration is invalid.
    func buildParams(outputDirectory: URL) throws -> Params {
        guard isValid else {
            throw ConfigError.invalidConfiguration(validationErrors)
        }

        // Build JSON structure that matches Params
        var paramsDict: [String: Any] = [:]

        // Figma config
        paramsDict["figma"] = [
            "lightFileId": fileKey,
        ]

        // Common config
        if !figmaFrameName.isEmpty || !nameValidateRegexp.isEmpty {
            var commonDict: [String: Any] = [:]
            if !figmaFrameName.isEmpty {
                commonDict["icons"] = [
                    "figmaFrameName": figmaFrameName,
                    "nameValidateRegexp": nameValidateRegexp.isEmpty ? nil : nameValidateRegexp,
                    "nameReplaceRegexp": nameReplaceRegexp.isEmpty ? nil : nameReplaceRegexp,
                ].compactMapValues { $0 }
            }
            if !commonDict.isEmpty {
                paramsDict["common"] = commonDict
            }
        }

        // iOS config
        if let iosConfig = buildIOSDict(outputDirectory: outputDirectory) {
            paramsDict["ios"] = iosConfig
        }

        // Android config
        if let androidConfig = buildAndroidDict(outputDirectory: outputDirectory) {
            paramsDict["android"] = androidConfig
        }

        // Flutter config
        if let flutterConfig = buildFlutterDict(outputDirectory: outputDirectory) {
            paramsDict["flutter"] = flutterConfig
        }

        // Web config
        if let webConfig = buildWebDict(outputDirectory: outputDirectory) {
            paramsDict["web"] = webConfig
        }

        // Convert to Params via JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paramsDict)
            return try JSONDecoder().decode(Params.self, from: jsonData)
        } catch {
            throw ConfigError.paramsEncodingFailed(error)
        }
    }

    // MARK: - Config Dict Builders

    private func buildIOSDict(outputDirectory: URL) -> [String: Any]? {
        guard let config = platforms.first(where: { $0.platform == .ios && $0.isEnabled }) else {
            return nil
        }

        let assetsFolder = config.optionValue("assetsfolder") ?? "Assets.xcassets"

        var dict: [String: Any] = [
            "xcodeprojPath": ".",
            "target": "App",
            "xcassetsPath": outputDirectory.appendingPathComponent(assetsFolder).path,
            "xcassetsInMainBundle": true,
        ]

        if config.colorsEnabled {
            let useColorAssets = config.optionBool("usecolorassets", default: true)
            dict["colors"] = [
                "useColorAssets": useColorAssets,
                "assetsFolder": "Colors",
                "nameStyle": nameStyle.yamlValue,
            ].compactMapValues { $0 }
        }

        if config.iconsEnabled {
            dict["icons"] = [
                "format": "pdf",
                "assetsFolder": "Icons",
                "nameStyle": nameStyle.yamlValue,
            ].compactMapValues { $0 }
        }

        if config.imagesEnabled {
            dict["images"] = [
                "assetsFolder": "Illustrations",
                "nameStyle": nameStyle.yamlValue,
                "scales": [1, 2, 3],
            ].compactMapValues { $0 }
        }

        if config.typographyEnabled {
            dict["typography"] = [
                "generateLabels": false,
                "nameStyle": nameStyle.yamlValue,
            ].compactMapValues { $0 }
        }

        return dict
    }

    private func buildAndroidDict(outputDirectory: URL) -> [String: Any]? {
        guard let config = platforms.first(where: { $0.platform == .android && $0.isEnabled }) else {
            return nil
        }

        let resourcesPath = config.optionValue("resourcespath") ?? "app/src/main/res"

        var dict: [String: Any] = [
            "mainRes": outputDirectory.appendingPathComponent(resourcesPath).path,
        ]

        if config.colorsEnabled {
            dict["colors"] = [
                "xmlOutputFileName": config.optionValue("colorsxml") ?? "colors.xml",
            ].compactMapValues { $0 }
        }

        if config.iconsEnabled {
            dict["icons"] = [
                "output": "drawable",
            ]
        }

        if config.imagesEnabled {
            dict["images"] = [
                "output": "drawable",
                "format": "webp",
            ]
        }

        if config.typographyEnabled {
            dict["typography"] = [
                "nameStyle": "snakeCase",
            ]
        }

        return dict
    }

    private func buildFlutterDict(outputDirectory: URL) -> [String: Any]? {
        guard let config = platforms.first(where: { $0.platform == .flutter && $0.isEnabled }) else {
            return nil
        }

        let libPath = config.optionValue("outputpath") ?? "lib/generated"

        var dict: [String: Any] = [
            "output": outputDirectory.appendingPathComponent(libPath).path,
        ]

        if config.colorsEnabled {
            dict["colors"] = [
                "output": "colors.dart",
                "className": config.optionValue("colorsclass") ?? "AppColors",
            ]
        }

        if config.iconsEnabled {
            let assetsPath = config.optionValue("assetspath") ?? "assets/icons"
            dict["icons"] = [
                "output": outputDirectory.appendingPathComponent(assetsPath).path,
            ]
        }

        if config.imagesEnabled {
            let assetsPath = config.optionValue("assetspath") ?? "assets/images"
            dict["images"] = [
                "output": outputDirectory.appendingPathComponent(assetsPath).path,
            ]
        }

        return dict
    }

    private func buildWebDict(outputDirectory: URL) -> [String: Any]? {
        guard let config = platforms.first(where: { $0.platform == .web && $0.isEnabled }) else {
            return nil
        }

        let outputPath = config.optionValue("outputpath") ?? "src/design-tokens"

        var dict: [String: Any] = [
            "output": outputDirectory.appendingPathComponent(outputPath).path,
        ]

        if config.colorsEnabled {
            dict["colors"] = [
                "outputDirectory": "colors",
                "cssFileName": "colors.css",
            ]
        }

        if config.iconsEnabled {
            dict["icons"] = [
                "outputDirectory": "icons",
            ]
        }

        if config.imagesEnabled {
            dict["images"] = [
                "outputDirectory": "images",
            ]
        }

        return dict
    }
}

// MARK: - PlatformConfig Helpers

extension PlatformConfig {
    /// Get option value by normalized name (lowercase, no spaces).
    func optionValue(_ normalizedName: String) -> String? {
        let option = options.first { opt in
            let normalized = opt.name.lowercased().replacingOccurrences(of: " ", with: "")
            return normalized == normalizedName && opt.enabled
        }
        return option?.value
    }

    /// Get boolean option value by normalized name.
    func optionBool(_ normalizedName: String, default defaultValue: Bool = false) -> Bool {
        guard let value = optionValue(normalizedName) else { return defaultValue }
        return value.lowercased() == "true"
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

    /// YAML-compatible value for JSON encoding.
    var yamlValue: String? {
        switch self {
        case .original: nil
        case .camelCase: "camelCase"
        case .snakeCase: "snakeCase"
        case .kebabCase: "kebabCase"
        }
    }

    /// Convert to ExFigCore.NameStyle for direct use.
    var paramsNameStyle: ExFigCore.NameStyle? {
        switch self {
        case .original: nil
        case .camelCase: .camelCase
        case .snakeCase: .snakeCase
        case .kebabCase: .kebabCase
        }
    }
}
