public enum DynamicTypeStyle: String, RawRepresentable, Sendable {
    case largeTitle = "Large Title"
    case title1 = "Title 1"
    case title2 = "Title 2"
    case title3 = "Title 3"
    case headline = "Headline"
    case body = "Body"
    case callout = "Callout"
    case subheadline = "Subhead"
    case footnote = "Footnote"
    case caption1 = "Caption 1"
    case caption2 = "Caption 2"

    public var uiKitStyleName: String {
        switch self {
        case .largeTitle:
            "largeTitle"
        case .title1:
            "title1"
        case .title2:
            "title2"
        case .title3:
            "title3"
        case .headline:
            "headline"
        case .body:
            "body"
        case .callout:
            "callout"
        case .subheadline:
            "subheadline"
        case .footnote:
            "footnote"
        case .caption1:
            "caption1"
        case .caption2:
            "caption2"
        }
    }

    public var swiftUIStyleName: String {
        switch self {
        case .largeTitle:
            "largeTitle"
        case .title1:
            "title"
        case .title2:
            "title2"
        case .title3:
            "title3"
        case .headline:
            "headline"
        case .body:
            "body"
        case .callout:
            "callout"
        case .subheadline:
            "subheadline"
        case .footnote:
            "footnote"
        case .caption1:
            "caption"
        case .caption2:
            "caption2"
        }
    }
}

public struct TextStyle: Asset, Sendable {
    public enum TextCase: String, Sendable {
        case original
        case uppercased
        case lowercased
    }

    public var name: String
    public var platform: Platform?
    public let fontName: String
    public let fontSize: Double
    public let fontStyle: DynamicTypeStyle?
    public let lineHeight: Double?
    public let letterSpacing: Double
    public let textCase: TextCase

    public init(
        name: String,
        platform: Platform? = nil,
        fontName: String,
        fontSize: Double,
        fontStyle: DynamicTypeStyle?,
        lineHeight: Double? = nil,
        letterSpacing: Double,
        textCase: TextCase = .original
    ) {
        self.name = name
        self.platform = platform
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontStyle = fontStyle
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.textCase = textCase
    }

    // MARK: Hashable

    public static func == (lhs: TextStyle, rhs: TextStyle) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
