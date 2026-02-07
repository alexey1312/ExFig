import Foundation

/// Errors that can occur during config discovery.
enum ConfigDiscoveryError: LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound(URL)
    case invalidConfig(URL, String)

    var errorDescription: String? {
        switch self {
        case let .directoryNotFound(url):
            "Directory not found: \(url.path)"
        case let .fileNotFound(url):
            "Config file not found: \(url.path)"
        case let .invalidConfig(url, reason):
            "Invalid config: \(url.lastPathComponent) - \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            "Check the directory path exists"
        case .fileNotFound:
            "Check the config file path"
        case .invalidConfig:
            "Validate config with: pkl eval <config>"
        }
    }
}

/// Represents an output path conflict between configs.
struct OutputPathConflict {
    /// The conflicting output path.
    let path: String
    /// URLs of configs that share this output path.
    let configs: [URL]
}

/// Discovers and validates ExFig configuration files.
struct ConfigDiscovery {
    private static let pklExtension = "pkl"

    // MARK: - Directory Scanning

    /// Discover all PKL config files in a directory.
    /// - Parameter directory: Directory to scan.
    /// - Returns: Array of URLs to discovered PKL files.
    /// - Throws: `ConfigDiscoveryError.directoryNotFound` if directory doesn't exist.
    func discoverConfigs(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw ConfigDiscoveryError.directoryNotFound(directory)
        }

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter { url in
            url.pathExtension.lowercased() == Self.pklExtension
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Discover configs from an explicit list of file URLs.
    /// - Parameter urls: URLs to config files.
    /// - Returns: Array of validated URLs.
    /// - Throws: `ConfigDiscoveryError.fileNotFound` if any file doesn't exist.
    func discoverConfigs(from urls: [URL]) throws -> [URL] {
        let fileManager = FileManager.default

        for url in urls {
            guard fileManager.fileExists(atPath: url.path) else {
                throw ConfigDiscoveryError.fileNotFound(url)
            }
        }

        return urls
    }

    // MARK: - Config Validation

    /// Filter discovered configs to only include valid ExFig configs.
    /// - Parameter configs: URLs to check.
    /// - Returns: URLs that are valid ExFig configs.
    func filterValidConfigs(_ configs: [URL]) -> [URL] {
        configs.filter { isValidExFigConfig(at: $0) }
    }

    /// Check if a PKL file is a valid ExFig config.
    /// - Parameter url: URL to the PKL file.
    /// - Returns: `true` if the file is a valid ExFig config.
    ///
    /// A config is valid if it:
    /// - Has .pkl extension
    /// - Contains "ExFig" in amends clause or has platform section (ios, android, flutter, web)
    func isValidExFigConfig(at url: URL) -> Bool {
        guard url.pathExtension.lowercased() == Self.pklExtension else {
            return false
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)

            // Check if it amends ExFig schema
            if content.contains("ExFig.pkl") {
                return true
            }

            // Check for platform sections (basic text search)
            let platforms = ["ios", "android", "flutter", "web"]
            for platform in platforms {
                // Look for platform = new or platform { patterns
                if content.contains("\(platform) =") || content.contains("\(platform) {") {
                    return true
                }
            }

            return false
        } catch {
            ExFigCommand.logger.warning(
                "Failed to read config file \(url.lastPathComponent): \(error.localizedDescription)"
            )
            return false
        }
    }

    // MARK: - Conflict Detection

    /// Detect output path conflicts between configs.
    /// - Parameter configs: URLs to config files.
    /// - Returns: Array of conflicts found.
    func detectOutputPathConflicts(_ configs: [URL]) throws -> [OutputPathConflict] {
        var pathToConfigs: [String: [URL]] = [:]

        for configURL in configs {
            let outputPaths = try extractOutputPaths(from: configURL)
            for path in outputPaths {
                pathToConfigs[path, default: []].append(configURL)
            }
        }

        return pathToConfigs
            .filter { $0.value.count > 1 }
            .map { OutputPathConflict(path: $0.key, configs: $0.value) }
            .sorted { $0.path < $1.path }
    }

    // MARK: - Private Helpers

    private func extractOutputPaths(from configURL: URL) throws -> [String] {
        // For PKL, we need to evaluate the config to get output paths
        // For now, do a basic text search for common output path patterns
        let content = try String(contentsOf: configURL, encoding: .utf8)
        var paths: [String] = []

        // Extract iOS xcassetsPath
        if let match = content.firstMatch(of: /xcassetsPath\s*=\s*"([^"]+)"/) {
            paths.append(String(match.1))
        }

        // Extract Android mainRes
        if let match = content.firstMatch(of: /mainRes\s*=\s*"([^"]+)"/) {
            paths.append(String(match.1))
        }

        // Extract Flutter/Web output
        if let match = content.firstMatch(of: /output\s*=\s*"([^"]+)"/) {
            paths.append(String(match.1))
        }

        return paths
    }
}
