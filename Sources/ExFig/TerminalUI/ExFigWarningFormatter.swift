/// Formats ExFigWarning for terminal display using TOON format.
///
/// Uses two styles:
/// - **Compact**: Single line `key=value` pairs for simple warnings
/// - **Multiline**: Indented key-value pairs for warnings with multiple fields
struct ExFigWarningFormatter {
    /// Format an ExFigWarning for terminal display.
    /// - Parameter warning: The warning to format.
    /// - Returns: A formatted string suitable for terminal output.
    func format(_ warning: ExFigWarning) -> String {
        switch warning {
        // Compact format warnings
        case .configMissing, .composeRequirementMissing, .noConfigsFound,
             .noValidConfigs, .xcodeProjectUpdateFailed, .checkpointExpired,
             .checkpointPathMismatch, .retrying, .preFetchPartialFailure,
             .preFetchComponentsPartialFailure, .preFetchNodesPartialFailure,
             .granularCacheWithoutCache, .themeAttributesFileNotFound,
             .themeAttributesMarkerNotFound, .themeAttributesNameCollision,
             .heicUnavailableFallingBackToPng:
            formatCompact(warning)

        // Multiline format warnings
        case let .noAssetsFound(assetType, frameName):
            formatNoAssetsFound(assetType: assetType, frameName: frameName)

        case let .invalidConfigsSkipped(count):
            formatInvalidConfigsSkipped(count: count)

        case let .webIconsMissingSVGData(count, names):
            formatWebIconsMissingSVGData(count: count, names: names)

        case let .webIconsConversionFailed(count, names):
            formatWebIconsConversionFailed(count: count, names: names)
        }
    }

    // MARK: - Compact Formatters

    // swiftlint:disable:next cyclomatic_complexity
    private func formatCompact(_ warning: ExFigWarning) -> String {
        switch warning {
        case let .configMissing(platform, assetType):
            "Config missing: platform=\(platform), assetType=\(assetType)"

        case let .composeRequirementMissing(requirement):
            "Compose export skipped: missing=\(requirement)"

        case .noConfigsFound:
            "No config files found"

        case .noValidConfigs:
            "No valid ExFig config files found"

        case .xcodeProjectUpdateFailed:
            "Xcode project update incomplete: some file references could not be added"

        case .checkpointExpired:
            "Checkpoint expired: older than 24h, starting fresh"

        case .checkpointPathMismatch:
            "Checkpoint invalid: paths don't match current request, starting fresh"

        case let .retrying(attempt, maxAttempts, error, delay):
            "Retrying: attempt=\(attempt)/\(maxAttempts), error=\(error), delay=\(delay)"

        case let .preFetchPartialFailure(failed, total):
            "Pre-fetch partial failure: \(failed)/\(total) files failed, using fallback"

        case let .preFetchComponentsPartialFailure(failed, total):
            "Pre-fetch components partial failure: \(failed)/\(total) files failed, using fallback"

        case let .preFetchNodesPartialFailure(error):
            "Pre-fetch nodes failed: \(error), using fallback"

        case .granularCacheWithoutCache:
            "--experimental-granular-cache ignored: requires --cache flag"

        case let .themeAttributesFileNotFound(file):
            "Theme attributes skipped: file not found, path=\(file)"

        case let .themeAttributesMarkerNotFound(file, marker):
            "Theme attributes skipped: marker not found, file=\(file), marker=\(marker)"

        case let .themeAttributesNameCollision(count, collisions):
            formatThemeAttributesCollision(count: count, collisions: collisions)

        case .heicUnavailableFallingBackToPng:
            "HEIC encoding unavailable on this platform, using PNG format instead"

        // Multiline cases handled in main format() method
        case .noAssetsFound, .invalidConfigsSkipped, .webIconsMissingSVGData, .webIconsConversionFailed:
            fatalError("Multiline warnings should not reach formatCompact")
        }
    }

    // MARK: - Multiline Formatters

    private func formatNoAssetsFound(assetType: String, frameName: String) -> String {
        """
        No assets found:
          type: \(assetType)
          frame: \(frameName)
        """
    }

    private func formatInvalidConfigsSkipped(count: Int) -> String {
        let noun = count == 1 ? "file" : "files"
        return """
        Invalid configs skipped:
          count: \(count) \(noun)
        """
    }

    private func formatWebIconsMissingSVGData(count: Int, names: [String]) -> String {
        let preview = formatNamePreview(names)
        return """
        TSX components skipped (missing SVG data):
          count: \(count)
          icons: \(preview)
        """
    }

    private func formatWebIconsConversionFailed(count: Int, names: [String]) -> String {
        let preview = formatNamePreview(names)
        return """
        TSX components skipped (JSX conversion failed):
          count: \(count)
          icons: \(preview)
        """
    }

    /// Formats a list of names as a preview string, truncating if too long.
    private func formatNamePreview(_ names: [String], maxNames: Int = 3) -> String {
        if names.count <= maxNames {
            return names.joined(separator: ", ")
        }
        let preview = names.prefix(maxNames).joined(separator: ", ")
        let remaining = names.count - maxNames
        return "\(preview), +\(remaining) more"
    }

    private func formatThemeAttributesCollision(
        count: Int,
        collisions: [ThemeAttributeCollisionInfo]
    ) -> String {
        let preview = collisions.prefix(3).map { "\($0.discarded)→\($0.attr)" }.joined(separator: ", ")
        let suffix = count > 3 ? ", +\(count - 3) more" : ""
        return "Theme attributes collision: \(count) skipped, \(preview)\(suffix)"
    }
}
