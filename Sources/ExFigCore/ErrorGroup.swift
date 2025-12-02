import Foundation

public struct ErrorGroup: LocalizedError, Sendable {
    public private(set) var all: [any Error & Sendable]
    public var errorDescription: String? {
        all.compactMap {
            ($0 as? LocalizedError)?.errorDescription ?? $0.localizedDescription
        }.joined(separator: "\n")
    }

    public init(all: [any Error & Sendable] = []) {
        self.all = all
    }

    public mutating func append(_ error: any Error & Sendable) {
        all.append(error)
    }
}
