import ExFigCore

public extension Common.NameStyle {
    /// Converts PKL `Common.NameStyle` to `ExFigCore.NameStyle`.
    ///
    /// Raw values match between the two enums (verified by `EnumBridgingTests`).
    var coreNameStyle: NameStyle {
        // swiftlint:disable:next force_unwrapping
        NameStyle(rawValue: rawValue)!
    }
}
