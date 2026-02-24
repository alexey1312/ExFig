import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct VariablesEndpoint: BaseEndpoint {
    public typealias Content = VariablesMeta

    private let fileId: String

    public init(fileId: String) {
        self.fileId = fileId
    }

    func content(from root: VariablesResponse) -> Content {
        root.meta
    }

    public func makeRequest(baseURL: URL) -> URLRequest {
        let url = baseURL
            .appendingPathComponent("files")
            .appendingPathComponent(fileId)
            .appendingPathComponent("variables")
            .appendingPathComponent("local")
        return URLRequest(url: url)
    }
}
