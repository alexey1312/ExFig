import Foundation

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
    func extractUniqueFileIds(from configURLs: [URL]) -> Set<String> {
        var fileIds = Set<String>()

        for configURL in configURLs {
            if let params = parseParams(from: configURL) {
                fileIds.formUnion(params.getFileIds())
            }
        }

        return fileIds
    }

    /// Parse Params from a PKL config file URL.
    ///
    /// - Parameter url: URL to the config file.
    /// - Returns: Parsed Params or nil if parsing fails.
    private func parseParams(from url: URL) -> Params? {
        do {
            let evaluator = try PKLEvaluator()

            // Run async evaluation synchronously
            let semaphore = DispatchSemaphore(value: 0)
            var result: Params?

            Task {
                result = try? await evaluator.evaluateToParams(configPath: url)
                semaphore.signal()
            }

            semaphore.wait()
            return result
        } catch {
            // PKL evaluation failed, skip this file
            // The actual batch processing will report this error later
            return nil
        }
    }
}
