import ExFigCore
import ToonFormat

/// Formats `AssetsValidatorWarning` for readable terminal display using TOON format
struct WarningFormatter {
    /// Format an AssetsValidatorWarning for terminal display
    /// - Parameter warning: The warning to format
    /// - Returns: A formatted multi-line string suitable for terminal output
    func format(_ warning: AssetsValidatorWarning) -> String {
        let assets = extractAssets(from: warning)

        guard !assets.isEmpty else {
            return ""
        }

        let header = buildHeader(for: warning, count: assets.count)
        let assetsSection = formatAssets(assets)

        return "\(header)\n\(assetsSection)"
    }

    // MARK: - Private Helpers

    private func extractAssets(from warning: AssetsValidatorWarning) -> [String] {
        switch warning {
        case let .lightAssetsNotFoundInDarkPalette(assets):
            assets
        case let .lightHCAssetsNotFoundInLightPalette(assets):
            assets
        case let .darkHCAssetsNotFoundInDarkPalette(assets):
            assets
        }
    }

    private func buildHeader(for warning: AssetsValidatorWarning, count: Int) -> String {
        let noun = count == 1 ? "asset" : "assets"

        switch warning {
        case .lightAssetsNotFoundInDarkPalette:
            return "\(count) \(noun) not found in dark palette (will be universal):"
        case .lightHCAssetsNotFoundInLightPalette:
            return "\(count) \(noun) not found in light palette (will be universal):"
        case .darkHCAssetsNotFoundInDarkPalette:
            return "\(count) \(noun) not found in dark palette (will be universal):"
        }
    }

    private func formatAssets(_ assets: [String]) -> String {
        // Use TOON format for the array header, then list each asset on its own line
        var result = "  assets[\(assets.count)]:"

        for asset in assets {
            result += "\n    \(asset)"
        }

        return result
    }
}
