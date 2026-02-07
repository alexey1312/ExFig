// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSColorsEntry = iOS.ColorsEntry

// MARK: - Convenience Extensions

public extension iOS.ColorsEntry {
    /// Returns a validated ColorsSourceInput for use with ColorsExportContext.
    /// Throws if required fields (tokensFileId, tokensCollectionName, lightModeName) are nil or empty.
    func validatedColorsSourceInput() throws -> ColorsSourceInput {
        guard let tokensFileId, !tokensFileId.isEmpty else {
            throw ColorsConfigError.missingTokensFileId
        }
        guard let tokensCollectionName, !tokensCollectionName.isEmpty else {
            throw ColorsConfigError.missingTokensCollectionName
        }
        guard let lightModeName, !lightModeName.isEmpty else {
            throw ColorsConfigError.missingLightModeName
        }
        return ColorsSourceInput(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
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
        switch nameStyle {
        case .camelCase: .camelCase
        case .snake_case: .snakeCase
        case .pascalCase: .pascalCase
        case .flatCase: .flatCase
        case .kebab_case: .kebabCase
        case .sCREAMING_SNAKE_CASE: .screamingSnakeCase
        }
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
