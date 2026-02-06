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
    func extractUniqueFileIds(from configURLs: [URL]) -> Set<String> {
        var fileIds = Set<String>()

        for configURL in configURLs {
            if let params = parseParams(from: configURL) {
                fileIds.formUnion(params.getFileIds())
            }
        }

        return fileIds
    }

    /// Parse PKLConfig from a PKL config file URL.
    ///
    /// - Parameter url: URL to the config file.
    /// - Returns: Parsed PKLConfig or nil if parsing fails.
    private func parseParams(from url: URL) -> PKLConfig? {
        do {
            let evaluator = try PKLEvaluator()

            // Run async evaluation synchronously
            // Semaphore ensures sequential access, so @unchecked Sendable is safe
            let semaphore = DispatchSemaphore(value: 0)
            let box = SendableBox<PKLConfig?>(nil)

            Task {
                defer { semaphore.signal() }
                do {
                    box.value = try await evaluator.evaluateToPKLConfig(configPath: url)
                } catch {
                    ExFigCommand.logger.warning(
                        "Failed to parse config \(url.lastPathComponent): \(error.localizedDescription)"
                    )
                }
            }

            semaphore.wait()
            return box.value
        } catch {
            ExFigCommand.logger.warning(
                "Failed to create PKL evaluator for \(url.lastPathComponent): \(error.localizedDescription)"
            )
            return nil
        }
    }
}
