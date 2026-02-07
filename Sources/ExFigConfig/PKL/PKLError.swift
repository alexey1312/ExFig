import Foundation

/// Errors that can occur during PKL configuration evaluation.
public enum PKLError: Error, LocalizedError, Sendable {
    /// Configuration file not found.
    case configNotFound(path: String)

    /// PKL evaluation did not complete (e.g., async bridge failed).
    case evaluationDidNotComplete

    public var errorDescription: String? {
        switch self {
        case let .configNotFound(path):
            """
            Configuration file not found: \(path)

            Create an exfig.pkl configuration file or specify path with --input.
            """

        case .evaluationDidNotComplete:
            "PKL evaluation did not complete. This is an internal error."
        }
    }
}
