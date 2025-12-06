import Foundation

public enum AssetsValidatorWarning: LocalizedError, Sendable {
    case lightAssetsNotFoundInDarkPalette(assets: [String])
    case lightHCAssetsNotFoundInLightPalette(assets: [String])
    case darkHCAssetsNotFoundInDarkPalette(assets: [String])

    // swiftlint:disable line_length
    public var errorDescription: String? {
        let warning = switch self {
        case let .lightAssetsNotFoundInDarkPalette(lights):
            "The following assets will be considered universal because they are not found in the dark palette: \(lights.joined(separator: ", "))"
        case let .lightHCAssetsNotFoundInLightPalette(lightsHC):
            "The following assets will be considered universal because they are not found in the light palette: \(lightsHC.joined(separator: ", "))"
        case let .darkHCAssetsNotFoundInDarkPalette(darkHC):
            "The following assets will be considered universal because they are not found in the dark palette: \(darkHC.joined(separator: ", "))"
        }
        return "⚠️ \(warning)"
    }
    // swiftlint:enable line_length
}
