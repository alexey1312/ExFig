// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSTypographyEntry = iOS.Typography

// MARK: - Convenience Extensions

public extension iOS.Typography {
    /// Returns a TypographySourceInput for use with TypographyExportContext.
    /// Per-entry fileId takes priority over the provided platform-level fileId.
    func typographySourceInput(fileId: String, timeout: TimeInterval?) -> TypographySourceInput {
        TypographySourceInput(
            fileId: self.fileId ?? fileId,
            timeout: timeout
        )
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        switch nameStyle {
        case .camelCase: .camelCase
        case .snake_case: .snakeCase
        case .pascalCase: .pascalCase
        case .flatCase: .flatCase
        case .kebab_case: .kebabCase
        case .sCREAMING_SNAKE_CASE: .screamingSnakeCase
        }
    }

    /// Path to generate UIFont extension as URL.
    var fontSwiftURL: URL? {
        fontSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate SwiftUI Font extension as URL.
    var swiftUIFontSwiftURL: URL? {
        swiftUIFontSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate label style extension as URL.
    var labelStyleSwiftURL: URL? {
        labelStyleSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Directory for label subclasses as URL.
    var labelsDirectoryURL: URL? {
        labelsDirectory.map { URL(fileURLWithPath: $0) }
    }
}

// swiftlint:enable type_name
