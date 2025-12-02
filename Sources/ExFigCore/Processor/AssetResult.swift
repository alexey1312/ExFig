import Foundation

public struct AssetResult<Success: Sendable, Error: Sendable>: Sendable {
    public var result: Result<Success, any Swift.Error & Sendable>
    public var warning: AssetsValidatorWarning?

    public func get() throws -> Success {
        try result.get()
    }

    public static func failure(_ error: any Swift.Error & Sendable) -> AssetResult<Success, Error> {
        AssetResult(result: .failure(error), warning: nil)
    }

    public static func success(_ data: Success) -> AssetResult<Success, Error> {
        AssetResult(result: .success(data), warning: nil)
    }

    public static func success(_ data: Success, warning: AssetsValidatorWarning?) -> AssetResult<Success, Error> {
        AssetResult(result: .success(data), warning: warning)
    }
}
