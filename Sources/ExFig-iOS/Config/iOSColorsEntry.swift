// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSColorsEntry = iOS.ColorsEntry

// MARK: - Convenience Extensions

public extension iOS.ColorsEntry {
    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        nameStyle.coreNameStyle
    }

    /// Path to generate UIColor extension as URL.
    var colorSwiftURL: URL? {
        colorSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate SwiftUI Color extension as URL.
    var swiftuiColorSwiftURL: URL? {
        swiftuiColorSwift.map { URL(fileURLWithPath: $0) }
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved xcassets path: entry override or platform config fallback.
    func resolvedXcassetsPath(fallback: URL?) -> URL? {
        xcassetsPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }
}

// swiftlint:enable type_name
