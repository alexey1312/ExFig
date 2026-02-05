import ExFigCore
import Foundation

/// Checkpoint for resuming interrupted exports.
///
/// Stores progress of an export operation to enable resumption after failures.
/// Checkpoints are saved to `.exfig-checkpoint.json` in the working directory.
public struct ExportCheckpoint: Codable, Sendable {
    /// Unique identifier for this export session.
    public let exportID: String

    /// When the export was started.
    public let startedAt: Date

    /// SHA-256 hash of the config file for validation.
    public let configHash: String

    /// Path to the config file.
    public let configPath: String

    /// Completed export items by type.
    public var completed: CompletedItems

    /// Pending export items by type.
    public var pending: PendingItems

    /// Default checkpoint expiration (24 hours).
    public static let defaultExpiration: TimeInterval = 24 * 60 * 60

    /// Checkpoint file name.
    public static let fileName = ".exfig-checkpoint.json"

    /// Create a new checkpoint.
    /// - Parameters:
    ///   - configPath: Path to the config file.
    ///   - configHash: SHA-256 hash of config contents.
    ///   - pending: Initial pending items.
    public init(
        configPath: String,
        configHash: String,
        pending: PendingItems = PendingItems()
    ) {
        exportID = UUID().uuidString
        startedAt = Date()
        self.configPath = configPath
        self.configHash = configHash
        completed = CompletedItems()
        self.pending = pending
    }

    /// Check if checkpoint is expired.
    /// - Parameter expiration: Expiration duration (default: 24 hours).
    /// - Returns: True if checkpoint is older than expiration.
    public func isExpired(expiration: TimeInterval = defaultExpiration) -> Bool {
        Date().timeIntervalSince(startedAt) > expiration
    }

    /// Check if config hash matches.
    /// - Parameter hash: Hash to compare.
    /// - Returns: True if hashes match.
    public func matchesConfig(hash: String) -> Bool {
        configHash == hash
    }

    /// Mark a color export as completed.
    public mutating func markColorsCompleted() {
        completed.colors = true
        pending.colors = false
    }

    /// Mark a typography export as completed.
    public mutating func markTypographyCompleted() {
        completed.typography = true
        pending.typography = false
    }

    /// Mark an icon as completed.
    /// - Parameter name: Icon name.
    public mutating func markIconCompleted(_ name: String) {
        completed.icons.insert(name)
        pending.icons.remove(name)
    }

    /// Mark an image as completed.
    /// - Parameter name: Image name.
    public mutating func markImageCompleted(_ name: String) {
        completed.images.insert(name)
        pending.images.remove(name)
    }

    /// Check if all items are completed.
    public var isComplete: Bool {
        (!pending.colors || completed.colors) &&
            (!pending.typography || completed.typography) &&
            pending.icons.isEmpty &&
            pending.images.isEmpty
    }
}

// MARK: - Nested Types

public extension ExportCheckpoint {
    /// Completed export items.
    struct CompletedItems: Codable, Sendable {
        public var colors: Bool = false
        public var typography: Bool = false
        public var icons: Set<String> = []
        public var images: Set<String> = []

        public init() {}
    }

    /// Pending export items.
    struct PendingItems: Codable, Sendable {
        public var colors: Bool = false
        public var typography: Bool = false
        public var icons: Set<String> = []
        public var images: Set<String> = []

        public init() {}

        public init(
            colors: Bool = false,
            typography: Bool = false,
            icons: Set<String> = [],
            images: Set<String> = []
        ) {
            self.colors = colors
            self.typography = typography
            self.icons = icons
            self.images = images
        }
    }
}

// MARK: - Persistence

public extension ExportCheckpoint {
    /// Load checkpoint from file.
    /// - Parameter directory: Directory containing checkpoint file.
    /// - Returns: Loaded checkpoint or nil if not found.
    static func load(from directory: URL) throws -> ExportCheckpoint? {
        let fileURL = directory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        var decoder = JSONCodec.makeDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportCheckpoint.self, from: data)
    }

    /// Save checkpoint to file.
    /// - Parameter directory: Directory to save checkpoint in.
    func save(to directory: URL) throws {
        let fileURL = directory.appendingPathComponent(Self.fileName)

        var encoder = JSONCodec.makeEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.writeOptions = [.prettyPrinted]

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

// MARK: - Config Hash

extension ExportCheckpoint {
    /// Compute SHA-256 hash of config file.
    /// - Parameter url: URL of config file.
    /// - Returns: Hex-encoded SHA-256 hash.
    public static func computeConfigHash(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return computeHash(of: data)
    }

    /// Compute SHA-256 hash of data.
    /// - Parameter data: Data to hash.
    /// - Returns: Hex-encoded SHA-256 hash.
    private static func computeHash(of data: Data) -> String {
        // Simple hash using built-in facilities
        // Note: For production, consider using CryptoKit on macOS 10.15+
        var hash = 0
        for byte in data {
            hash = hash &* 31 &+ Int(byte)
        }
        return String(format: "%016llx", UInt64(bitPattern: Int64(hash)))
    }
}
