import Foundation
import Yams

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
            "Invalid config at \(url.path): \(reason)"
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
    private static let yamlExtensions = ["yaml", "yml"]

    // MARK: - Directory Scanning

    /// Discover all YAML config files in a directory.
    /// - Parameter directory: Directory to scan.
    /// - Returns: Array of URLs to discovered YAML files.
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
            Self.yamlExtensions.contains(url.pathExtension.lowercased())
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

    /// Filter discovered configs to only include valid ExFig/figma-export configs.
    /// - Parameter configs: URLs to check.
    /// - Returns: URLs that are valid ExFig configs.
    func filterValidConfigs(_ configs: [URL]) -> [URL] {
        configs.filter { isValidExFigConfig(at: $0) }
    }

    /// Check if a YAML file is a valid ExFig config.
    /// - Parameter url: URL to the YAML file.
    /// - Returns: `true` if the file is a valid ExFig config.
    func isValidExFigConfig(at url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8),
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return false
            }

            // Try to parse as YAML and check for required 'figma' section
            guard let yaml = try Yams.load(yaml: content) as? [String: Any] else {
                return false
            }
            return yaml["figma"] != nil
        } catch {
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
        let data = try Data(contentsOf: configURL)
        guard let content = String(data: data, encoding: .utf8) else {
            return []
        }

        guard let yaml = try Yams.load(yaml: content) as? [String: Any] else {
            return []
        }

        var paths: [String] = []

        // Extract iOS xcassetsPath
        if let ios = yaml["ios"] as? [String: Any],
           let xcassetsPath = ios["xcassetsPath"] as? String
        {
            paths.append(xcassetsPath)
        }

        // Extract Android mainRes
        if let android = yaml["android"] as? [String: Any],
           let mainRes = android["mainRes"] as? String
        {
            paths.append(mainRes)
        }

        // Extract Flutter output
        if let flutter = yaml["flutter"] as? [String: Any],
           let output = flutter["output"] as? String
        {
            paths.append(output)
        }

        return paths
    }
}
