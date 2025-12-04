import Foundation

/// Detects terminal capabilities and environment
enum TTYDetector {
    /// Returns true if stdout is connected to a TTY
    static var isTTY: Bool {
        isatty(STDOUT_FILENO) == 1
    }

    /// Returns the current terminal width in columns, or default value if unavailable.
    static var terminalWidth: Int {
        #if os(macOS) || os(Linux)
            var size = winsize()
            if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0, size.ws_col > 0 {
                return Int(size.ws_col)
            }
        #endif
        return 80 // Default fallback
    }

    /// Returns true if FORCE_COLOR environment variable is set
    static var forceColor: Bool {
        ProcessInfo.processInfo.environment["FORCE_COLOR"] != nil
    }

    /// Returns true if NO_COLOR environment variable is set
    static var noColor: Bool {
        ProcessInfo.processInfo.environment["NO_COLOR"] != nil
    }

    /// Returns true if running in a CI environment
    static var isCI: Bool {
        let ciVariables = ["CI", "CONTINUOUS_INTEGRATION", "GITHUB_ACTIONS", "GITLAB_CI", "JENKINS_URL"]
        return ciVariables.contains { ProcessInfo.processInfo.environment[$0] != nil }
    }

    /// Determines the effective output mode based on environment
    static func effectiveMode(verbose: Bool, quiet: Bool) -> OutputMode {
        if quiet {
            return .quiet
        }
        if verbose {
            return .verbose
        }
        if !isTTY || isCI {
            return .plain
        }
        return .normal
    }

    /// Returns true if colors should be enabled
    static var colorsEnabled: Bool {
        if noColor {
            return false
        }
        if forceColor {
            return true
        }
        return isTTY && !isCI
    }
}
