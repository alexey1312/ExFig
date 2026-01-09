/// Models for updating Figma Variables via REST API
/// POST /v1/files/:file_key/variables

/// Request body for updating variables
public struct VariablesUpdateRequest: Codable, Sendable {
    public var variables: [VariableUpdate]

    public init(variables: [VariableUpdate]) {
        self.variables = variables
    }
}

/// Single variable update action
public struct VariableUpdate: Codable, Sendable {
    public var action: String
    public var id: String
    public var codeSyntax: VariableCodeSyntax?

    public init(id: String, codeSyntax: VariableCodeSyntax) {
        action = "UPDATE"
        self.id = id
        self.codeSyntax = codeSyntax
    }
}

/// Platform-specific code syntax for Variables
/// Shown in Figma Dev Mode for each platform
public struct VariableCodeSyntax: Codable, Sendable {
    // swiftlint:disable identifier_name
    public var WEB: String?
    public var ANDROID: String?
    public var iOS: String?
    // swiftlint:enable identifier_name

    public init(iOS: String? = nil, android: String? = nil, web: String? = nil) {
        self.iOS = iOS
        ANDROID = android
        WEB = web
    }
}

/// Response from updating variables
public struct UpdateVariablesResponse: Codable, Sendable {
    public var status: Int?
    public var error: Bool?

    public init(status: Int? = nil, error: Bool? = nil) {
        self.status = status
        self.error = error
    }
}
