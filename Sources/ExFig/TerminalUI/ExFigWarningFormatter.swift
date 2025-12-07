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

        // Multiline format warnings
        case let .noAssetsFound(assetType, frameName):
            formatNoAssetsFound(assetType: assetType, frameName: frameName)

        case let .invalidConfigsSkipped(count):
            formatInvalidConfigsSkipped(count: count)
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
}
