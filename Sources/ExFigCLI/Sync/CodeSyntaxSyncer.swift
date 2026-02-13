import ExFigCore
import FigmaAPI
import Foundation

/// Syncs generated code names back to Figma Variables codeSyntax.iOS field.
///
/// This allows designers to see real code names in Figma Dev Mode.
public struct CodeSyntaxSyncer: Sendable {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    /// Syncs codeSyntax for all color variables in the specified collection.
    ///
    /// - Parameters:
    ///   - fileId: Figma file ID containing the variables
    ///   - collectionName: Name of the variable collection to sync
    ///   - template: Template string with {name} placeholder (e.g., "Color.{name}")
    ///   - nameStyle: Name style to apply to variable names
    ///   - nameValidateRegexp: Optional regex pattern for validating/capturing names
    ///   - nameReplaceRegexp: Optional replacement pattern using captured groups
    /// - Returns: Number of variables updated
    public func sync(
        fileId: String,
        collectionName: String,
        template: String,
        nameStyle: NameStyle,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) async throws -> Int {
        // 1. Fetch variables from Figma
        let meta = try await client.request(VariablesEndpoint(fileId: fileId))

        // 2. Find the target collection
        guard let collection = meta.variableCollections.first(where: { $0.value.name == collectionName })
        else {
            throw CodeSyntaxSyncerError.collectionNotFound(collectionName)
        }

        // 3. Get all variables in the collection
        let variableIds = collection.value.variableIds
        let variables: [(id: String, name: String)] = variableIds.compactMap { id in
            guard let variable = meta.variables[id] else { return nil }
            guard variable.deletedButReferenced != true else { return nil }
            return (id: id, name: variable.name)
        }

        guard !variables.isEmpty else {
            return 0
        }

        // 4. Build update request
        let updates = variables.map { variable in
            let processedName = processName(
                variable.name,
                nameStyle: nameStyle,
                nameValidateRegexp: nameValidateRegexp,
                nameReplaceRegexp: nameReplaceRegexp
            )
            let codeSyntax = template.replacingOccurrences(of: "{name}", with: processedName)

            return VariableUpdate(
                id: variable.id,
                codeSyntax: VariableCodeSyntax(iOS: codeSyntax)
            )
        }

        // 5. Send update request
        let request = VariablesUpdateRequest(variables: updates)
        _ = try await client.request(UpdateVariablesEndpoint(fileId: fileId, body: request))

        return updates.count
    }

    /// Applies the same name transformations as ColorsProcessor:
    /// 1. Normalize: Replace "/" with "_", remove duplications like "color/color" → "color"
    /// 2. Apply nameReplaceRegexp (using nameValidateRegexp to match)
    /// 3. Apply nameStyle transformation (camelCase, snakeCase, etc.)
    private func processName(
        _ name: String,
        nameStyle: NameStyle,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?
    ) -> String {
        var result = name

        // Step 1: Normalize "/" separator
        let split = result.split(separator: "/")
        if split.count == 2, split[0] == split[1] {
            result = String(split[0])
        } else {
            result = result.replacingOccurrences(of: "/", with: "_")
        }

        // Step 2: Apply regex replacement if configured
        if let replaceRegexp = nameReplaceRegexp,
           let validateRegexp = nameValidateRegexp,
           let regex = try? NSRegularExpression(pattern: validateRegexp)
        {
            let range = NSRange(result.startIndex..., in: result)
            if let match = regex.firstMatch(in: result, range: range) {
                // Extract captured groups
                var groups: [String] = []
                for i in 0 ..< match.numberOfRanges {
                    if let groupRange = Range(match.range(at: i), in: result) {
                        groups.append(String(result[groupRange]))
                    }
                }

                // Replace $N placeholders in replaceRegexp
                var replacement = replaceRegexp
                for (index, group) in groups.enumerated() {
                    replacement = replacement.replacingOccurrences(of: "$\(index)", with: group)
                }
                result = replacement
            }
        }

        // Step 3: Apply name style transformation
        result = normalizeName(result, style: nameStyle)

        return result
    }

    /// Converts name to the specified naming style.
    private func normalizeName(_ name: String, style: NameStyle) -> String {
        switch style {
        case .camelCase:
            name.lowerCamelCased()
        case .snakeCase:
            name.snakeCased()
        case .pascalCase:
            name.camelCased()
        case .flatCase:
            name.flatCased()
        case .kebabCase:
            name.kebabCased()
        case .screamingSnakeCase:
            name.screamingSnakeCased()
        }
    }
}

/// Errors for CodeSyntaxSyncer.
public enum CodeSyntaxSyncerError: LocalizedError, Sendable {
    case collectionNotFound(String)
    case templateMissingPlaceholder

    public var errorDescription: String? {
        switch self {
        case let .collectionNotFound(name):
            "Variable collection '\(name)' not found"
        case .templateMissingPlaceholder:
            "Template must contain {name} placeholder"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .collectionNotFound:
            "Check the tokensCollectionName in your config"
        case .templateMissingPlaceholder:
            "Use a template like \"Color.{name}\" or \"UIColor.{name}\""
        }
    }
}
