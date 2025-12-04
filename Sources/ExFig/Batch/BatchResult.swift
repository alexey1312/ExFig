import Foundation

/// Represents a config file to be processed.
struct ConfigFile: Sendable {
    /// URL to the config file.
    let url: URL
    /// Display name for the config.
    let name: String

    init(url: URL, name: String? = nil) {
        self.url = url
        self.name = name ?? url.lastPathComponent
    }
}

/// Statistics from an export operation.
struct ExportStats: Sendable {
    let colors: Int
    let icons: Int
    let images: Int
    let typography: Int

    static let zero = ExportStats(colors: 0, icons: 0, images: 0, typography: 0)

    static func + (lhs: ExportStats, rhs: ExportStats) -> ExportStats {
        ExportStats(
            colors: lhs.colors + rhs.colors,
            icons: lhs.icons + rhs.icons,
            images: lhs.images + rhs.images,
            typography: lhs.typography + rhs.typography
        )
    }
}

/// Result of processing a single config.
enum ConfigResult: Sendable {
    case success(config: ConfigFile, stats: ExportStats)
    case failure(config: ConfigFile, error: any Error)

    var config: ConfigFile {
        switch self {
        case let .success(config, _), let .failure(config, _):
            config
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var stats: ExportStats? {
        if case let .success(_, stats) = self {
            return stats
        }
        return nil
    }

    var error: (any Error)? {
        if case let .failure(_, error) = self {
            return error
        }
        return nil
    }
}

/// Result of batch processing multiple configs.
struct BatchResult: Sendable {
    /// Results for each config processed.
    let results: [ConfigResult]
    /// Total duration of batch execution.
    let duration: TimeInterval
    /// When the batch started.
    let startTime: Date
    /// When the batch completed.
    let endTime: Date

    /// Number of successful configs.
    var successCount: Int {
        results.filter(\.isSuccess).count
    }

    /// Number of failed configs.
    var failureCount: Int {
        results.count - successCount
    }

    /// Aggregated stats from all successful configs.
    var totalStats: ExportStats {
        results.compactMap(\.stats).reduce(.zero, +)
    }

    /// Failed configs with their errors.
    var failures: [(config: ConfigFile, error: any Error)] {
        results.compactMap { result in
            if case let .failure(config, error) = result {
                return (config, error)
            }
            return nil
        }
    }

    /// Successful configs with their stats.
    var successes: [(config: ConfigFile, stats: ExportStats)] {
        results.compactMap { result in
            if case let .success(config, stats) = result {
                return (config, stats)
            }
            return nil
        }
    }
}
