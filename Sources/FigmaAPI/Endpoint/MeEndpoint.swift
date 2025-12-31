import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

/// Endpoint for fetching current authenticated user info.
/// Requires `current_user:read` OAuth scope.
public struct MeEndpoint: BaseEndpoint {
    public typealias Content = FigmaUser

    public init() {}

    public func makeRequest(baseURL: URL) -> URLRequest {
        let url = baseURL.appendingPathComponent("me")
        return URLRequest(url: url)
    }
}
