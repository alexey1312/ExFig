import ExFigConfig
import Foundation
import Logging

/// Extracts unique Figma file IDs from config files.
///
/// Used by batch processing to collect all unique file IDs before pre-fetching
/// their metadata. This allows a single API call per unique file instead of
/// one per config.
struct FileIdExtractor {
    /// Extract all unique file IDs from a list of config URLs.
    ///
    /// Parses each config file and extracts all file IDs using the `FileIdProvider` protocol:
    /// - `figma.lightFileId` (required)
    /// - `figma.darkFileId` (optional)
    /// - `figma.lightHighContrastFileId` (optional)
    /// - `figma.darkHighContrastFileId` (optional)
    /// - `common.variablesColors.tokensFileId` (optional)
    /// - Multi-entry colors `tokensFileId` for all platforms (optional)
    ///
    /// - Parameter configURLs: URLs to config files.
    /// - Returns: Set of unique file IDs found across all configs.
    func extractUniqueFileIds(from configURLs: [URL]) async -> Set<String> {
        var fileIds = Set<String>()

        for configURL in configURLs {
            do {
                let module: ExFig.ModuleImpl = try await PKLEvaluator.evaluate(configPath: configURL)
                fileIds.formUnion(module.getFileIds())
            } catch {
                let name = configURL.lastPathComponent
                let reason = error.localizedDescription
                ExFigCommand.logger.error(
                    """
                    Pre-fetch optimization: Failed to parse config \(name): \(reason). \
                    File IDs from this config will not be pre-fetched.
                    """
                )
            }
        }

        return fileIds
    }
}
