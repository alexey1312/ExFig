import Foundation

extension String {
    /// A Boolean value indicating whether this string is considered snake case.
    ///
    /// For example, the following strings are all snake case:
    ///
    /// - "snake_case"
    /// - "example"
    /// - "date_formatter"
    ///
    /// String can contain lowercase letters and underscores only.
    /// In snake case, words are separated by underscores.
    var isSnakeCase: Bool {
        // Strip all underscores and check if the rest is lowercase
        filter { $0 != "_" }.allSatisfy { $0.isLowercase || $0.isNumber }
    }

    /// A Boolean value indicating whether this string is considered kebab case.
    ///
    /// For example, the following strings are all kebab case:
    ///
    /// - "kebab-case"
    /// - "example"
    /// - "date-formatter"
    ///
    /// String can contain lowercase letters and hyphens only.
    /// In kebab case, words are separated by hyphens.
    var isKebabCase: Bool {
        // Strip all hyphens and check if the rest is lowercase
        filter { $0 != "-" }.allSatisfy { $0.isLowercase || $0.isNumber }
    }

    /// A Boolean value indicating whether this string is considered lower camel case.
    ///
    /// For example, the following strings are all lower camel case:
    ///
    /// - "lowerCamelCase"
    /// - "example"
    /// - "dateFormatter"
    ///
    /// String can contain lowercase and uppercase letters only.
    /// In lower camel case, words are separated by uppercase letters.
    var isLowerCamelCase: Bool {
        // Check if the first character is lowercase and the rest contains letters
        if let firstCharacter = first, firstCharacter.isLowercase, allSatisfy(\.isLetter) {
            return true
        }
        return false
    }
}

public extension String {
    /// Splits given string by variations between two characters and
    /// returns and array of strings.
    ///
    /// In this example, `lowercasedStrings` is used first to convert the names in the array
    /// to lowercase strings and then to count their characters.
    private func lowercasedStrings() -> [String] {
        var lastCharacter: Character = " "
        var results: [String] = []

        for character in [Character](self) {
            if results.isEmpty && (character.isLetter || character.isNumber) {
                results.append(String(character))
            } else if ((lastCharacter.isLetter || lastCharacter.isNumber) && character.isLowercase) ||
                (lastCharacter.isNumber && character.isNumber) ||
                (lastCharacter.isUppercase && character.isUppercase)
            {
                results[results.count - 1] += String(character)
            } else if character.isLetter || character.isNumber {
                results.append(String(character))
            }
            lastCharacter = character
        }

        return results.map(\.capitalized)
    }

    /// Returns a camel case version of the string.
    ///
    /// Here's an example of transforming a string to camel case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.lowerCamelCased())
    ///     // Prints "KeynoteEvent"
    ///
    /// - Returns: A camel case copy of the string.
    func camelCased() -> String {
        let strings = lowercasedStrings()
        return strings.joined()
    }

    /// Returns a lower camel case version of the string.
    ///
    /// Here's an example of transforming a string to lower camel case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.lowerCamelCased())
    ///     // Prints "keynoteEvent"
    ///
    /// - Returns: A lower camel case copy of the string.
    func lowerCamelCased() -> String {
        if isLowerCamelCase { return self }
        var strings = lowercasedStrings()
        if let firstString = strings.first {
            strings[0] = firstString.lowercased()
        }
        return strings.joined()
    }

    /// Returns snake case version of the string.
    ///
    /// Here's an example of transforming a string to snake case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.snakeCased())
    ///     // Prints "keynote_event"
    ///
    /// - Returns: A snake case copy of the string.
    func snakeCased() -> String {
        guard !isSnakeCase else { return self }
        // Convert kebab-case to snake_case directly (preserves number placement like "discount5")
        let kebabConverted = replacingOccurrences(of: "-", with: "_")
        guard !kebabConverted.isSnakeCase else { return kebabConverted }
        let result = split(separator: " ").joined(separator: "_")
        guard !result.isSnakeCase else { return result }
        return result.lowercasedStrings().map { $0.lowercased() }.joined(separator: "_")
    }

    /// Returns kebab case version of the string.
    ///
    /// Here's an example of transforming a string to kebab case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.kebabCased())
    ///     // Prints "keynote-event"
    ///
    /// - Returns: A kebab case copy of the string.
    func kebabCased() -> String {
        guard !isKebabCase else { return self }
        // Convert snake_case to kebab-case directly (preserves number placement like "box04")
        let snakeConverted = replacingOccurrences(of: "_", with: "-")
        guard !snakeConverted.isKebabCase else { return snakeConverted }
        return lowercasedStrings().map { $0.lowercased() }.joined(separator: "-")
    }

    /// Returns screaming snake case version of the string.
    ///
    /// Here's an example of transforming a string to screaming snake case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.screamingSnakeCased())
    ///     // Prints "KEYNOTE_EVENT"
    ///
    /// - Returns: A screaming snake case copy of the string.
    func screamingSnakeCased() -> String {
        lowercasedStrings().map { $0.uppercased() }.joined(separator: "_")
    }

    /// Converts the string to flat case (all lowercase, no separator).
    ///
    /// Here's an example of transforming a string to flat case.
    ///
    ///     let event = "Keynote Event"
    ///     print(event.flatCased())
    ///     // Prints "keynoteevent"
    ///
    /// - Returns: A flat case copy of the string.
    func flatCased() -> String {
        lowercasedStrings().joined()
    }
}
