import ExFigConfig
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias WebColorsEntry = Web.ColorsEntry

// MARK: - Entry-Level Override Resolution

public extension Web.ColorsEntry {
    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved output path: entry override or platform config fallback.
    func resolvedOutput(fallback: URL) -> URL {
        output.map { URL(fileURLWithPath: $0) } ?? fallback
    }
}
