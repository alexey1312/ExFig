// swiftlint:disable type_name

import ExFigCore
import Foundation

/// iOS typography export configuration entry.
///
/// Defines how text styles from Figma are exported to an iOS/Xcode project.
/// Supports both UIKit `UIFont` extensions and SwiftUI `Font` extensions.
///
/// ## Source Configuration
///
/// Text styles are loaded from Figma file's local styles:
/// - Source configuration comes from `figma.lightFileId` in the config
/// - All text styles from the file are exported
///
/// ## Output Configuration
///
/// - `fontSwift`: Path to generate UIFont extension
/// - `swiftUIFontSwift`: Path to generate SwiftUI Font extension
/// - `generateLabels`: Whether to generate UILabel subclasses
/// - `labelsDirectory`: Directory for generated UILabel subclasses
/// - `labelStyleSwift`: Path to generate label style extension
public struct iOSTypographyEntry: Decodable, Sendable {
    // MARK: - Source (Figma)

    /// Figma file ID containing text styles (inherited from figma.lightFileId).
    public let fileId: String?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering text style names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    // MARK: - Output (iOS-specific)

    /// Naming style for generated Swift identifiers.
    public let nameStyle: NameStyle

    /// Path to generate UIFont extension.
    public let fontSwift: URL?

    /// Path to generate SwiftUI Font extension.
    public let swiftUIFontSwift: URL?

    /// Whether to generate UILabel subclasses for each text style.
    public let generateLabels: Bool

    /// Directory for generated UILabel subclasses.
    public let labelsDirectory: URL?

    /// Path to generate label style extension.
    public let labelStyleSwift: URL?

    // MARK: - Initializer

    public init(
        fileId: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle = .camelCase,
        fontSwift: URL? = nil,
        swiftUIFontSwift: URL? = nil,
        generateLabels: Bool = false,
        labelsDirectory: URL? = nil,
        labelStyleSwift: URL? = nil
    ) {
        self.fileId = fileId
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.fontSwift = fontSwift
        self.swiftUIFontSwift = swiftUIFontSwift
        self.generateLabels = generateLabels
        self.labelsDirectory = labelsDirectory
        self.labelStyleSwift = labelStyleSwift
    }
}

// MARK: - Convenience Extensions

public extension iOSTypographyEntry {
    /// Returns a TypographySourceInput for use with TypographyExportContext.
    func typographySourceInput(fileId: String, timeout: TimeInterval?) -> TypographySourceInput {
        TypographySourceInput(
            fileId: self.fileId ?? fileId,
            timeout: timeout
        )
    }
}

// swiftlint:enable type_name
