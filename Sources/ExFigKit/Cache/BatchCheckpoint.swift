import Foundation

/// Checkpoint for resuming batch processing of multiple configs.
///
/// Tracks which configs have been completed to enable resumption after failures.
/// Saved to `.exfig-batch-checkpoint.json` in the working directory.
public struct BatchCheckpoint: Codable, Sendable {
    /// Unique identifier for this batch session.
    public let batchID: String

    /// When the batch was started.
    public let startedAt: Date

    /// Paths that were requested for processing.
    public let requestedPaths: [String]

    /// Completed config paths (successful exports).
    public var completedConfigs: Set<String>

    /// Failed config paths (for reporting).
    public var failedConfigs: Set<String>

    /// Default checkpoint expiration (24 hours).
    public static let defaultExpiration: TimeInterval = 24 * 60 * 60

    /// Checkpoint file name.
    public static let fileName = ".exfig-batch-checkpoint.json"

    /// Create a new batch checkpoint.
    /// - Parameter requestedPaths: Paths requested for processing.
    public init(requestedPaths: [String]) {
        batchID = UUID().uuidString
        startedAt = Date()
        self.requestedPaths = requestedPaths
        completedConfigs = []
        failedConfigs = []
    }

    /// Check if checkpoint is expired.
    /// - Parameter expiration: Expiration duration (default: 24 hours).
    /// - Returns: True if checkpoint is older than expiration.
    public func isExpired(expiration: TimeInterval = defaultExpiration) -> Bool {
        Date().timeIntervalSince(startedAt) > expiration
    }

    /// Check if paths match (same batch).
    /// - Parameter paths: Paths to compare.
    /// - Returns: True if paths match.
    public func matchesPaths(_ paths: [String]) -> Bool {
        Set(requestedPaths) == Set(paths)
    }

    /// Mark a config as completed.
    /// - Parameter path: Config file path.
    public mutating func markCompleted(_ path: String) {
        completedConfigs.insert(path)
        failedConfigs.remove(path)
    }

    /// Mark a config as failed.
    /// - Parameter path: Config file path.
    public mutating func markFailed(_ path: String) {
        failedConfigs.insert(path)
    }

    /// Check if a config is already completed.
    /// - Parameter path: Config file path.
    /// - Returns: True if config was completed in previous run.
    public func isCompleted(_ path: String) -> Bool {
        completedConfigs.contains(path)
    }

    /// Number of remaining configs to process.
    public var remainingCount: Int {
        requestedPaths.count - completedConfigs.count
    }

    /// Get paths that still need processing.
    /// - Parameter allPaths: All discovered config paths.
    /// - Returns: Paths not yet completed.
    public func pendingPaths(from allPaths: [String]) -> [String] {
        allPaths.filter { !completedConfigs.contains($0) }
    }
}

// MARK: - Persistence

public extension BatchCheckpoint {
    /// Load checkpoint from file.
    /// - Parameter directory: Directory containing checkpoint file.
    /// - Returns: Loaded checkpoint or nil if not found.
    static func load(from directory: URL) throws -> BatchCheckpoint? {
        let fileURL = directory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BatchCheckpoint.self, from: data)
    }

    /// Save checkpoint to file.
    /// - Parameter directory: Directory to save checkpoint in.
    func save(to directory: URL) throws {
        let fileURL = directory.appendingPathComponent(Self.fileName)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(self)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Delete checkpoint file.
    /// - Parameter directory: Directory containing checkpoint file.
    static func delete(from directory: URL) throws {
        let fileURL = directory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
