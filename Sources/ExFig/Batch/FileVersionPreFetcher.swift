import FigmaAPI
import Foundation

/// Configuration for pre-fetch operation.
struct PreFetchConfiguration {
    let configs: [ConfigFile]
    let cacheEnabled: Bool
    let noCacheFlag: Bool
    let verbose: Bool
    let rateLimiter: SharedRateLimiter
    let retryPolicy: RetryPolicy
}

/// Pre-fetches file metadata for multiple Figma files in parallel.
///
/// Used by batch processing to fetch all unique file versions upfront,
/// avoiding redundant API calls when multiple configs reference the same files.
struct FileVersionPreFetcher: Sendable {
    let client: Client
    let ui: TerminalUI

    // MARK: - Static Factory

    /// Pre-fetches file versions for all unique file IDs if cache is enabled.
    ///
    /// This optimization fetches file metadata once per unique fileId before parallel
    /// config processing, avoiding redundant API calls when multiple configs reference
    /// the same Figma files.
    ///
    /// - Parameters:
    ///   - configuration: Pre-fetch configuration.
    ///   - ui: Terminal UI for progress output.
    /// - Returns: PreFetchedFileVersions if successful, nil otherwise.
    static func preFetchIfNeeded(
        configuration: PreFetchConfiguration,
        ui: TerminalUI
    ) async -> PreFetchedFileVersions? {
        // Only pre-fetch when cache is enabled
        guard configuration.cacheEnabled, !configuration.noCacheFlag else {
            return nil
        }

        // Extract unique file IDs from all configs
        let extractor = FileIdExtractor()
        let configURLs = configuration.configs.map(\.url)
        let uniqueFileIds = extractor.extractUniqueFileIds(from: configURLs)

        guard !uniqueFileIds.isEmpty else {
            return nil
        }

        if configuration.verbose {
            ui.info("Found \(uniqueFileIds.count) unique Figma file(s) to pre-fetch")
        }

        // Get access token
        guard let token = ProcessInfo.processInfo.environment["FIGMA_PERSONAL_TOKEN"] else {
            // Token missing, let individual configs handle this error
            return nil
        }

        // Create rate-limited client for pre-fetch
        let baseClient = FigmaClient(accessToken: token, timeout: nil)
        let client = RateLimitedClient(
            client: baseClient,
            rateLimiter: configuration.rateLimiter,
            configID: ConfigID("prefetch"),
            retryPolicy: configuration.retryPolicy
        )

        // Pre-fetch file versions
        let preFetcher = FileVersionPreFetcher(client: client, ui: ui)
        do {
            return try await preFetcher.preFetch(fileIds: uniqueFileIds)
        } catch {
            // Pre-fetch failed, proceed without optimization
            // Individual configs will fetch their own metadata
            if configuration.verbose {
                ui.warning("Pre-fetch failed: \(error.localizedDescription)")
            }
            return nil
        }
    }

    // MARK: - Instance Methods

    /// Pre-fetch file metadata for all unique file IDs.
    ///
    /// - Parameter fileIds: Set of unique file IDs to fetch.
    /// - Returns: PreFetchedFileVersions containing all successfully fetched metadata.
    /// - Throws: Error if all fetches fail. Partial failures are handled gracefully.
    func preFetch(fileIds: Set<String>) async throws -> PreFetchedFileVersions {
        guard !fileIds.isEmpty else {
            return PreFetchedFileVersions(versions: [:])
        }

        let fileIdArray = Array(fileIds)

        let result = try await ui.withSpinner(
            "Pre-fetching file versions (\(fileIdArray.count) unique files)..."
        ) {
            try await fetchAllMetadata(fileIds: fileIdArray)
        }

        // Report partial failures if any
        let failedCount = fileIdArray.count - result.count
        if failedCount > 0 {
            ui.warning(.preFetchPartialFailure(failed: failedCount, total: fileIdArray.count))
        }

        return result
    }

    /// Fetch metadata for all file IDs in parallel.
    private func fetchAllMetadata(fileIds: [String]) async throws -> PreFetchedFileVersions {
        try await withThrowingTaskGroup(of: (String, FileMetadata?).self) { group in
            for fileId in fileIds {
                group.addTask { [client] in
                    do {
                        let endpoint = FileMetadataEndpoint(fileId: fileId)
                        let metadata = try await client.request(endpoint)
                        return (fileId, metadata)
                    } catch {
                        // Individual file fetch failed, return nil
                        // Will be handled as partial failure
                        return (fileId, nil)
                    }
                }
            }

            var versions: [String: FileMetadata] = [:]
            for try await (fileId, metadata) in group {
                if let metadata {
                    versions[fileId] = metadata
                }
            }

            // If all fetches failed, throw error
            if versions.isEmpty, !fileIds.isEmpty {
                throw PreFetchError.allFetchesFailed(count: fileIds.count)
            }

            return PreFetchedFileVersions(versions: versions)
        }
    }
}

// MARK: - Errors

/// Errors that can occur during pre-fetching.
enum PreFetchError: Error, LocalizedError {
    /// All file metadata fetches failed.
    case allFetchesFailed(count: Int)

    var errorDescription: String? {
        switch self {
        case let .allFetchesFailed(count):
            "Failed to pre-fetch all \(count) file versions"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .allFetchesFailed:
            "Check your FIGMA_PERSONAL_TOKEN and network connection"
        }
    }
}
