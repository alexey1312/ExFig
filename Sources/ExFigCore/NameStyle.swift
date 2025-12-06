import Foundation

/// Naming convention styles for asset names.
///
/// Supported styles:
/// - `camelCase`: lowerCamelCase - `myImageName`
/// - `snakeCase`: snake_case - `my_image_name`
/// - `pascalCase`: PascalCase/UpperCamelCase - `MyImageName`
/// - `kebabCase`: kebab-case - `my-image-name`
/// - `screamingSnakeCase`: SCREAMING_SNAKE_CASE - `MY_IMAGE_NAME`
public enum NameStyle: String, Decodable, Sendable, CaseIterable {
    /// lowerCamelCase: `myImageName`
    case camelCase

    /// snake_case: `my_image_name`
    case snakeCase = "snake_case"

    /// PascalCase/UpperCamelCase: `MyImageName`
    case pascalCase = "PascalCase"

    /// kebab-case: `my-image-name`
    case kebabCase = "kebab-case"

    /// SCREAMING_SNAKE_CASE: `MY_IMAGE_NAME`
    case screamingSnakeCase = "SCREAMING_SNAKE_CASE"
}
