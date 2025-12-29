import CResvg
import Foundation

/// Errors that can occur during SVG rasterization with resvg
public enum ResvgError: LocalizedError, Equatable, Sendable {
    case notUtf8String
    case fileOpenFailed(path: String)
    case malformedGzip
    case elementsLimitReached
    case invalidSize
    case parsingFailed
    case unknownError(code: Int32)
    case emptyImage
    case svgExportFailed

    /// Creates a ResvgError from a resvg error code
    /// - Parameter code: The error code from resvg C API
    /// - Returns: The corresponding ResvgError, or nil if RESVG_OK
    static func fromCode(_ code: Int32) -> ResvgError? {
        switch code {
        case Int32(RESVG_OK.rawValue):
            nil
        case Int32(RESVG_ERROR_NOT_AN_UTF8_STR.rawValue):
            .notUtf8String
        case Int32(RESVG_ERROR_FILE_OPEN_FAILED.rawValue):
            .fileOpenFailed(path: "")
        case Int32(RESVG_ERROR_MALFORMED_GZIP.rawValue):
            .malformedGzip
        case Int32(RESVG_ERROR_ELEMENTS_LIMIT_REACHED.rawValue):
            .elementsLimitReached
        case Int32(RESVG_ERROR_INVALID_SIZE.rawValue):
            .invalidSize
        case Int32(RESVG_ERROR_PARSING_FAILED.rawValue):
            .parsingFailed
        default:
            .unknownError(code: code)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .notUtf8String:
            "SVG data is not a valid UTF-8 string"
        case let .fileOpenFailed(path):
            "Failed to open SVG file: \(path)"
        case .malformedGzip:
            "Compressed SVG is not valid GZip format"
        case .elementsLimitReached:
            "SVG has more than 1,000,000 elements (security limit)"
        case .invalidSize:
            "SVG has invalid size (width/height <= 0 or missing viewBox)"
        case .parsingFailed:
            "Failed to parse SVG data"
        case let .unknownError(code):
            "Unknown resvg error (code: \(code))"
        case .emptyImage:
            "SVG has no renderable elements"
        case .svgExportFailed:
            "Failed to export normalized SVG"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notUtf8String:
            "Ensure the SVG file is encoded as UTF-8"
        case .fileOpenFailed:
            "Check that the file path exists and is readable"
        case .malformedGzip:
            "Re-export the SVG from Figma without compression"
        case .elementsLimitReached:
            "Split the SVG into smaller files"
        case .invalidSize:
            "Ensure the SVG has valid width, height, or viewBox attributes"
        case .parsingFailed:
            "Re-export the SVG from Figma or validate the SVG syntax"
        case .unknownError:
            nil
        case .emptyImage:
            "Ensure the SVG contains visible elements"
        case .svgExportFailed:
            "SVG may contain unsupported features"
        }
    }
}
