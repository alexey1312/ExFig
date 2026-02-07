import Foundation

/// Errors that can occur during PKL configuration evaluation.
public enum PKLError: Error, LocalizedError, Sendable {
    /// PKL evaluation failed (syntax error, type error, etc.).
    case evaluationFailed(message: String, exitCode: Int32)

    /// Configuration file not found.
    case configNotFound(path: String)

    public var errorDescription: String? {
        switch self {
        case let .evaluationFailed(message, exitCode):
            """
            PKL evaluation failed (exit code \(exitCode)):
            \(message)
            """

        case let .configNotFound(path):
            """
            Configuration file not found: \(path)

            Create an exfig.pkl configuration file or specify path with --input.
            """
        }
    }
}
