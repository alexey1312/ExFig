import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

public typealias APIResult<Value> = Swift.Result<Value, Error>

public protocol Client: Sendable {
    func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content
}

public class BaseClient: Client, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, config: URLSessionConfiguration) {
        self.baseURL = baseURL
        session = URLSession(configuration: config)
    }

    public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
        let request = endpoint.makeRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)
        return try endpoint.content(from: response, with: data)
    }
}
