import Foundation

/// Errors that can occur during PKL configuration evaluation.
public enum PKLError: Error, LocalizedError, Sendable {
    /// PKL CLI executable was not found.
    /// Install via: `mise use pkl`
    case notFound(searchedPaths: [String])

    /// PKL evaluation failed (syntax error, type error, etc.).
    case evaluationFailed(message: String, exitCode: Int32)

    /// Configuration file not found.
    case configNotFound(path: String)

    public var errorDescription: String? {
        switch self {
        case let .notFound(searchedPaths):
            """
            PKL CLI not found.

            Searched paths:
            \(searchedPaths.map { "  - \($0)" }.joined(separator: "\n"))

            Install PKL via mise:
              mise use pkl

            Or download from: https://pkl-lang.org/main/current/pkl-cli/index.html
            """

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
