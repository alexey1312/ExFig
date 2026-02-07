import Foundation

/// Configuration for name validation and transformation using regular expressions.
///
/// Used to filter and transform asset names from Figma:
/// - `nameValidateRegexp`: Filter names that match the pattern
/// - `nameReplaceRegexp`: Transform names using capture groups
///
/// Example:
/// ```pkl
/// nameValidateRegexp = "^icon_(.+)$"  // Match names starting with "icon_"
/// nameReplaceRegexp = "$1"             // Keep only the part after "icon_"
/// ```
public struct NameProcessingConfig: Decodable, Sendable {
    /// Regex pattern for validating/filtering names.
    /// Only names matching this pattern will be processed.
    /// If nil, all names are accepted.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    /// Uses `$1`, `$2`, etc. for capture groups.
    /// If nil, name is returned unchanged.
    public let nameReplaceRegexp: String?

    public init(
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) {
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
    }
}
