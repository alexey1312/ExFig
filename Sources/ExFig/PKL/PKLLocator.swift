import Foundation

/// Locates the PKL CLI executable.
///
/// Search order:
/// 1. mise installs directory (~/.local/share/mise/installs/pkl/*/pkl)
/// 2. Homebrew on Apple Silicon (/opt/homebrew/bin/pkl)
/// 3. Homebrew on Intel (/usr/local/bin/pkl)
/// 4. PATH environment variable (skipping mise shims)
///
/// Note: mise shims don't work correctly for pkl (they intercept `eval` as mise task).
/// We search the installs directory directly instead.
///
/// Usage:
/// ```swift
/// let locator = PKLLocator()
/// let pklPath = try locator.findPKL()
/// ```
public final class PKLLocator: @unchecked Sendable {
    private let miseInstallsPath: String
    private let homebrewPaths: [String]
    private let pathEnvironment: String

    private var cachedPath: URL?
    private let lock = NSLock()

    /// Creates a new PKL locator.
    /// - Parameters:
    ///   - miseShimsPath: Path to mise installs directory. Default: ~/.local/share/mise/installs
    ///   - pathEnvironment: PATH environment value. Default: current PATH
    public init(
        miseShimsPath: String? = nil,
        pathEnvironment: String? = nil
    ) {
        miseInstallsPath = miseShimsPath ?? Self.defaultMiseInstallsPath()
        homebrewPaths = Self.defaultHomebrewPaths()
        self.pathEnvironment = pathEnvironment ?? ProcessInfo.processInfo.environment["PATH"] ?? ""
    }

    /// Finds the PKL CLI executable.
    /// - Returns: URL to the pkl executable
    /// - Throws: `PKLError.notFound` if pkl is not installed
    public func findPKL() throws -> URL {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedPath {
            return cached
        }

        var searchedPaths: [String] = []

        // 1. Check mise installs (find latest version)
        let pklInstallsDir = URL(fileURLWithPath: miseInstallsPath)
            .appendingPathComponent("pkl")
            .path
        searchedPaths.append(pklInstallsDir)

        if let pklPath = findLatestPklInInstalls(pklInstallsDir) {
            cachedPath = pklPath
            return pklPath
        }

        // 2. Check Homebrew locations
        for homebrewPath in homebrewPaths {
            searchedPaths.append(homebrewPath)

            if FileManager.default.isExecutableFile(atPath: homebrewPath) {
                let url = URL(fileURLWithPath: homebrewPath)
                cachedPath = url
                return url
            }
        }

        // 3. Check PATH (skipping mise shims)
        let pathDirs = pathEnvironment.split(separator: ":").map(String.init)
        for dir in pathDirs {
            // Skip mise shims - they don't work correctly for pkl
            if dir.contains("mise/shims") {
                continue
            }

            let pklPath = URL(fileURLWithPath: dir)
                .appendingPathComponent("pkl")
                .path
            searchedPaths.append(pklPath)

            if FileManager.default.isExecutableFile(atPath: pklPath) {
                let url = URL(fileURLWithPath: pklPath)
                cachedPath = url
                return url
            }
        }

        throw PKLError.notFound(searchedPaths: searchedPaths)
    }

    /// Clears the cached path (useful for testing).
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedPath = nil
    }

    private func findLatestPklInInstalls(_ pklInstallsDir: String) -> URL? {
        let fm = FileManager.default

        guard let versions = try? fm.contentsOfDirectory(atPath: pklInstallsDir) else {
            return nil
        }

        // Sort versions descending to get latest first
        let sortedVersions = versions.sorted { v1, v2 in
            v1.compare(v2, options: .numeric) == .orderedDescending
        }

        for version in sortedVersions {
            let pklPath = URL(fileURLWithPath: pklInstallsDir)
                .appendingPathComponent(version)
                .appendingPathComponent("pkl")
                .path

            if fm.isExecutableFile(atPath: pklPath) {
                return URL(fileURLWithPath: pklPath)
            }
        }

        return nil
    }

    private static func defaultMiseInstallsPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return URL(fileURLWithPath: home)
            .appendingPathComponent(".local/share/mise/installs")
            .path
    }

    private static func defaultHomebrewPaths() -> [String] {
        [
            "/opt/homebrew/bin/pkl", // Apple Silicon
            "/usr/local/bin/pkl", // Intel Mac
            "/home/linuxbrew/.linuxbrew/bin/pkl", // Linux Homebrew
        ]
    }
}
