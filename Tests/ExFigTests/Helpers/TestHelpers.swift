@testable import ExFig
import FigmaAPI
import Foundation

// MARK: - Params.Figma Extension

extension Params.Figma {
    /// Creates a Params.Figma for testing with minimal required fields.
    static func make(
        lightFileId: String,
        darkFileId: String? = nil,
        lightHighContrastFileId: String? = nil,
        darkHighContrastFileId: String? = nil,
        timeout: TimeInterval? = nil
    ) -> Params.Figma {
        let json = """
        {
            "lightFileId": "\(lightFileId)"
            \(darkFileId.map { ", \"darkFileId\": \"\($0)\"" } ?? "")
            \(lightHighContrastFileId.map { ", \"lightHighContrastFileId\": \"\($0)\"" } ?? "")
            \(darkHighContrastFileId.map { ", \"darkHighContrastFileId\": \"\($0)\"" } ?? "")
            \(timeout.map { ", \"timeout\": \($0)" } ?? "")
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Params.Figma.self, from: Data(json.utf8))
    }
}

// MARK: - Params.Common.Colors Extension

extension Params.Common.Colors {
    /// Creates a Params.Common.Colors for testing.
    static func make(
        useSingleFile: Bool? = nil,
        darkModeSuffix: String? = nil,
        lightHCModeSuffix: String? = nil,
        darkHCModeSuffix: String? = nil
    ) -> Params.Common.Colors {
        var components: [String] = []
        if let useSingleFile {
            components.append("\"useSingleFile\": \(useSingleFile)")
        }
        if let darkModeSuffix {
            components.append("\"darkModeSuffix\": \"\(darkModeSuffix)\"")
        }
        if let lightHCModeSuffix {
            components.append("\"lightHCModeSuffix\": \"\(lightHCModeSuffix)\"")
        }
        if let darkHCModeSuffix {
            components.append("\"darkHCModeSuffix\": \"\(darkHCModeSuffix)\"")
        }

        let json = "{ \(components.joined(separator: ", ")) }"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Params.Common.Colors.self, from: Data(json.utf8))
    }
}

// MARK: - Node Extension for Testing

extension Node {
    /// Creates a Node for testing color extraction.
    static func makeColor(
        r: Double,
        g: Double,
        b: Double,
        a: Double,
        opacity: Double? = nil
    ) -> Node {
        let json = """
        {
            "document": {
                "id": "test",
                "name": "test",
                "fills": [
                    {
                        "type": "SOLID",
                        "opacity": \(opacity ?? 1.0),
                        "color": {
                            "r": \(r),
                            "g": \(g),
                            "b": \(b),
                            "a": \(a)
                        }
                    }
                ]
            }
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Node.self, from: Data(json.utf8))
    }
}

// MARK: - Style Extension for Testing

extension Style {
    /// Creates a Style for testing.
    static func make(
        styleType: StyleType = .fill,
        nodeId: String,
        name: String,
        description: String = ""
    ) -> Style {
        Style(styleType: styleType, nodeId: nodeId, name: name, description: description)
    }
}

// MARK: - Params.Common.VariablesColors Extension

extension Params.Common.VariablesColors {
    /// Creates a Params.Common.VariablesColors for testing.
    static func make(
        tokensFileId: String,
        tokensCollectionName: String,
        lightModeName: String = "Light",
        darkModeName: String = "Dark",
        lightHCModeName: String? = nil,
        darkHCModeName: String? = nil,
        primitivesModeName: String? = nil
    ) -> Params.Common.VariablesColors {
        var components: [String] = [
            "\"tokensFileId\": \"\(tokensFileId)\"",
            "\"tokensCollectionName\": \"\(tokensCollectionName)\"",
            "\"lightModeName\": \"\(lightModeName)\"",
            "\"darkModeName\": \"\(darkModeName)\"",
        ]
        if let lightHCModeName {
            components.append("\"lightHCModeName\": \"\(lightHCModeName)\"")
        }
        if let darkHCModeName {
            components.append("\"darkHCModeName\": \"\(darkHCModeName)\"")
        }
        if let primitivesModeName {
            components.append("\"primitivesModeName\": \"\(primitivesModeName)\"")
        }

        let json = "{ \(components.joined(separator: ", ")) }"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Params.Common.VariablesColors.self, from: Data(json.utf8))
    }
}

// MARK: - Component Extension

extension Component {
    /// Creates a Component for testing.
    static func make(
        key: String = "test-key",
        nodeId: String,
        name: String,
        description: String? = nil,
        frameName: String = "Icons",
        pageName: String = "Components"
    ) -> Component {
        var json = """
        {
            "key": "\(key)",
            "node_id": "\(nodeId)",
            "name": "\(name)",
            "containing_frame": {
                "node_id": "\(nodeId)",
                "name": "\(frameName)",
                "page_name": "\(pageName)"
            }
        """
        if let description {
            json = json.replacingOccurrences(
                of: "\"containing_frame\"",
                with: "\"description\": \"\(description)\", \"containing_frame\""
            )
        }
        json += "}"

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // swiftlint:disable:next force_try
        return try! decoder.decode(Component.self, from: Data(json.utf8))
    }
}

// MARK: - Params Extension

extension Params {
    /// Creates a minimal Params for testing image loading.
    static func make(
        lightFileId: String,
        darkFileId: String? = nil,
        iconsFrameName: String? = nil,
        imagesFrameName: String? = nil,
        useSingleFileIcons: Bool? = nil,
        useSingleFileImages: Bool? = nil,
        iconsDarkModeSuffix: String? = nil
    ) -> Params {
        var commonComponents: [String] = []

        if iconsFrameName != nil || useSingleFileIcons != nil || iconsDarkModeSuffix != nil {
            var iconParts: [String] = []
            if let frameName = iconsFrameName {
                iconParts.append("\"figmaFrameName\": \"\(frameName)\"")
            }
            if let useSingle = useSingleFileIcons {
                iconParts.append("\"useSingleFile\": \(useSingle)")
            }
            if let darkSuffix = iconsDarkModeSuffix {
                iconParts.append("\"darkModeSuffix\": \"\(darkSuffix)\"")
            }
            commonComponents.append("\"icons\": { \(iconParts.joined(separator: ", ")) }")
        }

        if imagesFrameName != nil || useSingleFileImages != nil {
            var imageParts: [String] = []
            if let frameName = imagesFrameName {
                imageParts.append("\"figmaFrameName\": \"\(frameName)\"")
            }
            if let useSingle = useSingleFileImages {
                imageParts.append("\"useSingleFile\": \(useSingle)")
            }
            commonComponents.append("\"images\": { \(imageParts.joined(separator: ", ")) }")
        }

        let commonJson = commonComponents.isEmpty ? "" : ", \"common\": { \(commonComponents.joined(separator: ", ")) }"
        let darkJson = darkFileId.map { ", \"darkFileId\": \"\($0)\"" } ?? ""

        let json = """
        {
            "figma": {
                "lightFileId": "\(lightFileId)"\(darkJson)
            }\(commonJson)
        }
        """

        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Params.self, from: Data(json.utf8))
    }
}

// MARK: - VariablesMeta Extension

/// Value that can be either a color or an alias to another variable.
enum TestVariableValue {
    case color(r: Double, g: Double, b: Double, a: Double)
    case alias(String) // Reference to another variable ID
}

extension VariablesMeta {
    /// Creates a VariablesMeta for testing with specified colors and modes.
    static func make(
        collectionName: String = "Colors",
        modes: [(id: String, name: String)] = [("1:0", "Light"), ("1:1", "Dark")],
        variables: [(id: String, name: String, valuesByMode: [String: (r: Double, g: Double, b: Double, a: Double)])]
    ) -> VariablesMeta {
        let converted: [(id: String, name: String, collectionId: String?, valuesByMode: [String: TestVariableValue])]
        converted = variables.map { variable in
            let values = variable.valuesByMode.mapValues { color in
                TestVariableValue.color(r: color.r, g: color.g, b: color.b, a: color.a)
            }
            return (variable.id, variable.name, nil, values)
        }
        return makeWithAliases(
            collectionName: collectionName,
            modes: modes,
            variables: converted,
            primitiveCollections: []
        )
    }

    // swiftlint:disable function_body_length large_tuple
    /// Creates a VariablesMeta with support for variable aliases.
    /// This allows testing alias resolution where one variable references another.
    static func makeWithAliases(
        collectionName: String = "Colors",
        modes: [(id: String, name: String)] = [("1:0", "Light"), ("1:1", "Dark")],
        variables: [(id: String, name: String, collectionId: String?, valuesByMode: [String: TestVariableValue])],
        primitiveCollections: [(
            id: String, name: String, defaultModeId: String, modes: [(id: String, name: String)],
            variableIds: [String]
        )] = []
    ) -> VariablesMeta {
        // swiftlint:enable function_body_length large_tuple
        let modesJson = modes.map { mode in
            "{\"mode_id\": \"\(mode.id)\", \"name\": \"\(mode.name)\"}"
        }.joined(separator: ", ")

        // Only include variables from main collection in variable_ids
        let mainCollectionVariableIds = variables
            .filter { $0.collectionId == nil || $0.collectionId == "VariableCollectionId:1:1" }
            .map { "\"VariableID:\($0.id)\"" }
            .joined(separator: ", ")

        // Build variables JSON
        let variablesJson = variables.map { variable in
            let valuesJson = variable.valuesByMode.map { modeId, value in
                switch value {
                case let .color(r, g, b, a):
                    "\"\(modeId)\": {\"r\": \(r), \"g\": \(g), \"b\": \(b), \"a\": \(a)}"
                case let .alias(refId):
                    "\"\(modeId)\": {\"id\": \"VariableID:\(refId)\", \"type\": \"VARIABLE_ALIAS\"}"
                }
            }.joined(separator: ", ")

            let collectionId = variable.collectionId ?? "VariableCollectionId:1:1"

            return """
            "VariableID:\(variable.id)": {
                "id": "VariableID:\(variable.id)",
                "name": "\(variable.name)",
                "variable_collection_id": "\(collectionId)",
                "values_by_mode": { \(valuesJson) },
                "description": ""
            }
            """
        }.joined(separator: ", ")

        // Build primitive collections JSON
        var collectionsJson = """
        "VariableCollectionId:1:1": {
            "default_mode_id": "\(modes.first?.id ?? "1:0")",
            "id": "VariableCollectionId:1:1",
            "name": "\(collectionName)",
            "modes": [\(modesJson)],
            "variable_ids": [\(mainCollectionVariableIds)]
        }
        """

        for collection in primitiveCollections {
            let primModesJson = collection.modes.map { mode in
                "{\"mode_id\": \"\(mode.id)\", \"name\": \"\(mode.name)\"}"
            }.joined(separator: ", ")
            let primVarIds = collection.variableIds.map { "\"VariableID:\($0)\"" }.joined(separator: ", ")

            collectionsJson += """
            ,
            "\(collection.id)": {
                "default_mode_id": "\(collection.defaultModeId)",
                "id": "\(collection.id)",
                "name": "\(collection.name)",
                "modes": [\(primModesJson)],
                "variable_ids": [\(primVarIds)]
            }
            """
        }

        let json = """
        {
            "variable_collections": { \(collectionsJson) },
            "variables": { \(variablesJson) }
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // swiftlint:disable:next force_try
        return try! decoder.decode(VariablesMeta.self, from: Data(json.utf8))
    }
}
