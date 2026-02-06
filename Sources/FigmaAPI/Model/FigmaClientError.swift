import Foundation

struct FigmaClientError: Decodable, LocalizedError, Sendable {
    let status: Int
    let err: String

    var errorDescription: String? {
        switch err {
        case "Not found":
            // swiftlint:disable:next line_length
            "Figma file not found. Check lightFileId and darkFileId (if your project supports dark mode) in the config file. Also verify that your personal access token is valid and hasn't expired."
        default:
            "Figma API: \(err)"
        }
    }
}
