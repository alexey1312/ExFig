import ExFigCore
import FigmaAPI

/// W3C token type for a numeric variable, determined by Figma variable scopes.
public enum NumberTokenType: String, Sendable {
    /// Spatial value with unit — `$value: {"value": N, "unit": "px"}`.
    case dimension
    /// Unitless numeric value — `$value: N`.
    case number
}

/// A loaded numeric token with its resolved W3C type.
public struct NumberToken: Sendable {
    public let name: String
    public let value: Double
    public let tokenType: NumberTokenType
    public let description: String?
    public let variableId: String
    public let fileId: String
}

/// Loads FLOAT variables from Figma and classifies them as `dimension` or `number`
/// based on their Figma scopes.
final class NumberVariablesLoader: Sendable {
    private let client: Client
    private let tokensFileId: String
    private let tokensCollectionName: String
    private let modeName: String
    private let filter: String?

    init(
        client: Client,
        tokensFileId: String,
        tokensCollectionName: String,
        modeName: String = "Default",
        filter: String? = nil
    ) {
        self.client = client
        self.tokensFileId = tokensFileId
        self.tokensCollectionName = tokensCollectionName
        self.modeName = modeName
        self.filter = filter
    }

    struct LoadResult: Sendable {
        let dimensions: [NumberToken]
        let numbers: [NumberToken]
        let warnings: [ExFigWarning]
    }

    func load() async throws -> LoadResult {
        let endpoint = VariablesEndpoint(fileId: tokensFileId)
        let meta = try await client.request(endpoint)

        guard let collection = meta.variableCollections.first(where: { $0.value.name == tokensCollectionName })
        else {
            throw ExFigError.custom(errorString: "Collection '\(tokensCollectionName)' not found for number variables")
        }

        let modeId = collection.value.modes.first(where: { $0.name == modeName })?.modeId
            ?? collection.value.defaultModeId

        var dimensions: [NumberToken] = []
        var numbers: [NumberToken] = []
        var warnings: [ExFigWarning] = []

        for variableId in collection.value.variableIds {
            guard let variable = meta.variables[variableId] else { continue }
            guard isFloatVariable(variable) else { continue }

            if let token = processVariable(variable, modeId: modeId, meta: meta, warnings: &warnings) {
                switch token.tokenType {
                case .dimension: dimensions.append(token)
                case .number: numbers.append(token)
                }
            }
        }

        return LoadResult(dimensions: dimensions, numbers: numbers, warnings: warnings)
    }

    private func isFloatVariable(_ variable: VariableValue) -> Bool {
        guard variable.deletedButReferenced != true else { return false }
        guard variable.resolvedType == "FLOAT" else { return false }
        if let filter {
            return AssetsFilter(filter: filter).match(name: variable.name)
        }
        return true
    }

    private func processVariable(
        _ variable: VariableValue,
        modeId: String,
        meta: VariablesMeta,
        warnings: inout [ExFigWarning]
    ) -> NumberToken? {
        guard let modeValue = variable.valuesByMode[modeId] else { return nil }

        guard let resolvedValue = resolveValue(modeValue, meta: meta, modeId: modeId) else {
            warnings.append(.unresolvedNumberAlias(tokenName: variable.name))
            return nil
        }

        let desc = variable.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return NumberToken(
            name: variable.name,
            value: resolvedValue,
            tokenType: Self.scopesToTokenType(variable.scopes ?? []),
            description: desc.isEmpty ? nil : desc,
            variableId: variable.id,
            fileId: tokensFileId
        )
    }

    private func resolveValue(_ value: ValuesByMode, meta: VariablesMeta, modeId: String) -> Double? {
        switch value {
        case let .number(num):
            num
        case let .variableAlias(alias):
            resolveNumberAlias(alias: alias, meta: meta, modeId: modeId)
        default:
            nil
        }
    }

    private func resolveNumberAlias(
        alias: VariableAlias,
        meta: VariablesMeta,
        modeId: String,
        depth: Int = 0
    ) -> Double? {
        guard depth < 10 else { return nil }
        guard let variable = meta.variables[alias.id] else { return nil }
        guard variable.deletedButReferenced != true else { return nil }

        let collection = meta.variableCollections[variable.variableCollectionId]
        let resolvedModeId = collection?.modes.first(where: { $0.name == "Value" })?.modeId
            ?? collection?.defaultModeId
            ?? modeId

        guard let value = variable.valuesByMode[resolvedModeId] else { return nil }

        switch value {
        case let .number(num):
            return num
        case let .variableAlias(nextAlias):
            return resolveNumberAlias(alias: nextAlias, meta: meta, modeId: modeId, depth: depth + 1)
        default:
            return nil
        }
    }

    // MARK: - Scope to Token Type Mapping (Tasks 5.2, 5.5)

    /// Figma scopes that indicate a spatial/dimensional value (needs "px" unit).
    private static let dimensionScopes: Set<String> = [
        "ALL_SCOPES",
        "WIDTH_HEIGHT",
        "GAP",
        "CORNER_RADIUS",
        "FONT_SIZE",
        "LINE_HEIGHT",
        "LETTER_SPACING",
        "STROKE_FLOAT",
        "EFFECT_FLOAT",
        "PARAGRAPH_INDENT",
        "PARAGRAPH_SPACING",
    ]

    /// Figma scopes that indicate a unitless numeric value.
    private static let numberScopes: Set<String> = [
        "FONT_WEIGHT",
        "OPACITY",
    ]

    /// Maps Figma variable scopes to W3C token type.
    ///
    /// If any scope is in `dimensionScopes`, the variable is a `dimension`.
    /// If scopes contain only `numberScopes` entries, it's a `number`.
    /// Empty or unknown scopes default to `number`.
    static func scopesToTokenType(_ scopes: [String]) -> NumberTokenType {
        guard !scopes.isEmpty else { return .number }

        // Check for explicit number-only scopes first
        let hasNumberScope = scopes.contains(where: { numberScopes.contains($0) })
        let hasDimensionScope = scopes.contains(where: { dimensionScopes.contains($0) })

        if hasDimensionScope {
            return .dimension
        }
        if hasNumberScope {
            return .number
        }
        return .number
    }
}
