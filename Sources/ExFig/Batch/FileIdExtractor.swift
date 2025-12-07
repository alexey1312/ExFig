import Foundation
import Yams

/// Extracts unique Figma file IDs from config files.
///
/// Used by batch processing to collect all unique file IDs before pre-fetching
/// their metadata. This allows a single API call per unique file instead of
/// one per config.
struct FileIdExtractor {
    /// Extract all unique file IDs from a list of config URLs.
    ///
    /// Parses each config file and extracts:
    /// - `figma.lightFileId` (required)
    /// - `figma.darkFileId` (optional)
    /// - `common.variablesColors.tokensFileId` (optional)
    ///
    /// - Parameter configURLs: URLs to config files.
    /// - Returns: Set of unique file IDs found across all configs.
    func extractUniqueFileIds(from configURLs: [URL]) -> Set<String> {
        var fileIds = Set<String>()

        for configURL in configURLs {
            let ids = extractFileIds(from: configURL)
            fileIds.formUnion(ids)
        }

        return fileIds
    }

    /// Extract file IDs from a single config file.
    ///
    /// - Parameter configURL: URL to the config file.
    /// - Returns: Array of file IDs found in this config.
    private func extractFileIds(from configURL: URL) -> [String] {
        do {
            let data = try Data(contentsOf: configURL)
            guard let content = String(data: data, encoding: .utf8) else {
                return []
            }

            let decoder = YAMLDecoder()
            let config = try decoder.decode(PartialConfig.self, from: content)

            var ids: [String] = []

            // Extract figma.lightFileId (required)
            ids.append(config.figma.lightFileId)

            // Extract figma.darkFileId (optional)
            if let darkFileId = config.figma.darkFileId {
                ids.append(darkFileId)
            }

            // Extract common.variablesColors.tokensFileId (optional)
            if let tokensFileId = config.common?.variablesColors?.tokensFileId {
                ids.append(tokensFileId)
            }

            return ids
        } catch {
            // Config parsing failed, skip this file
            // The actual batch processing will report this error later
            return []
        }
    }
}

// MARK: - Partial Config Models

/// Minimal config structure for extracting file IDs.
/// Only decodes the fields we need, ignoring everything else.
private struct PartialConfig: Decodable {
    let figma: FigmaConfig
    let common: CommonConfig?

    struct FigmaConfig: Decodable {
        let lightFileId: String
        let darkFileId: String?
    }

    struct CommonConfig: Decodable {
        let variablesColors: VariablesColorsConfig?
    }

    struct VariablesColorsConfig: Decodable {
        let tokensFileId: String
    }
}
