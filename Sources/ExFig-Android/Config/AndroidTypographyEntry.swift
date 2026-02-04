import ExFigCore
import Foundation

/// Android typography export configuration entry.
///
/// Defines how text styles from Figma are exported to an Android project.
/// Supports both XML resources and Kotlin/Compose typography.
///
/// ## Source Configuration
///
/// Text styles are loaded from Figma file's local styles:
/// - Source configuration comes from `figma.lightFileId` in the config
/// - All text styles from the file are exported
///
/// ## Output Configuration
///
/// - XML typography styles in res/values/typography.xml
/// - Kotlin Typography class for Compose (optional)
public struct AndroidTypographyEntry: Decodable, Sendable {
    // MARK: - Source (Figma)

    /// Figma file ID containing text styles (inherited from figma.lightFileId).
    public let fileId: String?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering text style names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    // MARK: - Output (Android-specific)

    /// Naming style for generated identifiers.
    public let nameStyle: NameStyle

    /// Package name for Compose Typography class.
    public let composePackageName: String?

    // MARK: - Initializer

    public init(
        fileId: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle = .snakeCase,
        composePackageName: String? = nil
    ) {
        self.fileId = fileId
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.composePackageName = composePackageName
    }
}

// MARK: - Convenience Extensions

public extension AndroidTypographyEntry {
    /// Returns a TypographySourceInput for use with TypographyExportContext.
    func typographySourceInput(fileId: String, timeout: TimeInterval?) -> TypographySourceInput {
        TypographySourceInput(
            fileId: self.fileId ?? fileId,
            timeout: timeout
        )
    }
}
