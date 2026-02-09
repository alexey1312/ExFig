import ExFigConfig
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias FlutterColorsEntry = Flutter.ColorsEntry

// MARK: - Entry-Level Override Resolution

public extension Flutter.ColorsEntry {
    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }
}
