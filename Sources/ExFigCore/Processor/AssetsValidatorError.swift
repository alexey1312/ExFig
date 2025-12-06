import Foundation

enum AssetsValidatorError: LocalizedError, Sendable {
    case badName(name: String)
    case countMismatch(light: Int, dark: Int)
    case countMismatchLightHighContrastColors(light: Int, lightHC: Int)
    case countMismatchDarkHighContrastColors(dark: Int, darkHC: Int)
    case foundDuplicate(assetName: String)
    case secondAssetsNotFoundInFirstPalette(assets: [String], firstAssetsName: String, secondAssetsName: String)
    case descriptionMismatch(assetName: String, light: String, dark: String)

    // swiftlint:disable line_length
    var errorDescription: String? {
        let error = switch self {
        case let .badName(name):
            "Bad asset name «\(name)»"
        case let .countMismatch(light, dark):
            "The number of assets doesn't match. Light theme contains \(light), and dark \(dark)."
        case let .countMismatchLightHighContrastColors(light, lightHC):
            "The number of assets doesn't match. Light color palette contains \(light), and light high contrast color palette \(lightHC)."
        case let .countMismatchDarkHighContrastColors(dark, darkHC):
            "The number of assets doesn't match. Dark color palette contains \(dark), and dark high contrast color palette \(darkHC)."
        case let .secondAssetsNotFoundInFirstPalette(secondAsset, firstAssetsName, secondAssetsName):
            "\(firstAssetsName) theme doesn't contains following assets: \(secondAsset.joined(separator: ", ")), which exists in \(secondAssetsName.lowercased()) theme. Add these assets to \(firstAssetsName.lowercased()) theme and publish to the Team Library."
        case let .foundDuplicate(assetName):
            "Found duplicates of asset with name \(assetName). Remove duplicates."
        case let .descriptionMismatch(assetName, light, dark):
            "Asset with name \(assetName) have different description. In dark theme «\(dark)», in light theme «\(light)»"
        }
        return "❌ \(error)"
    }
    // swiftlint:enable line_length
}
