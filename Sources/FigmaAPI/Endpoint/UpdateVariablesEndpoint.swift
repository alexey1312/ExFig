import ExFigCore
import Foundation
#if canImport(FoundationNetworking)
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

    public func makeRequest(baseURL: URL) throws -> URLRequest {
        let url = baseURL
            .appendingPathComponent("files")
            .appendingPathComponent(fileId)
            .appendingPathComponent("variables")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONCodec.encode(body)

        return request
    }
}
