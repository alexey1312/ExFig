import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

/// Endpoint for updating Figma Variables codeSyntax
/// POST /v1/files/:file_key/variables
public struct UpdateVariablesEndpoint: BaseEndpoint {
    public typealias Content = UpdateVariablesResponse

    private let fileId: String
    private let body: VariablesUpdateRequest

    public init(fileId: String, body: VariablesUpdateRequest) {
        self.fileId = fileId
        self.body = body
    }

    public func makeRequest(baseURL: URL) -> URLRequest {
        let url = baseURL
            .appendingPathComponent("files")
            .appendingPathComponent(fileId)
            .appendingPathComponent("variables")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        request.httpBody = try! encoder.encode(body)

        return request
    }
}
