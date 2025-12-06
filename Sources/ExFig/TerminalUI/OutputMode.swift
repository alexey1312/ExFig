import Foundation

/// Output mode for CLI commands
enum OutputMode: Sendable {
    /// Default mode with spinners, progress bars, and colors
    case normal
    /// Detailed debug output including timing and API calls
    case verbose
    /// Minimal output - only errors
    case quiet
    /// Plain text mode for non-TTY environments (CI, pipes)
    case plain

    /// Determines if progress indicators should be shown
    var showProgress: Bool {
        switch self {
        case .normal, .verbose:
            true
        case .quiet, .plain:
            false
        }
    }

    /// Determines if animations should be used
    var useAnimations: Bool {
        self == .normal
    }

    /// Determines if colors should be used
    var useColors: Bool {
        switch self {
        case .normal, .verbose:
            true
        case .quiet, .plain:
            false
        }
    }

    /// Determines if debug messages should be shown
    var showDebug: Bool {
        self == .verbose
    }
}
