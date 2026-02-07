// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSColorsEntry = iOS.ColorsEntry

// MARK: - Convenience Extensions

public extension iOS.ColorsEntry {
    /// Returns a ColorsSourceInput for use with ColorsExportContext.
    var colorsSourceInput: ColorsSourceInput {
        ColorsSourceInput(
            tokensFileId: tokensFileId ?? "",
            tokensCollectionName: tokensCollectionName ?? "",
            lightModeName: lightModeName ?? "",
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        NameStyle(rawValue: nameStyle.rawValue) ?? .camelCase
    }

    /// Path to generate UIColor extension as URL.
    var colorSwiftURL: URL? {
        colorSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate SwiftUI Color extension as URL.
    var swiftuiColorSwiftURL: URL? {
        swiftuiColorSwift.map { URL(fileURLWithPath: $0) }
    }
}

// swiftlint:enable type_name
