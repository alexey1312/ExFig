// swiftlint:disable file_length

import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation
import MCP
import YYJSON

/// Dispatches MCP CallTool requests to ExFig logic.
enum MCPToolHandlers {
    static func handle(params: CallTool.Parameters, state: MCPServerState) async -> CallTool.Result {
        do {
            switch params.name {
            case "exfig_validate":
                return try await handleValidate(params: params)
            case "exfig_tokens_info":
                return try await handleTokensInfo(params: params)
            case "exfig_inspect":
                return try await handleInspect(params: params, state: state)
            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        } catch let error as ExFigError {
            return errorResult(error)
        } catch let error as TokensFileError {
            return .init(
                content: [.text("Token file error: \(error.errorDescription ?? "\(error)")")],
                isError: true
            )
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    // MARK: - Validate

    private static func handleValidate(params: CallTool.Parameters) async throws -> CallTool.Result {
        let configPath = try resolveConfigPath(from: params.arguments?["config_path"]?.stringValue)
        let configURL = URL(fileURLWithPath: configPath)

        let config = try await PKLEvaluator.evaluate(configPath: configURL)

        let platforms = buildPlatformSummary(config: config)
        let fileIDs = Array(config.getFileIds()).sorted()

        let summary = ValidateSummary(
            configPath: configPath,
            valid: true,
            platforms: platforms.isEmpty ? nil : platforms,
            figmaFileIds: fileIDs.isEmpty ? nil : fileIDs
        )

        return .init(content: [.text(encodeJSON(summary))])
    }

    private static func buildPlatformSummary(config: PKLConfig) -> [String: EntrySummary] {
        var platforms: [String: EntrySummary] = [:]

        if let ios = config.ios {
            platforms["ios"] = EntrySummary(
                colorsEntries: ios.colors?.count, iconsEntries: ios.icons?.count,
                imagesEntries: ios.images?.count, typography: ios.typography != nil ? true : nil
            )
        }
        if let android = config.android {
            platforms["android"] = EntrySummary(
                colorsEntries: android.colors?.count, iconsEntries: android.icons?.count,
                imagesEntries: android.images?.count, typography: android.typography != nil ? true : nil
            )
        }
        if let flutter = config.flutter {
            platforms["flutter"] = EntrySummary(
                colorsEntries: flutter.colors?.count, iconsEntries: flutter.icons?.count,
                imagesEntries: flutter.images?.count
            )
        }
        if let web = config.web {
            platforms["web"] = EntrySummary(
                colorsEntries: web.colors?.count, iconsEntries: web.icons?.count,
                imagesEntries: web.images?.count
            )
        }

        return platforms
    }

    // MARK: - Tokens Info

    private static func handleTokensInfo(params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let filePath = params.arguments?["file_path"]?.stringValue else {
            return .init(content: [.text("Missing required parameter: file_path")], isError: true)
        }

        var source = try TokensFileSource.parse(fileAt: filePath)
        try source.resolveAliases()

        var countsByType: [String: Int]?
        let byType = source.tokenCountsByType()
        if !byType.isEmpty {
            var typeCounts: [String: Int] = [:]
            for entry in byType {
                typeCounts[entry.type] = entry.count
            }
            countsByType = typeCounts
        }

        var topLevelGroups: [String: Int]?
        let groups = source.topLevelGroups()
        if !groups.isEmpty {
            var groupCounts: [String: Int] = [:]
            for entry in groups {
                groupCounts[entry.name] = entry.count
            }
            topLevelGroups = groupCounts
        }

        let result = TokensInfoResult(
            filePath: filePath,
            totalTokens: source.tokens.count,
            aliasCount: source.aliasCount,
            countsByType: countsByType,
            topLevelGroups: topLevelGroups,
            warnings: source.warnings.isEmpty ? nil : source.warnings
        )

        return .init(content: [.text(encodeJSON(result))])
    }

    // MARK: - Inspect

    private static func handleInspect(
        params: CallTool.Parameters,
        state: MCPServerState
    ) async throws -> CallTool.Result {
        // Validate inputs before expensive operations (PKL eval, API client)
        guard let resourceType = params.arguments?["resource_type"]?.stringValue else {
            return .init(content: [.text("Missing required parameter: resource_type")], isError: true)
        }

        let configPath = try resolveConfigPath(from: params.arguments?["config_path"]?.stringValue)
        let configURL = URL(fileURLWithPath: configPath)
        let config = try await PKLEvaluator.evaluate(configPath: configURL)
        let client = try await state.getClient()

        let types = resourceType == "all"
            ? ["colors", "icons", "images", "typography"]
            : [resourceType]

        var results = InspectResult(configPath: configPath)

        for type in types {
            switch type {
            case "colors":
                results.colors = try await inspectColors(config: config, client: client)
            case "icons":
                results.icons = try await inspectIcons(config: config, client: client)
            case "images":
                results.images = try await inspectImages(config: config, client: client)
            case "typography":
                results.typography = try await inspectTypography(config: config, client: client)
            default:
                results.unknownTypes[type] = "Unknown resource type: \(type)"
            }
        }

        return .init(content: [.text(encodeJSON(results))])
    }

    // MARK: - Inspect Helpers

    private static func requireFileId(config: PKLConfig) throws -> String {
        guard let fileId = config.figma?.lightFileId else {
            throw ExFigError.custom(
                errorString: "No Figma file ID configured. Set figma.lightFileId in config."
            )
        }
        return fileId
    }

    private static func inspectColors(
        config: PKLConfig,
        client: FigmaAPI.Client
    ) async throws -> ColorsInspectResult {
        let fileId = try requireFileId(config: config)
        let styles = try await client.request(StylesEndpoint(fileId: fileId))
        let colorStyles = styles.filter { $0.styleType == .fill }

        var entriesPerPlatform: [String: Int]?
        var entries: [String: Int] = [:]
        if let c = config.ios?.colors { entries["ios"] = c.count }
        if let c = config.android?.colors { entries["android"] = c.count }
        if let c = config.flutter?.colors { entries["flutter"] = c.count }
        if let c = config.web?.colors { entries["web"] = c.count }
        if !entries.isEmpty { entriesPerPlatform = entries }

        return ColorsInspectResult(
            fileId: fileId,
            stylesCount: styles.count,
            colorStylesCount: colorStyles.count,
            sampleNames: colorStyles.isEmpty ? nil : Array(colorStyles.prefix(20).map(\.name)),
            truncated: colorStyles.count > 20 ? true : nil,
            entriesPerPlatform: entriesPerPlatform
        )
    }

    private static func inspectIcons(
        config: PKLConfig,
        client: FigmaAPI.Client
    ) async throws -> ComponentsInspectResult {
        let fileId = try requireFileId(config: config)
        let components = try await client.request(ComponentsEndpoint(fileId: fileId))

        return ComponentsInspectResult(
            fileId: fileId,
            componentsCount: components.count,
            sampleNames: components.isEmpty ? nil : Array(components.prefix(20).map(\.name)),
            truncated: components.count > 20 ? true : nil
        )
    }

    private static func inspectImages(
        config: PKLConfig,
        client: FigmaAPI.Client
    ) async throws -> FileInspectResult {
        let fileId = try requireFileId(config: config)
        let metadata = try await client.request(FileMetadataEndpoint(fileId: fileId))

        return FileInspectResult(
            fileId: fileId,
            fileName: metadata.name,
            lastModified: metadata.lastModified,
            version: metadata.version
        )
    }

    private static func inspectTypography(
        config: PKLConfig,
        client: FigmaAPI.Client
    ) async throws -> TypographyInspectResult {
        let fileId = try requireFileId(config: config)
        let styles = try await client.request(StylesEndpoint(fileId: fileId))
        let textStyles = styles.filter { $0.styleType == .text }

        return TypographyInspectResult(
            fileId: fileId,
            textStylesCount: textStyles.count,
            sampleNames: textStyles.isEmpty ? nil : Array(textStyles.prefix(20).map(\.name)),
            truncated: textStyles.count > 20 ? true : nil
        )
    }

    // MARK: - Helpers

    private static func resolveConfigPath(from argument: String?) throws -> String {
        if let path = argument {
            guard FileManager.default.fileExists(atPath: path) else {
                throw ExFigError.custom(errorString: "Config file not found: \(path)")
            }
            return path
        }

        for filename in ExFigOptions.defaultConfigFiles
            where FileManager.default.fileExists(atPath: filename)
        {
            return filename
        }

        throw ExFigError.custom(
            errorString: "No exfig.pkl found in current directory. Specify config_path parameter."
        )
    }

    private static func errorResult(_ error: ExFigError) -> CallTool.Result {
        var message = error.errorDescription ?? "\(error)"
        if let recovery = error.recoverySuggestion {
            message += "\n\nSuggestion: \(recovery)"
        }
        return .init(content: [.text(message)], isError: true)
    }

    /// Encodes a Codable value as pretty-printed JSON with sorted keys.
    private static func encodeJSON(_ value: some Encodable) -> String {
        guard let data = try? JSONCodec.encodePrettySorted(value) else {
            return "\(value)"
        }
        return String(data: data, encoding: .utf8) ?? "\(value)"
    }
}

// MARK: - Response Types

private struct ValidateSummary: Codable, Sendable {
    let configPath: String
    let valid: Bool
    var platforms: [String: EntrySummary]?
    var figmaFileIds: [String]?

    enum CodingKeys: String, CodingKey {
        case configPath = "config_path"
        case valid
        case platforms
        case figmaFileIds = "figma_file_ids"
    }
}

private struct EntrySummary: Codable, Sendable {
    var colorsEntries: Int?
    var iconsEntries: Int?
    var imagesEntries: Int?
    var typography: Bool?

    enum CodingKeys: String, CodingKey {
        case colorsEntries = "colors_entries"
        case iconsEntries = "icons_entries"
        case imagesEntries = "images_entries"
        case typography
    }
}

private struct TokensInfoResult: Codable, Sendable {
    let filePath: String
    let totalTokens: Int
    let aliasCount: Int
    var countsByType: [String: Int]?
    var topLevelGroups: [String: Int]?
    var warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case totalTokens = "total_tokens"
        case aliasCount = "alias_count"
        case countsByType = "counts_by_type"
        case topLevelGroups = "top_level_groups"
        case warnings
    }
}

private struct InspectResult: Codable, Sendable {
    let configPath: String
    var colors: ColorsInspectResult?
    var icons: ComponentsInspectResult?
    var images: FileInspectResult?
    var typography: TypographyInspectResult?
    var unknownTypes: [String: String] = [:]

    enum CodingKeys: String, CodingKey {
        case configPath = "config_path"
        case colors, icons, images, typography
        case unknownTypes = "unknown_types"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configPath, forKey: .configPath)
        try container.encodeIfPresent(colors, forKey: .colors)
        try container.encodeIfPresent(icons, forKey: .icons)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(typography, forKey: .typography)
        if !unknownTypes.isEmpty {
            try container.encode(unknownTypes, forKey: .unknownTypes)
        }
    }
}

private struct ColorsInspectResult: Codable, Sendable {
    let fileId: String
    let stylesCount: Int
    let colorStylesCount: Int
    var sampleNames: [String]?
    var truncated: Bool?
    var entriesPerPlatform: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case stylesCount = "styles_count"
        case colorStylesCount = "color_styles_count"
        case sampleNames = "sample_names"
        case truncated
        case entriesPerPlatform = "entries_per_platform"
    }
}

private struct ComponentsInspectResult: Codable, Sendable {
    let fileId: String
    let componentsCount: Int
    var sampleNames: [String]?
    var truncated: Bool?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case componentsCount = "components_count"
        case sampleNames = "sample_names"
        case truncated
    }
}

private struct FileInspectResult: Codable, Sendable {
    let fileId: String
    let fileName: String
    let lastModified: String
    let version: String

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case fileName = "file_name"
        case lastModified = "last_modified"
        case version
    }
}

private struct TypographyInspectResult: Codable, Sendable {
    let fileId: String
    let textStylesCount: Int
    var sampleNames: [String]?
    var truncated: Bool?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case textStylesCount = "text_styles_count"
        case sampleNames = "sample_names"
        case truncated
    }
}

// swiftlint:enable file_length
