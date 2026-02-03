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

    /// Validates if a name matches the validation regexp.
    /// Returns true if no regexp is set or if name matches.
    /// - Parameter name: The name to validate
    /// - Returns: True if name passes validation
    public func validates(name: String) -> Bool {
        guard let pattern = nameValidateRegexp else {
            return true
        }

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // Invalid regex — fail safely
            return false
        }

        let range = NSRange(name.startIndex..., in: name)
        return regex.firstMatch(in: name, range: range) != nil
    }

    /// Processes a name using the validation and replacement regexps.
    /// - Parameter name: The original name
    /// - Returns: Processed name (transformed or original if no match)
    public func processName(_ name: String) -> String {
        guard let pattern = nameValidateRegexp,
              let replacement = nameReplaceRegexp
        else {
            return name
        }

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return name
        }

        let range = NSRange(name.startIndex..., in: name)

        guard regex.firstMatch(in: name, range: range) != nil else {
            return name
        }

        return regex.stringByReplacingMatches(
            in: name,
            range: range,
            withTemplate: replacement
        )
    }

    /// Filters and processes a collection of names.
    /// - Parameter names: Names to filter and process
    /// - Returns: Array of (original, processed) name pairs for valid names
    public func filterAndProcess(_ names: [String]) -> [(original: String, processed: String)] {
        names
            .filter { validates(name: $0) }
            .map { ($0, processName($0)) }
    }
}

// MARK: - Convenience Extensions

public extension NameProcessingConfig {
    /// Creates a config with only validation regexp.
    static func validate(_ pattern: String) -> NameProcessingConfig {
        NameProcessingConfig(nameValidateRegexp: pattern, nameReplaceRegexp: nil)
    }

    /// Creates a config with both validation and replacement.
    static func transform(pattern: String, replacement: String) -> NameProcessingConfig {
        NameProcessingConfig(nameValidateRegexp: pattern, nameReplaceRegexp: replacement)
    }
}
