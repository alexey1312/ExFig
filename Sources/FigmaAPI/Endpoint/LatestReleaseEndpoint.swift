import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

public struct LatestReleaseEndpoint: BaseEndpoint {
    public typealias Content = LatestReleaseResponse

    public init() {}

    public func makeRequest(baseURL: URL) -> URLRequest {
        let url = baseURL.appendingPathComponent("repos/alexey1312/ExFig/releases/latest")
        return URLRequest(url: url)
    }
}

// MARK: - Response

public struct LatestReleaseResponse: Decodable {
    public let tagName: String
}
