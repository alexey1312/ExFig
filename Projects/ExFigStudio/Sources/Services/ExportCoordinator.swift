import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import Logging

// MARK: - Export Result

/// Result of an export operation.
struct ExportResult: Sendable {
    let platform: ExFigCore.Platform
    let assetType: AssetType
    let count: Int
    let success: Bool
    let errorMessage: String?

    static func success(platform: ExFigCore.Platform, assetType: AssetType, count: Int) -> ExportResult {
        ExportResult(platform: platform, assetType: assetType, count: count, success: true, errorMessage: nil)
    }

    static func failure(platform: ExFigCore.Platform, assetType: AssetType, error: Error) -> ExportResult {
        ExportResult(
            platform: platform,
            assetType: assetType,
            count: 0,
            success: false,
            errorMessage: error.localizedDescription
        )
    }

    static func skipped(platform: ExFigCore.Platform, assetType: AssetType) -> ExportResult {
        ExportResult(
            platform: platform,
            assetType: assetType,
            count: 0,
            success: true,
            errorMessage: "Not configured"
        )
    }
}

// MARK: - Export Coordinator

/// Actor that coordinates the export process using ExFigKit loaders and platform exporters.
///
/// This coordinator serves as the bridge between the GUI and the CLI export functionality.
/// It uses the same loaders and processors as the CLI but with GUI-specific progress reporting.
actor ExportCoordinator {
    let client: Client
    let progressReporter: ProgressReporter
    let logger: Logger

    init(client: Client, progressReporter: ProgressReporter) {
        self.client = client
        self.progressReporter = progressReporter
        logger = Logger(label: "io.exfig.studio.coordinator")
    }

    // MARK: - File Operations

    /// URLSession for downloading remote files.
    private static let downloadSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 10
        return URLSession(configuration: config)
    }()

    /// Downloads remote files and returns files with local data.
    func downloadRemoteFiles(_ files: [FileContents]) async throws -> [FileContents] {
        var result: [FileContents] = []

        for file in files {
            if let remoteURL = file.sourceURL {
                let (localURL, _) = try await Self.downloadSession.download(from: remoteURL)
                result.append(FileContents(
                    destination: file.destination,
                    dataFile: localURL,
                    scale: file.scale,
                    dark: file.dark,
                    isRTL: file.isRTL
                ))
            } else {
                result.append(file)
            }
        }

        return result
    }

    /// Writes export files to disk.
    func writeFiles(_ files: [FileContents]) throws {
        for file in files {
            let directoryURL = URL(fileURLWithPath: file.destination.directory.path)
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let fileURL = URL(fileURLWithPath: file.destination.url.path)
            if let data = file.data {
                try data.write(to: fileURL, options: .atomic)
            } else if let localFileURL = file.dataFile {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                try FileManager.default.copyItem(at: localFileURL, to: fileURL)
            }
        }
    }

    // MARK: - Main Export Entry Point

    /// Export all selected asset types to all selected platforms.
    func exportAll(
        params: Params,
        platforms: [ExFigCore.Platform],
        assets: Set<AssetType>
    ) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        if assets.contains(.colors) {
            let colorResults = try await exportColors(params: params, platforms: platforms)
            results.append(contentsOf: colorResults)
        }

        if assets.contains(.icons) {
            let iconResults = try await exportIcons(params: params, platforms: platforms)
            results.append(contentsOf: iconResults)
        }

        if assets.contains(.images) {
            let imageResults = try await exportImages(params: params, platforms: platforms)
            results.append(contentsOf: imageResults)
        }

        if assets.contains(.typography) {
            let typographyResults = try await exportTypography(params: params, platforms: platforms)
            results.append(contentsOf: typographyResults)
        }

        return results
    }
}
