import Foundation

/// Helper for loading JSON fixtures in tests.
enum FixtureLoader {
    /// Loads JSON data from a fixture file.
    /// - Parameter name: The fixture file name without extension.
    /// - Returns: The raw Data from the fixture file.
    static func loadData(_ name: String) throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw FixtureError.fileNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    /// Loads and decodes a JSON fixture.
    /// - Parameter name: The fixture file name without extension.
    /// - Returns: The decoded object of type T.
    static func load<T: Decodable>(_ name: String) throws -> T {
        let data = try loadData(name)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum FixtureError: Error, LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(name):
            "Fixture file not found: \(name).json"
        }
    }
}
