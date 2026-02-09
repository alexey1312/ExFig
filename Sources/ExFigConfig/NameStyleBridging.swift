import ExFigCore

public extension Common.NameStyle {
    /// Converts PKL `Common.NameStyle` to `ExFigCore.NameStyle`.
    ///
    /// Raw values match between the two enums (verified by `EnumBridgingTests`).
    var coreNameStyle: NameStyle {
        guard let style = NameStyle(rawValue: rawValue) else {
            preconditionFailure(
                "Unsupported NameStyle '\(rawValue)'. "
                    + "Valid: \(NameStyle.allCases.map(\.rawValue)). "
                    + "This may indicate a PKL schema version mismatch."
            )
        }
        return style
    }
}
