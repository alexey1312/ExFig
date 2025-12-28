import ExFigKit
import Foundation

/// Error types for marker-based file updates.
public enum MarkerFileUpdaterError: LocalizedError, Equatable {
    /// The specified marker was not found in the file.
    case markerNotFound(marker: String, file: String)

    /// Start marker appears after end marker in the file.
    case markersOutOfOrder(file: String)

    /// The target file does not exist.
    case fileNotFound(path: String)

    public var errorDescription: String? {
        switch self {
        case let .markerNotFound(marker, file):
            "Marker '\(marker)' not found in \(file)"
        case let .markersOutOfOrder(file):
            "Start marker appears after end marker in \(file)"
        case let .fileNotFound(path):
            "File not found: \(path)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case let .markerNotFound(marker, _):
            "Add marker comment: \(marker)"
        case .markersOutOfOrder:
            "Ensure start marker appears before end marker"
        case .fileNotFound:
            "Create the file or use autoCreateMarkers: true"
        }
    }
}

/// Updates file content between markers, preserving content outside markers.
///
/// This struct provides functionality to update XML or other text files by replacing
/// content between start and end marker comments while preserving all other content.
///
/// Example markers format:
/// ```xml
/// <!-- FIGMA COLORS MARKER START: Theme.App -->
/// <!-- FIGMA COLORS MARKER END: Theme.App -->
/// ```
///
/// Thread-safe and Sendable for use in concurrent batch processing.
public struct MarkerFileUpdater: Sendable {
    /// Base marker start text (without theme name).
    public let markerStart: String

    /// Base marker end text (without theme name).
    public let markerEnd: String

    /// Theme name to include in markers.
    public let themeName: String

    /// Creates a marker file updater.
    /// - Parameters:
    ///   - markerStart: Base start marker text (e.g., "FIGMA COLORS MARKER START")
    ///   - markerEnd: Base end marker text (e.g., "FIGMA COLORS MARKER END")
    ///   - themeName: Theme name to include in marker (e.g., "Theme.App")
    public init(markerStart: String, markerEnd: String, themeName: String) {
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.themeName = themeName
    }

    /// Full start marker string including theme name in XML comment format.
    public var fullStartMarker: String {
        "<!-- \(markerStart): \(themeName) -->"
    }

    /// Full end marker string including theme name in XML comment format.
    public var fullEndMarker: String {
        "<!-- \(markerEnd): \(themeName) -->"
    }

    /// Updates content between markers in a file.
    ///
    /// - Parameters:
    ///   - content: New content to insert between markers (without marker lines)
    ///   - fileURL: URL of the file to update
    ///   - autoCreate: If true, create file with markers if it doesn't exist
    ///   - templateContent: Template content for new file when autoCreate is true
    /// - Returns: Updated file content ready to be written
    /// - Throws: MarkerFileUpdaterError if markers not found or file issues
    public func update(
        content: String,
        in fileURL: URL,
        autoCreate: Bool = false,
        templateContent: String? = nil
    ) throws -> String {
        let filePath = fileURL.path

        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath) else {
            if autoCreate, let template = templateContent {
                return template
            }
            throw MarkerFileUpdaterError.fileNotFound(path: filePath)
        }

        // Read existing content
        let existingContent = try String(contentsOf: fileURL, encoding: .utf8)

        return try update(content: content, in: existingContent, fileName: fileURL.lastPathComponent)
    }

    /// Updates content between markers in a string.
    ///
    /// - Parameters:
    ///   - content: New content to insert between markers (without marker lines)
    ///   - existingContent: Existing file content
    ///   - fileName: File name for error messages
    /// - Returns: Updated content with new content between markers
    /// - Throws: MarkerFileUpdaterError if markers not found or out of order
    public func update(
        content: String,
        in existingContent: String,
        fileName: String
    ) throws -> String {
        let startMarker = fullStartMarker
        let endMarker = fullEndMarker

        // Find marker positions
        guard let startRange = existingContent.range(of: startMarker) else {
            throw MarkerFileUpdaterError.markerNotFound(marker: startMarker, file: fileName)
        }

        guard let endRange = existingContent.range(of: endMarker) else {
            throw MarkerFileUpdaterError.markerNotFound(marker: endMarker, file: fileName)
        }

        // Verify order (start must come before end)
        guard startRange.upperBound <= endRange.lowerBound else {
            throw MarkerFileUpdaterError.markersOutOfOrder(file: fileName)
        }

        // Build new content:
        // [content before start marker][start marker]\n[new content]\n[end marker][content after]
        let beforeMarker = String(existingContent[..<startRange.upperBound])
        let afterMarker = String(existingContent[endRange.lowerBound...])

        // Handle content formatting - ensure proper newlines
        let formattedContent = if content.isEmpty {
            "\n"
        } else {
            "\n" + content + "\n"
        }

        return beforeMarker + formattedContent + afterMarker
    }

    /// Creates a minimal file template with markers.
    ///
    /// - Parameter baseTemplate: Base XML structure with {{START_MARKER}} and {{END_MARKER}} placeholders
    /// - Returns: File content with markers inserted
    public func createTemplate(baseTemplate: String) -> String {
        baseTemplate
            .replacingOccurrences(of: "{{START_MARKER}}", with: fullStartMarker)
            .replacingOccurrences(of: "{{END_MARKER}}", with: fullEndMarker)
    }
}
