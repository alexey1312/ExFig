import Foundation

public struct AssetsFilter: Sendable {
    private let filters: [String]

    public init(filter: String) {
        filters = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    public init(filters: [String]) {
        self.filters = filters
    }

    /// Returns true if name matches with filter
    /// - Parameters:
    ///   - name: Name of the asset
    ///   - filter: Name of the assets separated by comma
    public func match(name: String) -> Bool {
        filters.contains(where: { filter -> Bool in
            if filter.contains("*") {
                return wildcard(name, pattern: filter)
            } else {
                return name == filter
            }
        })
    }

    private func wildcard(_ string: String, pattern: String) -> Bool {
        // Convert wildcard pattern to regex
        // * matches any sequence of characters
        // Escape special regex characters first, then replace escaped \* with .*
        var regexPattern = NSRegularExpression.escapedPattern(for: pattern)
        regexPattern = regexPattern.replacingOccurrences(of: "\\*", with: ".*")
        regexPattern = "^" + regexPattern + "$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }

        let range = NSRange(string.startIndex..., in: string)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }
}
