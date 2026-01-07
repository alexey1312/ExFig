import ExFigCore
import Foundation

/// Processor for download command image names and dark mode handling.
/// Extracted for testability.
enum DownloadImageProcessor {
    // MARK: - Name Processing

    /// Processes image pack names applying regex replacement and name style transformations.
    ///
    /// - Parameters:
    ///   - packs: Image packs to process
    ///   - validateRegexp: Optional regex pattern for validation/matching
    ///   - replaceRegexp: Optional regex replacement pattern (supports $1, $2, etc.)
    ///   - nameStyle: Optional name style to apply
    /// - Returns: Processed image packs with transformed names
    static func processNames(
        _ packs: [ImagePack],
        validateRegexp: String?,
        replaceRegexp: String?,
        nameStyle: NameStyle?
    ) -> [ImagePack] {
        packs.map { pack in
            var processed = pack
            processed.name = processName(
                pack.name,
                validateRegexp: validateRegexp,
                replaceRegexp: replaceRegexp,
                nameStyle: nameStyle
            )
            return processed
        }
    }

    /// Processes a single name applying regex replacement and name style transformations.
    ///
    /// - Parameters:
    ///   - name: Original name to process
    ///   - validateRegexp: Optional regex pattern for validation/matching
    ///   - replaceRegexp: Optional regex replacement pattern (supports $1, $2, etc.)
    ///   - nameStyle: Optional name style to apply
    /// - Returns: Processed name
    static func processName(
        _ name: String,
        validateRegexp: String?,
        replaceRegexp: String?,
        nameStyle: NameStyle?
    ) -> String {
        var result = name

        // 1. Initial sanitization: separators
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "\\", with: "_")

        // 2. Apply regex replacement if both patterns are specified
        if let validateRegexp, let replaceRegexp,
           let regex = try? NSRegularExpression(pattern: validateRegexp)
        {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: replaceRegexp
            )
        }

        // 3. Apply name style
        if let nameStyle {
            result = applyNameStyle(result, style: nameStyle)
        }

        // 4. Final strict sanitization
        // This ensures that even after regex/style application, the result is safe
        result = sanitizeFilename(result)

        return result
    }

    /// Strictly sanitizes a filename to prevent path traversal and ensure filesystem safety.
    ///
    /// - Parameter name: The name to sanitize
    /// - Returns: Sanitized name safe for use as a filename
    private static func sanitizeFilename(_ name: String) -> String {
        var result = name

        // Replace any remaining path separators (just in case regex introduced them)
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "\\", with: "_")

        // Prevent path traversal
        result = result.replacingOccurrences(of: "..", with: "__")

        // Remove control characters and other dangerous chars
        // Reserved chars: : * ? " < > | (Windows) + control chars
        let illegalChars = CharacterSet(charactersIn: ":*?\"<>|")
            .union(.controlCharacters)
            .union(.newlines)
            .union(.illegalCharacters)

        let components = result.components(separatedBy: illegalChars)
        result = components.joined(separator: "_")

        // Ensure non-empty result (fallback to "unnamed")
        if result.isEmpty || result == "." || result == "_" {
            return "unnamed"
        }

        return result
    }

    /// Applies a name style transformation to a string.
    ///
    /// - Parameters:
    ///   - name: Name to transform
    ///   - style: Style to apply
    /// - Returns: Transformed name
    static func applyNameStyle(_ name: String, style: NameStyle) -> String {
        switch style {
        case .camelCase:
            name.lowerCamelCased()
        case .snakeCase:
            name.snakeCased()
        case .pascalCase:
            name.camelCased()
        case .kebabCase:
            name.kebabCased()
        case .screamingSnakeCase:
            name.screamingSnakeCased()
        }
    }

    // MARK: - Dark Mode Handling

    /// Splits image packs into light and dark variants based on suffix.
    ///
    /// - Parameters:
    ///   - packs: Image packs to split
    ///   - darkSuffix: Suffix identifying dark mode variants (e.g., "_dark")
    /// - Returns: Tuple of (light packs, dark packs or nil if no dark variants found)
    static func splitByDarkMode(
        _ packs: [ImagePack],
        darkSuffix: String?
    ) -> (light: [ImagePack], dark: [ImagePack]?) {
        guard let darkSuffix else {
            return (packs, nil)
        }

        let lightPacks = packs.filter { !$0.name.hasSuffix(darkSuffix) }
        let darkPacks = packs
            .filter { $0.name.hasSuffix(darkSuffix) }
            .map { pack -> ImagePack in
                var newPack = pack
                newPack.name = String(pack.name.dropLast(darkSuffix.count))
                return newPack
            }

        return (lightPacks, darkPacks.isEmpty ? nil : darkPacks)
    }

    // MARK: - File Contents Creation

    /// Creates file contents for download from image packs.
    ///
    /// - Parameters:
    ///   - packs: Image packs to create file contents from
    ///   - outputURL: Output directory URL
    ///   - format: Image format
    ///   - dark: Whether these are dark mode variants
    ///   - darkModeSuffix: Suffix for dark mode files
    /// - Returns: Array of file contents ready for download
    static func createFileContents(
        from packs: [ImagePack],
        outputURL: URL,
        format: ImageFormat,
        dark: Bool,
        darkModeSuffix: String?
    ) -> [FileContents] {
        let fileExtension = format == .webp ? "png" : format.rawValue

        return packs.flatMap { pack -> [FileContents] in
            pack.images.map { image -> FileContents in
                var fileName = pack.name
                if dark {
                    fileName += darkModeSuffix ?? "_dark"
                }
                fileName += ".\(fileExtension)"

                let destination = Destination(
                    directory: outputURL,
                    file: URL(fileURLWithPath: fileName)
                )

                return FileContents(
                    destination: destination,
                    sourceURL: image.url,
                    scale: image.scale.value,
                    dark: dark
                )
            }
        }
    }
}
