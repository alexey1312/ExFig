// swiftlint:disable file_length
import Foundation
#if os(Linux)
    import FoundationXML
#endif

/// Represents a parsed SVG document ready for ImageVector conversion
public struct ParsedSVG: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let viewportWidth: Double
    public let viewportHeight: Double
    public let paths: [SVGPath]
    public let groups: [SVGGroup]?
    public let linearGradients: [String: SVGLinearGradient]
    public let radialGradients: [String: SVGRadialGradient]

    public init(
        width: Double,
        height: Double,
        viewportWidth: Double,
        viewportHeight: Double,
        paths: [SVGPath],
        groups: [SVGGroup]? = nil,
        linearGradients: [String: SVGLinearGradient] = [:],
        radialGradients: [String: SVGRadialGradient] = [:]
    ) {
        self.width = width
        self.height = height
        self.viewportWidth = viewportWidth
        self.viewportHeight = viewportHeight
        self.paths = paths
        self.groups = groups
        self.linearGradients = linearGradients
        self.radialGradients = radialGradients
    }
}

/// Represents a single path element in SVG
public struct SVGPath: Equatable, Sendable {
    public let pathData: String
    public let commands: [SVGPathCommand]
    public let fill: SVGColor?
    public let fillType: SVGFill
    public let stroke: SVGColor?
    public let strokeWidth: Double?
    public let strokeLineCap: StrokeCap?
    public let strokeLineJoin: StrokeJoin?
    public let strokeDashArray: [Double]?
    public let strokeDashOffset: Double?
    public let fillRule: FillRule?
    public let opacity: Double?

    public init(
        pathData: String,
        commands: [SVGPathCommand],
        fill: SVGColor?,
        fillType: SVGFill = .none,
        stroke: SVGColor?,
        strokeWidth: Double?,
        strokeLineCap: StrokeCap?,
        strokeLineJoin: StrokeJoin?,
        strokeDashArray: [Double]? = nil,
        strokeDashOffset: Double? = nil,
        fillRule: FillRule?,
        opacity: Double?
    ) {
        self.pathData = pathData
        self.commands = commands
        self.fill = fill
        self.fillType = fillType
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.strokeDashArray = strokeDashArray
        self.strokeDashOffset = strokeDashOffset
        self.fillRule = fillRule
        self.opacity = opacity
    }

    public enum StrokeCap: String, Sendable {
        case butt
        case round
        case square
    }

    public enum StrokeJoin: String, Sendable {
        case miter
        case round
        case bevel
    }

    public enum FillRule: String, Sendable {
        case nonZero
        case evenOdd
    }
}

/// Represents a color in SVG
public struct SVGColor: Equatable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: Double

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Parses a color string (hex, rgb, or named color)
    public static func parse(_ string: String) -> SVGColor? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        if trimmed == "none" || trimmed.isEmpty {
            return nil
        }

        if trimmed == "currentColor" {
            return SVGColor(red: 0, green: 0, blue: 0) // Default to black
        }

        // Hex color
        if trimmed.hasPrefix("#") {
            return parseHex(trimmed)
        }

        // rgb() or rgba() function
        if trimmed.hasPrefix("rgb") {
            return parseRGB(trimmed)
        }

        // Named colors
        return namedColor(trimmed)
    }

    private static func parseHex(_ hex: String) -> SVGColor? {
        var hexString = hex.trimmingCharacters(in: .whitespaces)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        switch hexString.count {
        case 3: // RGB shorthand
            let r = UInt8((rgb >> 8 & 0xF) * 17)
            let g = UInt8((rgb >> 4 & 0xF) * 17)
            let b = UInt8((rgb & 0xF) * 17)
            return SVGColor(red: r, green: g, blue: b)
        case 6: // RRGGBB
            let r = UInt8(rgb >> 16 & 0xFF)
            let g = UInt8(rgb >> 8 & 0xFF)
            let b = UInt8(rgb & 0xFF)
            return SVGColor(red: r, green: g, blue: b)
        case 8: // RRGGBBAA
            let r = UInt8(rgb >> 24 & 0xFF)
            let g = UInt8(rgb >> 16 & 0xFF)
            let b = UInt8(rgb >> 8 & 0xFF)
            let a = Double(rgb & 0xFF) / 255.0
            return SVGColor(red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }

    private static func parseRGB(_ rgb: String) -> SVGColor? {
        let pattern = #"rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                  in: rgb,
                  options: [],
                  range: NSRange(rgb.startIndex..., in: rgb)
              )
        else {
            return nil
        }

        let getValue: (Int) -> String? = { index in
            guard let range = Range(match.range(at: index), in: rgb) else { return nil }
            return String(rgb[range])
        }

        guard let rStr = getValue(1), let r = UInt8(rStr),
              let gStr = getValue(2), let g = UInt8(gStr),
              let bStr = getValue(3), let b = UInt8(bStr)
        else {
            return nil
        }

        let alpha = getValue(4).flatMap { Double($0) } ?? 1.0
        return SVGColor(red: r, green: g, blue: b, alpha: alpha)
    }

    private static func namedColor(_ name: String) -> SVGColor? {
        let colors: [String: (UInt8, UInt8, UInt8)] = [
            "black": (0, 0, 0),
            "white": (255, 255, 255),
            "red": (255, 0, 0),
            "green": (0, 128, 0),
            "blue": (0, 0, 255),
            "yellow": (255, 255, 0),
            "cyan": (0, 255, 255),
            "magenta": (255, 0, 255),
            "gray": (128, 128, 128),
            "grey": (128, 128, 128),
            "orange": (255, 165, 0),
            "purple": (128, 0, 128),
            "pink": (255, 192, 203),
            "brown": (165, 42, 42),
            "transparent": (0, 0, 0),
        ]

        guard let (r, g, b) = colors[name.lowercased()] else {
            return nil
        }

        let alpha: Double = name.lowercased() == "transparent" ? 0.0 : 1.0
        return SVGColor(red: r, green: g, blue: b, alpha: alpha)
    }

    /// Returns hex string representation (0xAARRGGBB format for Compose)
    public var composeHex: String {
        let alphaInt = UInt8(alpha * 255)
        return String(format: "0x%02X%02X%02X%02X", alphaInt, red, green, blue)
    }
}

/// Parses SVG files into ParsedSVG structures
public final class SVGParser: @unchecked Sendable { // swiftlint:disable:this type_body_length
    private static let inheritableAttributes = [
        "fill", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin",
        "stroke-dasharray", "stroke-dashoffset", "fill-rule", "opacity",
    ]

    private let pathParser = SVGPathParser()

    /// Storage for clip-path definitions
    private var clipPathDefs: [String: String] = [:]

    /// Storage for linear gradient definitions
    private var linearGradientDefs: [String: SVGLinearGradient] = [:]

    /// Storage for radial gradient definitions
    private var radialGradientDefs: [String: SVGRadialGradient] = [:]

    /// Storage for <symbol> and reusable element definitions (for <use> support)
    private var symbolDefs: [String: XMLElement] = [:]

    /// Storage for all elements with id attribute (for <use> support)
    private var elementDefs: [String: XMLElement] = [:]

    /// Storage for CSS styles from <style> blocks: selector -> properties
    private var cssStyles: [String: [String: String]] = [:]

    /// Current viewBox for coordinate resolution
    private var currentViewBox: (minX: Double, minY: Double, width: Double, height: Double)?

    /// Maximum depth for resolving nested <use> references
    private let maxUseDepth = 10

    public init() {}

    // MARK: - Cross-Platform XML Helpers

    /// Returns the local name of an element, stripping any namespace prefix.
    /// On Linux with FoundationXML, `name` may include namespace prefix (e.g., "svg:path"),
    /// while `localName` gives just "path".
    private func elementName(_ element: XMLElement) -> String? {
        element.localName ?? element.name
    }

    /// Finds child elements matching a given local name.
    /// Works around Linux FoundationXML issues where `elements(forName:)` may not work
    /// correctly with default namespaces.
    private func childElements(of element: XMLElement, named name: String) -> [XMLElement] {
        (element.children ?? []).compactMap { child -> XMLElement? in
            guard let childElement = child as? XMLElement,
                  elementName(childElement) == name
            else {
                return nil
            }
            return childElement
        }
    }

    /// Gets an attribute value from an element.
    /// Works around Linux FoundationXML issue where `attribute(forName:)` returns nil
    /// when the document has a default xmlns namespace.
    /// See: https://github.com/swiftlang/swift-corelibs-foundation/issues/4943
    private func attributeValue(_ element: XMLElement, forName name: String) -> String? {
        // First try the standard method (works on macOS)
        if let value = element.attribute(forName: name)?.stringValue {
            return value
        }
        // Fallback: iterate through attributes manually (workaround for Linux)
        for attribute in element.attributes ?? [] {
            if attribute.name == name || attribute.localName == name {
                return attribute.stringValue
            }
        }
        return nil
    }

    /// Parses SVG data into a ParsedSVG structure
    /// - Parameter data: Raw SVG file data
    /// - Returns: Parsed SVG representation
    public func parse(_ data: Data) throws -> ParsedSVG {
        let document = try XMLDocument(data: data, options: [])
        guard let root = document.rootElement(), elementName(root) == "svg" else {
            throw SVGParserError.invalidSVGRoot
        }

        // Reset definitions for this parse
        clipPathDefs = [:]
        linearGradientDefs = [:]
        radialGradientDefs = [:]
        symbolDefs = [:]
        elementDefs = [:]
        cssStyles = [:]

        // Index all elements with id for <use> resolution
        indexElementsWithId(from: root)

        // Parse CSS <style> blocks
        parseStyleElements(from: root)

        // Parse dimensions
        let (width, height) = try parseDimensions(from: root)
        let viewBoxValues = parseViewBoxValues(from: root)
        let (viewportWidth, viewportHeight) = viewBoxValues.map { _, _, w, h in (w, h) } ?? (width, height)

        // Store viewBox for gradient coordinate resolution
        currentViewBox = viewBoxValues

        // Parse defs for clip-paths and gradients
        try parseDefsForClipPaths(from: root)
        parseDefsForGradients(from: root)

        // Parse all path elements (flattened for backward compatibility)
        var paths: [SVGPath] = []
        try collectPaths(from: root, into: &paths, inheritedAttributes: [:])

        // Parse groups with structure preserved
        var groups: [SVGGroup] = []
        try collectGroups(from: root, into: &groups, inheritedAttributes: [:])

        return ParsedSVG(
            width: width,
            height: height,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            paths: paths,
            groups: groups.isEmpty ? nil : groups,
            linearGradients: linearGradientDefs,
            radialGradients: radialGradientDefs
        )
    }

    /// Parses SVG from a file URL
    /// - Parameter url: URL to the SVG file
    /// - Returns: Parsed SVG representation
    public func parse(contentsOf url: URL) throws -> ParsedSVG {
        let data = try Data(contentsOf: url)
        return try parse(data)
    }

    // MARK: - Private Methods

    private func parseDimensions(from element: XMLElement) throws -> (Double, Double) {
        // Try to get width and height attributes
        if let widthStr = attributeValue(element, forName: "width"),
           let heightStr = attributeValue(element, forName: "height")
        {
            let width = parseLength(widthStr)
            let height = parseLength(heightStr)
            if let w = width, let h = height {
                return (w, h)
            }
        }

        // Fall back to viewBox
        if let (_, _, w, h) = parseViewBoxValues(from: element) {
            return (w, h)
        }

        // Default to 24x24 (common icon size)
        return (24, 24)
    }

    private func parseViewBox(from element: XMLElement) -> (Double, Double)? {
        guard let (_, _, w, h) = parseViewBoxValues(from: element) else {
            return nil
        }
        return (w, h)
    }

    private func parseViewBoxValues(from element: XMLElement) -> (Double, Double, Double, Double)? {
        guard let viewBox = attributeValue(element, forName: "viewBox") else {
            return nil
        }

        let components = viewBox
            .split { $0.isWhitespace || $0 == "," }
            .compactMap { Double($0) }

        guard components.count == 4 else {
            return nil
        }

        return (components[0], components[1], components[2], components[3])
    }

    private func parseLength(_ string: String) -> Double? {
        var str = string.trimmingCharacters(in: .whitespaces)

        // Remove unit suffixes
        for unit in ["px", "pt", "em", "rem", "%", "mm", "cm", "in"] where str.hasSuffix(unit) {
            str = String(str.dropLast(unit.count))
            break
        }

        return Double(str)
    }

    private func collectPaths(
        from element: XMLElement,
        into paths: inout [SVGPath],
        inheritedAttributes: [String: String]
    ) throws {
        let attrs = mergeAttributes(from: element, with: inheritedAttributes)
        let name = elementName(element)

        // Skip <defs> - elements there are only used via <use> references
        if name == "defs" {
            return
        }

        // Process <use> elements
        if name == "use" {
            let (usePaths, _) = try resolveUseElement(element, inheritedAttributes: attrs)
            paths.append(contentsOf: usePaths)
            return // Don't recurse into <use> children
        }

        // Process path elements
        if name == "path" {
            if let pathData = attributeValue(element, forName: "d") {
                let path = try createSVGPath(pathData: pathData, attributes: attrs)
                paths.append(path)
            }
        }

        // Process other shape elements (convert to paths)
        if let path = try convertShapeToPath(element, attributes: attrs) {
            paths.append(path)
        }

        // Recursively process child elements
        for child in element.children ?? [] {
            if let childElement = child as? XMLElement {
                try collectPaths(from: childElement, into: &paths, inheritedAttributes: attrs)
            }
        }
    }

    private func parseStyleAttribute(_ style: String) -> [String: String] {
        var result: [String: String] = [:]
        let declarations = style.split(separator: ";")
        for declaration in declarations {
            let parts = declaration.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let property = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                result[property] = value
            }
        }
        return result
    }

    private func createSVGPath(pathData: String, attributes: [String: String]) throws -> SVGPath {
        let commands = try pathParser.parse(pathData)

        let fillValue = attributes["fill"]
        let fill = fillValue.flatMap { SVGColor.parse($0) }
        let fillType = resolveFill(fillValue)
        let stroke = attributes["stroke"].flatMap { SVGColor.parse($0) }
        let strokeWidth = attributes["stroke-width"].flatMap { Double($0) }

        let strokeLineCap: SVGPath.StrokeCap? = attributes["stroke-linecap"].flatMap {
            SVGPath.StrokeCap(rawValue: $0)
        }
        let strokeLineJoin: SVGPath.StrokeJoin? = attributes["stroke-linejoin"].flatMap {
            SVGPath.StrokeJoin(rawValue: $0)
        }

        let strokeDashArray = parseStrokeDashArray(attributes["stroke-dasharray"])
        let strokeDashOffset = attributes["stroke-dashoffset"].flatMap { Double($0) }

        let fillRule: SVGPath.FillRule? = if let rule = attributes["fill-rule"] {
            rule == "evenodd" ? .evenOdd : .nonZero
        } else {
            nil
        }

        let opacity = attributes["opacity"].flatMap { Double($0) }

        return SVGPath(
            pathData: pathData,
            commands: commands,
            fill: fill,
            fillType: fillType,
            stroke: stroke,
            strokeWidth: strokeWidth,
            strokeLineCap: strokeLineCap,
            strokeLineJoin: strokeLineJoin,
            strokeDashArray: strokeDashArray,
            strokeDashOffset: strokeDashOffset,
            fillRule: fillRule,
            opacity: opacity
        )
    }

    /// Parses stroke-dasharray attribute value
    private func parseStrokeDashArray(_ value: String?) -> [Double]? {
        guard let value, !value.isEmpty, value.lowercased() != "none" else {
            return nil
        }

        let parts = value.split { $0 == "," || $0.isWhitespace }
        let values = parts.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

        return values.isEmpty ? nil : values
    }

    private func convertShapeToPath(_ element: XMLElement, attributes: [String: String]) throws -> SVGPath? {
        var pathData: String?

        switch elementName(element) {
        case "rect":
            pathData = convertRectToPath(element)
        case "circle":
            pathData = convertCircleToPath(element)
        case "ellipse":
            pathData = convertEllipseToPath(element)
        case "line":
            pathData = convertLineToPath(element)
        case "polygon":
            pathData = convertPolygonToPath(element, closed: true)
        case "polyline":
            pathData = convertPolygonToPath(element, closed: false)
        default:
            return nil
        }

        guard let path = pathData else { return nil }
        return try createSVGPath(pathData: path, attributes: attributes)
    }

    private func convertRectToPath(_ element: XMLElement) -> String? {
        let xStr = attributeValue(element, forName: "x") ?? "0"
        let yStr = attributeValue(element, forName: "y") ?? "0"
        guard let wStr = attributeValue(element, forName: "width"),
              let hStr = attributeValue(element, forName: "height"),
              let x = Double(xStr),
              let y = Double(yStr),
              let w = Double(wStr),
              let h = Double(hStr)
        else {
            return nil
        }

        let rx = attributeValue(element, forName: "rx").flatMap { Double($0) } ?? 0
        let ry = attributeValue(element, forName: "ry").flatMap { Double($0) } ?? rx

        if rx == 0, ry == 0 {
            return "M\(x),\(y)h\(w)v\(h)h\(-w)Z"
        } else {
            let clampedRx = min(rx, w / 2)
            let clampedRy = min(ry, h / 2)
            return """
            M\(x + clampedRx),\(y)\
            h\(w - 2 * clampedRx)\
            a\(clampedRx),\(clampedRy) 0 0 1 \(clampedRx),\(clampedRy)\
            v\(h - 2 * clampedRy)\
            a\(clampedRx),\(clampedRy) 0 0 1 \(-clampedRx),\(clampedRy)\
            h\(-w + 2 * clampedRx)\
            a\(clampedRx),\(clampedRy) 0 0 1 \(-clampedRx),\(-clampedRy)\
            v\(-h + 2 * clampedRy)\
            a\(clampedRx),\(clampedRy) 0 0 1 \(clampedRx),\(-clampedRy)\
            Z
            """
        }
    }

    private func convertCircleToPath(_ element: XMLElement) -> String? {
        let cxStr = attributeValue(element, forName: "cx") ?? "0"
        let cyStr = attributeValue(element, forName: "cy") ?? "0"
        guard let rStr = attributeValue(element, forName: "r"),
              let cx = Double(cxStr),
              let cy = Double(cyStr),
              let r = Double(rStr)
        else {
            return nil
        }

        return """
        M\(cx - r),\(cy)\
        a\(r),\(r) 0 1 0 \(2 * r),0\
        a\(r),\(r) 0 1 0 \(-2 * r),0\
        Z
        """
    }

    private func convertEllipseToPath(_ element: XMLElement) -> String? {
        let cxStr = attributeValue(element, forName: "cx") ?? "0"
        let cyStr = attributeValue(element, forName: "cy") ?? "0"
        guard let rxStr = attributeValue(element, forName: "rx"),
              let ryStr = attributeValue(element, forName: "ry"),
              let cx = Double(cxStr),
              let cy = Double(cyStr),
              let rx = Double(rxStr),
              let ry = Double(ryStr)
        else {
            return nil
        }

        return """
        M\(cx - rx),\(cy)\
        a\(rx),\(ry) 0 1 0 \(2 * rx),0\
        a\(rx),\(ry) 0 1 0 \(-2 * rx),0\
        Z
        """
    }

    private func convertLineToPath(_ element: XMLElement) -> String? {
        let x1Str = attributeValue(element, forName: "x1") ?? "0"
        let y1Str = attributeValue(element, forName: "y1") ?? "0"
        let x2Str = attributeValue(element, forName: "x2") ?? "0"
        let y2Str = attributeValue(element, forName: "y2") ?? "0"
        guard let x1 = Double(x1Str),
              let y1 = Double(y1Str),
              let x2 = Double(x2Str),
              let y2 = Double(y2Str)
        else {
            return nil
        }

        return "M\(x1),\(y1)L\(x2),\(y2)"
    }

    private func convertPolygonToPath(_ element: XMLElement, closed: Bool) -> String? {
        guard let pointsStr = attributeValue(element, forName: "points") else {
            return nil
        }

        let numbers = pointsStr
            .split { $0.isWhitespace || $0 == "," }
            .compactMap { Double($0) }

        guard numbers.count >= 4, numbers.count.isMultiple(of: 2) else {
            return nil
        }

        var path = "M\(numbers[0]),\(numbers[1])"
        for i in stride(from: 2, to: numbers.count, by: 2) {
            path += "L\(numbers[i]),\(numbers[i + 1])"
        }
        if closed {
            path += "Z"
        }

        return path
    }

    // MARK: - Group Parsing

    private func parseDefsForClipPaths(from root: XMLElement) throws {
        // Find defs element
        guard let defs = childElements(of: root, named: "defs").first else {
            return
        }

        // Look for clipPath elements
        for clipPathElement in childElements(of: defs, named: "clipPath") {
            guard let id = attributeValue(clipPathElement, forName: "id") else {
                continue
            }

            // Get the path data from the first path child
            if let pathElement = childElements(of: clipPathElement, named: "path").first,
               let pathData = attributeValue(pathElement, forName: "d")
            {
                clipPathDefs[id] = pathData
            }
        }
    }

    // MARK: - <use> and <symbol> Support

    /// Recursively indexes all elements with id attribute for <use> resolution
    private func indexElementsWithId(from element: XMLElement) {
        // Index this element if it has an id
        if let id = attributeValue(element, forName: "id") {
            elementDefs[id] = element

            // Also track <symbol> elements separately
            if elementName(element) == "symbol" {
                symbolDefs[id] = element
            }
        }

        // Recurse into children
        for child in element.children ?? [] {
            if let childElement = child as? XMLElement {
                indexElementsWithId(from: childElement)
            }
        }
    }

    // MARK: - CSS Style Parsing

    /// Recursively finds and parses all <style> elements
    private func parseStyleElements(from element: XMLElement) {
        let name = elementName(element)

        if name == "style" {
            // Extract CSS text content (handles CDATA and regular text)
            if let cssText = element.stringValue {
                parseCSSRules(cssText)
            }
        }

        // Recurse into children (including defs)
        for child in element.children ?? [] {
            if let childElement = child as? XMLElement {
                parseStyleElements(from: childElement)
            }
        }
    }

    /// Parses CSS rules from a style block text
    private func parseCSSRules(_ css: String) {
        // Simple CSS parser: matches selectors { properties }
        // Pattern: ([^{]+)\{([^}]+)\}
        let pattern = #"([^{]+)\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }

        let matches = regex.matches(in: css, options: [], range: NSRange(css.startIndex..., in: css))
        for match in matches {
            guard let selectorRange = Range(match.range(at: 1), in: css),
                  let propertiesRange = Range(match.range(at: 2), in: css)
            else {
                continue
            }

            let selectorsString = String(css[selectorRange])
            let propertiesString = String(css[propertiesRange])

            let properties = parseCSSProperties(propertiesString)
            guard !properties.isEmpty else { continue }

            // Handle multiple selectors separated by comma
            let selectors = selectorsString.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            for selector in selectors {
                cssStyles[selector, default: [:]].merge(properties) { _, new in new }
            }
        }
    }

    /// Parses CSS property declarations (key: value; pairs)
    private func parseCSSProperties(_ properties: String) -> [String: String] {
        var result: [String: String] = [:]
        let declarations = properties.split(separator: ";")
        for declaration in declarations {
            let parts = declaration.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let property = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    result[property] = value
                }
            }
        }
        return result
    }

    /// Gets CSS styles for an element based on its class and id
    private func getCSSStyles(for element: XMLElement) -> [String: String] {
        var styles: [String: String] = [:]

        // Apply ID selector styles (#id)
        if let id = attributeValue(element, forName: "id") {
            if let idStyles = cssStyles["#\(id)"] {
                styles.merge(idStyles) { _, new in new }
            }
        }

        // Apply class selector styles (.class)
        if let classAttr = attributeValue(element, forName: "class") {
            let classes = classAttr.split { $0.isWhitespace }
            for cls in classes {
                if let classStyles = cssStyles[".\(cls)"] {
                    styles.merge(classStyles) { _, new in new }
                }
            }
        }

        return styles
    }

    /// Resolves a <use> element by finding and processing its referenced content
    /// - Parameters:
    ///   - useElement: The <use> element to resolve
    ///   - inheritedAttributes: Attributes inherited from parent elements
    ///   - depth: Current recursion depth (to prevent infinite loops)
    /// - Returns: Tuple of (paths, groups) resolved from the referenced element
    private func resolveUseElement(
        _ useElement: XMLElement,
        inheritedAttributes: [String: String],
        depth: Int = 0
    ) throws -> (paths: [SVGPath], groups: [SVGGroup]) {
        // Check depth limit to prevent infinite recursion
        guard depth < maxUseDepth else {
            return ([], [])
        }

        // Get href or xlink:href attribute
        let href = attributeValue(useElement, forName: "href")
            ?? attributeValue(useElement, forName: "xlink:href")

        // Validate href format (should be #id)
        guard let href, href.hasPrefix("#"), href.count > 1 else {
            return ([], [])
        }

        let refId = String(href.dropFirst())

        // Find referenced element
        guard let referencedElement = symbolDefs[refId] ?? elementDefs[refId] else {
            return ([], [])
        }

        // Merge attributes from <use> element
        let attrs = mergeAttributes(from: useElement, with: inheritedAttributes)

        // Check if <use> has x, y, or transform attributes
        let useX = attributeValue(useElement, forName: "x").flatMap { Double($0) }
        let useY = attributeValue(useElement, forName: "y").flatMap { Double($0) }
        let useTransform = parseTransform(from: useElement)

        // Determine if we need to wrap in a group (for position offset or transform)
        let needsGroup = useX != nil || useY != nil || useTransform != nil

        // Parse the referenced element's content
        var resolvedPaths: [SVGPath] = []
        var resolvedGroups: [SVGGroup] = []

        try resolveReferencedContent(
            referencedElement,
            into: &resolvedPaths,
            groups: &resolvedGroups,
            inheritedAttributes: attrs,
            depth: depth
        )

        // If we need to wrap in a group, create one
        if needsGroup {
            // Combine x/y offset with any existing transform
            let transform: SVGTransform? = if let useX, let useY {
                if let existingTransform = useTransform {
                    // Combine translate with existing transform
                    SVGTransform(
                        translateX: (existingTransform.translateX ?? 0) + useX,
                        translateY: (existingTransform.translateY ?? 0) + useY,
                        scaleX: existingTransform.scaleX,
                        scaleY: existingTransform.scaleY,
                        rotation: existingTransform.rotation,
                        pivotX: existingTransform.pivotX,
                        pivotY: existingTransform.pivotY
                    )
                } else {
                    SVGTransform(translateX: useX, translateY: useY)
                }
            } else if let useX {
                SVGTransform(translateX: useX, translateY: 0)
            } else if let useY {
                SVGTransform(translateX: 0, translateY: useY)
            } else {
                useTransform
            }

            let group = SVGGroup(
                transform: transform,
                clipPath: nil,
                paths: resolvedPaths,
                children: resolvedGroups,
                opacity: attrs["opacity"].flatMap { Double($0) }
            )
            return ([], [group])
        }

        return (resolvedPaths, resolvedGroups)
    }

    /// Resolves content from a referenced element (symbol, g, path, etc.)
    private func resolveReferencedContent(
        _ element: XMLElement,
        into paths: inout [SVGPath],
        groups: inout [SVGGroup],
        inheritedAttributes: [String: String],
        depth: Int
    ) throws {
        let name = elementName(element)

        // For <symbol>, process its children
        if name == "symbol" || name == "g" {
            for child in element.children ?? [] {
                if let childElement = child as? XMLElement {
                    try resolveReferencedContent(
                        childElement,
                        into: &paths,
                        groups: &groups,
                        inheritedAttributes: inheritedAttributes,
                        depth: depth
                    )
                }
            }
            return
        }

        // For <use>, recursively resolve
        if name == "use" {
            let (usePaths, useGroups) = try resolveUseElement(
                element,
                inheritedAttributes: inheritedAttributes,
                depth: depth + 1
            )
            paths.append(contentsOf: usePaths)
            groups.append(contentsOf: useGroups)
            return
        }

        // For <path>, create path
        if name == "path", let pathData = attributeValue(element, forName: "d") {
            let pathAttrs = mergeAttributes(from: element, with: inheritedAttributes)
            let path = try createSVGPath(pathData: pathData, attributes: pathAttrs)
            paths.append(path)
            return
        }

        // For other shapes, convert to path
        let attrs = mergeAttributes(from: element, with: inheritedAttributes)
        if let path = try convertShapeToPath(element, attributes: attrs) {
            paths.append(path)
        }
    }

    private func collectGroups(
        from element: XMLElement,
        into groups: inout [SVGGroup],
        inheritedAttributes: [String: String]
    ) throws {
        for child in element.children ?? [] {
            guard let childElement = child as? XMLElement else {
                continue
            }

            let name = elementName(childElement)
            if name == "g" {
                let group = try parseGroup(childElement, inheritedAttributes: inheritedAttributes)
                groups.append(group)
            } else if name == "use" {
                // Process <use> elements that may create groups
                let attrs = mergeAttributes(from: childElement, with: inheritedAttributes)
                let (_, useGroups) = try resolveUseElement(childElement, inheritedAttributes: attrs)
                groups.append(contentsOf: useGroups)
            } else if name != "defs" {
                // Skip defs but recurse into other non-group elements
                try collectGroups(from: childElement, into: &groups, inheritedAttributes: inheritedAttributes)
            }
        }
    }

    private func parseGroup(
        _ element: XMLElement,
        inheritedAttributes: [String: String]
    ) throws -> SVGGroup {
        let attrs = mergeAttributes(from: element, with: inheritedAttributes)
        let transform = parseTransform(from: element)
        let clipPath = resolveClipPath(from: element)
        let opacity = attrs["opacity"].flatMap { Double($0) }
        let paths = try collectGroupPaths(from: element, attributes: attrs)
        let children = try collectChildGroups(from: element, inheritedAttributes: attrs)

        return SVGGroup(
            transform: transform,
            clipPath: clipPath,
            paths: paths,
            children: children,
            opacity: opacity
        )
    }

    private func mergeAttributes(from element: XMLElement, with inherited: [String: String]) -> [String: String] {
        var attrs = inherited

        // Apply CSS styles (lower priority than element attributes)
        let cssAttrs = getCSSStyles(for: element)
        attrs.merge(cssAttrs) { _, new in new }

        // Apply element attributes (override CSS)
        for attr in Self.inheritableAttributes {
            if let value = attributeValue(element, forName: attr) {
                attrs[attr] = value
            }
        }

        // Apply inline style attribute (highest priority)
        if let style = attributeValue(element, forName: "style") {
            attrs.merge(parseStyleAttribute(style)) { _, new in new }
        }
        return attrs
    }

    private func parseTransform(from element: XMLElement) -> SVGTransform? {
        attributeValue(element, forName: "transform").flatMap { SVGTransform.parse($0) }
    }

    private func resolveClipPath(from element: XMLElement) -> String? {
        guard let clipPathRef = attributeValue(element, forName: "clip-path"),
              let id = parseClipPathReference(clipPathRef)
        else {
            return nil
        }
        return clipPathDefs[id]
    }

    private func collectGroupPaths(from element: XMLElement, attributes: [String: String]) throws -> [SVGPath] {
        var paths: [SVGPath] = []
        for child in element.children ?? [] {
            guard let childElement = child as? XMLElement else { continue }

            if elementName(childElement) == "path",
               let pathData = attributeValue(childElement, forName: "d")
            {
                let pathAttrs = overrideAttributes(from: childElement, with: attributes)
                try paths.append(createSVGPath(pathData: pathData, attributes: pathAttrs))
            } else if let path = try convertShapeToPath(childElement, attributes: attributes) {
                paths.append(path)
            }
        }
        return paths
    }

    private func overrideAttributes(from element: XMLElement, with base: [String: String]) -> [String: String] {
        var attrs = base
        for attr in Self.inheritableAttributes {
            if let value = attributeValue(element, forName: attr) {
                attrs[attr] = value
            }
        }
        return attrs
    }

    private func collectChildGroups(
        from element: XMLElement,
        inheritedAttributes: [String: String]
    ) throws -> [SVGGroup] {
        var children: [SVGGroup] = []
        for child in element.children ?? [] {
            guard let childElement = child as? XMLElement, elementName(childElement) == "g" else { continue }
            try children.append(parseGroup(childElement, inheritedAttributes: inheritedAttributes))
        }
        return children
    }

    private func parseClipPathReference(_ reference: String) -> String? {
        // Parse url(#id) format
        let pattern = #"url\(#([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                  in: reference,
                  options: [],
                  range: NSRange(reference.startIndex..., in: reference)
              ),
              let idRange = Range(match.range(at: 1), in: reference)
        else {
            return nil
        }
        return String(reference[idRange])
    }

    // MARK: - Gradient Parsing

    private func parseDefsForGradients(from root: XMLElement) {
        // Find defs element
        guard let defs = childElements(of: root, named: "defs").first else {
            return
        }

        // Parse linear gradients
        for gradientElement in childElements(of: defs, named: "linearGradient") {
            if let gradient = parseLinearGradient(gradientElement) {
                linearGradientDefs[gradient.id] = gradient
            }
        }

        // Parse radial gradients
        for gradientElement in childElements(of: defs, named: "radialGradient") {
            if let gradient = parseRadialGradient(gradientElement) {
                radialGradientDefs[gradient.id] = gradient
            }
        }
    }

    private func parseLinearGradient(_ element: XMLElement) -> SVGLinearGradient? {
        guard let id = attributeValue(element, forName: "id") else {
            return nil
        }

        let x1 = parseGradientCoordinate(attributeValue(element, forName: "x1"), defaultValue: 0)
        let y1 = parseGradientCoordinate(attributeValue(element, forName: "y1"), defaultValue: 0)
        let x2 = parseGradientCoordinate(attributeValue(element, forName: "x2"), defaultValue: 1)
        let y2 = parseGradientCoordinate(attributeValue(element, forName: "y2"), defaultValue: 0)
        let spreadMethod = parseSpreadMethod(attributeValue(element, forName: "spreadMethod"))
        let stops = parseGradientStops(element)

        return SVGLinearGradient(
            id: id,
            x1: x1, y1: y1,
            x2: x2, y2: y2,
            stops: stops,
            spreadMethod: spreadMethod
        )
    }

    private func parseRadialGradient(_ element: XMLElement) -> SVGRadialGradient? {
        guard let id = attributeValue(element, forName: "id") else {
            return nil
        }

        let cx = parseGradientCoordinate(attributeValue(element, forName: "cx"), defaultValue: 0.5)
        let cy = parseGradientCoordinate(attributeValue(element, forName: "cy"), defaultValue: 0.5)
        let r = parseGradientCoordinate(attributeValue(element, forName: "r"), defaultValue: 0.5)
        let fx = attributeValue(element, forName: "fx").flatMap { parseGradientCoordinate($0, defaultValue: cx) }
        let fy = attributeValue(element, forName: "fy").flatMap { parseGradientCoordinate($0, defaultValue: cy) }
        let spreadMethod = parseSpreadMethod(attributeValue(element, forName: "spreadMethod"))
        let stops = parseGradientStops(element)

        return SVGRadialGradient(
            id: id,
            cx: cx, cy: cy, r: r,
            fx: fx, fy: fy,
            stops: stops,
            spreadMethod: spreadMethod
        )
    }

    private func parseGradientStops(_ element: XMLElement) -> [SVGGradientStop] {
        var stops: [SVGGradientStop] = []

        for stopElement in childElements(of: element, named: "stop") {
            let offset = parseGradientOffset(attributeValue(stopElement, forName: "offset"))

            // Parse color from stop-color attribute or style
            var colorStr: String?
            var opacityStr: String?

            if let style = attributeValue(stopElement, forName: "style") {
                let styleAttrs = parseStyleAttribute(style)
                colorStr = styleAttrs["stop-color"]
                opacityStr = styleAttrs["stop-opacity"]
            }

            if colorStr == nil {
                colorStr = attributeValue(stopElement, forName: "stop-color")
            }
            if opacityStr == nil {
                opacityStr = attributeValue(stopElement, forName: "stop-opacity")
            }

            let color = colorStr.flatMap { SVGColor.parse($0) } ?? SVGColor(red: 0, green: 0, blue: 0)
            let opacity = opacityStr.flatMap { Double($0) } ?? 1.0

            stops.append(SVGGradientStop(offset: offset, color: color, opacity: opacity))
        }

        // Sort stops by offset for consistent rendering
        return stops.sorted { $0.offset < $1.offset }
    }

    private func parseGradientOffset(_ string: String?) -> Double {
        guard let str = string else { return 0 }

        if str.hasSuffix("%") {
            let numStr = String(str.dropLast())
            return (Double(numStr) ?? 0) / 100.0
        }

        return Double(str) ?? 0
    }

    private func parseGradientCoordinate(_ string: String?, defaultValue: Double) -> Double {
        guard let str = string else { return defaultValue }

        // Handle percentage values
        if str.hasSuffix("%") {
            let numStr = String(str.dropLast())
            let percentage = Double(numStr) ?? (defaultValue * 100)
            // Convert percentage to viewport coordinates
            if let viewBox = currentViewBox {
                return (percentage / 100.0) * viewBox.width
            }
            return percentage / 100.0
        }

        return Double(str) ?? defaultValue
    }

    private func parseSpreadMethod(_ string: String?) -> SVGLinearGradient.SpreadMethod {
        guard let str = string else { return .pad }
        return SVGLinearGradient.SpreadMethod(rawValue: str) ?? .pad
    }

    /// Resolves fill value to SVGFill type
    /// Handles url(#id) references to gradients and solid colors
    private func resolveFill(_ fillValue: String?) -> SVGFill {
        guard let fill = fillValue else { return .none }

        // Check for gradient reference
        if fill.hasPrefix("url(#") {
            let pattern = #"url\(#([^)]+)\)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: fill, options: [], range: NSRange(fill.startIndex..., in: fill)),
               let idRange = Range(match.range(at: 1), in: fill)
            {
                let id = String(fill[idRange])

                if let linearGradient = linearGradientDefs[id] {
                    return .linearGradient(linearGradient)
                }
                if let radialGradient = radialGradientDefs[id] {
                    return .radialGradient(radialGradient)
                }
            }
            return .none
        }

        // Check for "none"
        if fill == "none" {
            return .none
        }

        // Try to parse as solid color
        if let color = SVGColor.parse(fill) {
            return .solid(color)
        }

        return .none
    }
}

// MARK: - Errors

public enum SVGParserError: Error, LocalizedError, Equatable {
    case invalidSVGRoot
    case missingDimensions
    case invalidPathData(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSVGRoot:
            "Invalid SVG: root element must be <svg>"
        case .missingDimensions:
            "Invalid SVG: missing dimensions"
        case let .invalidPathData(path):
            "Invalid path data: \(path)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidSVGRoot:
            "Ensure SVG file starts with <svg> element"
        case .missingDimensions:
            "Add width/height or viewBox attribute to SVG"
        case .invalidPathData:
            "Check SVG path syntax"
        }
    }
}
