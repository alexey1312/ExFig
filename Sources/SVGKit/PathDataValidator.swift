import Foundation
import Logging

/// Result of path data validation
public struct PathDataValidationResult: Sendable, Equatable {
    /// Length of pathData in characters
    public let charLength: Int
    /// Length of pathData in UTF-8 bytes
    public let byteLength: Int
    /// True if pathData exceeds Android Lint threshold (800 chars)
    public let exceedsLintThreshold: Bool
    /// True if pathData exceeds AAPT critical limit (32,767 bytes)
    public let exceedsCriticalLimit: Bool

    public init(charLength: Int, byteLength: Int) {
        self.charLength = charLength
        self.byteLength = byteLength
        exceedsLintThreshold = charLength > PathDataValidator.lintThreshold
        exceedsCriticalLimit = byteLength > PathDataValidator.criticalThreshold
    }
}

/// Validation issue for a specific path
public struct PathValidationIssue: Sendable {
    public let pathName: String
    public let result: PathDataValidationResult
    public let isCritical: Bool

    public init(pathName: String, result: PathDataValidationResult) {
        self.pathName = pathName
        self.result = result
        isCritical = result.exceedsCriticalLimit
    }
}

/// Validates Android VectorDrawable pathData for length constraints
///
/// Android has two important limits for pathData strings:
/// - **Lint threshold (800 chars)**: Android Lint warns about performance impact
/// - **Critical limit (32,767 bytes)**: AAPT StringPool uses signed 16-bit int,
///   causing STRING_TOO_LARGE error during build
///
/// Sources:
/// - https://googlesamples.github.io/android-custom-lint-rules/checks/VectorPath.md.html
/// - https://brightinventions.pl/blog/string-too-large-in-android-resources/
public struct PathDataValidator: Sendable {
    /// Android Lint threshold for pathData length warning (characters)
    public static let lintThreshold = 800

    /// AAPT critical limit for any XML string attribute (bytes)
    /// StringPool.cpp uses signed 16-bit integer for string length
    public static let criticalThreshold = 32767

    private let logger = Logger(label: "com.alexey1312.exfig.path-validator")

    public init() {}

    /// Validates a single pathData string
    /// - Parameter pathData: The path data string to validate
    /// - Returns: Validation result with length metrics and threshold flags
    public func validate(pathData: String) -> PathDataValidationResult {
        let charLength = pathData.count
        let byteLength = pathData.utf8.count
        return PathDataValidationResult(charLength: charLength, byteLength: byteLength)
    }

    /// Validates multiple paths and returns issues found
    /// - Parameter paths: Array of tuples (pathName, pathData)
    /// - Returns: Array of validation issues (only paths that exceed thresholds)
    public func validatePaths(_ paths: [(name: String, pathData: String)]) -> [PathValidationIssue] {
        paths.compactMap { name, pathData in
            let result = validate(pathData: pathData)
            guard result.exceedsLintThreshold || result.exceedsCriticalLimit else {
                return nil
            }
            return PathValidationIssue(pathName: name, result: result)
        }
    }

    /// Logs validation issues with appropriate severity
    /// - Parameters:
    ///   - issues: Array of validation issues to log
    ///   - iconName: Name of the icon being processed (for context)
    ///   - logWarnings: If true, logs lint threshold warnings (>800 chars). Default is false.
    public func logIssues(_ issues: [PathValidationIssue], iconName: String, logWarnings: Bool = false) {
        for issue in issues {
            if issue.isCritical {
                logger.error(
                    """
                    pathData exceeds 32,767 bytes (\(issue.result.byteLength) bytes) \
                    in \(iconName)/\(issue.pathName). \
                    This will cause STRING_TOO_LARGE error during Android build. \
                    Consider simplifying the path in Figma or using raster format.
                    """
                )
            } else if logWarnings, issue.result.exceedsLintThreshold {
                logger.warning(
                    """
                    pathData exceeds 800 chars (\(issue.result.charLength) chars) \
                    in \(iconName)/\(issue.pathName). \
                    This may cause performance issues. Consider simplifying in Figma.
                    """
                )
            }
        }
    }

    /// Validates a ParsedSVG and returns all issues
    /// - Parameters:
    ///   - svg: The parsed SVG to validate
    ///   - iconName: Name of the icon (for logging context)
    /// - Returns: Array of validation issues
    public func validate(svg: ParsedSVG, iconName: String) -> [PathValidationIssue] {
        var pathsToValidate: [(name: String, pathData: String)] = []
        var pathIndex = 0

        // Collect paths from elements
        if !svg.elements.isEmpty {
            collectPaths(from: svg.elements, into: &pathsToValidate, pathIndex: &pathIndex)
        } else {
            // Fallback for legacy structure
            for path in svg.paths {
                pathsToValidate.append(("path_\(pathIndex)", path.pathData))
                pathIndex += 1
            }
            if let groups = svg.groups {
                for group in groups {
                    collectPathsFromGroup(group, into: &pathsToValidate, pathIndex: &pathIndex)
                }
            }
        }

        return validatePaths(pathsToValidate)
    }

    private func collectPaths(
        from elements: [SVGElement],
        into paths: inout [(name: String, pathData: String)],
        pathIndex: inout Int
    ) {
        for element in elements {
            switch element {
            case let .path(path):
                paths.append(("path_\(pathIndex)", path.pathData))
                pathIndex += 1
            case let .group(group):
                collectPaths(from: group.elements, into: &paths, pathIndex: &pathIndex)
                // Also check legacy paths array
                for path in group.paths {
                    paths.append(("path_\(pathIndex)", path.pathData))
                    pathIndex += 1
                }
            }
        }
    }

    private func collectPathsFromGroup(
        _ group: SVGGroup,
        into paths: inout [(name: String, pathData: String)],
        pathIndex: inout Int
    ) {
        for path in group.paths {
            paths.append(("path_\(pathIndex)", path.pathData))
            pathIndex += 1
        }
        for child in group.children {
            collectPathsFromGroup(child, into: &paths, pathIndex: &pathIndex)
        }
    }
}

// MARK: - Validation Summary

/// Summary of path validation across multiple icons
public struct PathValidationSummary: Sendable {
    public let totalIcons: Int
    public let iconsWithWarnings: Int
    public let iconsWithCriticalErrors: Int
    public let allIssues: [(iconName: String, issues: [PathValidationIssue])]

    public var hasWarnings: Bool { iconsWithWarnings > 0 }
    public var hasCriticalErrors: Bool { iconsWithCriticalErrors > 0 }

    public init(results: [(iconName: String, issues: [PathValidationIssue])]) {
        totalIcons = results.count
        allIssues = results.filter { !$0.issues.isEmpty }
        iconsWithWarnings = results.filter { iconResult in
            iconResult.issues.contains { $0.result.exceedsLintThreshold }
        }.count
        iconsWithCriticalErrors = results.filter { iconResult in
            iconResult.issues.contains { $0.isCritical }
        }.count
    }
}
