# Proposal: SVG Gradient Support (TDD Approach)

## Summary

Add linear and radial gradient support to SVGKit for Android Vector Drawable XML and Compose ImageVector generation,
following Test-Driven Development methodology.

## Research Sources

- [usvg spec](https://github.com/linebender/resvg/blob/main/crates/usvg/docs/spec.adoc) - gradient element
  specifications
- [FigX image_vector](https://github.com/tonykolomeytsev/figx/tree/master/crates/lib/image_vector) - usvg to model
  conversion
- [FigX svg2drawable](https://github.com/tonykolomeytsev/figx/tree/master/crates/lib/svg2drawable) - VD XML generation

## SVG Gradient Specification (from usvg)

### linearGradient

```xml
<linearGradient id="grad1" x1="0" y1="0" x2="24" y2="24"
                gradientUnits="userSpaceOnUse"
                spreadMethod="pad">
  <stop offset="0" stop-color="#FF0000" stop-opacity="1"/>
  <stop offset="1" stop-color="#0000FF" stop-opacity="1"/>
</linearGradient>
```

Attributes:

- `id` - unique identifier (required)
- `x1, y1, x2, y2` - gradient line coordinates
- `gradientUnits` - `userSpaceOnUse` (after usvg simplification)
- `spreadMethod` - `pad` | `reflect` | `repeat` (optional)
- `gradientTransform` - transform matrix (optional)

### radialGradient

```xml
<radialGradient id="grad2" cx="12" cy="12" r="12" fx="12" fy="12"
                gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#FFFFFF"/>
  <stop offset="1" stop-color="#000000"/>
</radialGradient>
```

Attributes:

- `id` - unique identifier (required)
- `cx, cy` - center coordinates
- `r` - radius (positive number)
- `fx, fy` - focal point (optional, defaults to cx, cy)
- `gradientUnits` - `userSpaceOnUse`
- `spreadMethod` - `pad` | `reflect` | `repeat` (optional)

### stop

```xml
<stop offset="0.5" stop-color="#FF0000" stop-opacity="0.8"/>
```

Attributes:

- `offset` - position 0.0 to 1.0 (unique, ordered)
- `stop-color` - color value
- `stop-opacity` - opacity 0.0 to 1.0 (default: 1)

### defs

Always first child of `<svg>`, contains gradient definitions.

______________________________________________________________________

## TDD Implementation Plan

### Phase 1: Gradient Types (SVGTypes.swift)

#### Test 1.1: SVGGradientStop parsing

```swift
// Tests/SVGKitTests/SVGGradientTests.swift

func testGradientStopParsing() {
    let stop = SVGGradientStop(offset: 0.5, color: SVGColor("#FF0000")!, opacity: 0.8)

    XCTAssertEqual(stop.offset, 0.5)
    XCTAssertEqual(stop.color.red, 255)
    XCTAssertEqual(stop.opacity, 0.8)
}

func testGradientStopDefaultOpacity() {
    let stop = SVGGradientStop(offset: 0, color: SVGColor("#000000")!)

    XCTAssertEqual(stop.opacity, 1.0)
}

func testGradientStopEquatable() {
    let stop1 = SVGGradientStop(offset: 0.5, color: SVGColor("#FF0000")!)
    let stop2 = SVGGradientStop(offset: 0.5, color: SVGColor("#FF0000")!)
    let stop3 = SVGGradientStop(offset: 0.7, color: SVGColor("#FF0000")!)

    XCTAssertEqual(stop1, stop2)
    XCTAssertNotEqual(stop1, stop3)
}
```

#### Test 1.2: SVGLinearGradient

```swift
func testLinearGradientCreation() {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FF0000")!),
        SVGGradientStop(offset: 1, color: SVGColor("#0000FF")!)
    ]
    let gradient = SVGLinearGradient(
        id: "grad1",
        x1: 0, y1: 0,
        x2: 24, y2: 24,
        stops: stops
    )

    XCTAssertEqual(gradient.id, "grad1")
    XCTAssertEqual(gradient.x1, 0)
    XCTAssertEqual(gradient.y2, 24)
    XCTAssertEqual(gradient.stops.count, 2)
}

func testLinearGradientSendable() {
    // Verify Sendable conformance compiles
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 1, y2: 1, stops: [])
    Task {
        _ = gradient // Should compile without warnings
    }
}
```

#### Test 1.3: SVGRadialGradient

```swift
func testRadialGradientCreation() {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FFFFFF")!),
        SVGGradientStop(offset: 1, color: SVGColor("#000000")!)
    ]
    let gradient = SVGRadialGradient(
        id: "grad2",
        cx: 12, cy: 12,
        r: 12,
        fx: nil, fy: nil,
        stops: stops
    )

    XCTAssertEqual(gradient.cx, 12)
    XCTAssertEqual(gradient.r, 12)
    XCTAssertNil(gradient.fx)
}

func testRadialGradientWithFocalPoint() {
    let gradient = SVGRadialGradient(
        id: "grad3",
        cx: 12, cy: 12,
        r: 12,
        fx: 8, fy: 8,
        stops: []
    )

    XCTAssertEqual(gradient.fx, 8)
    XCTAssertEqual(gradient.fy, 8)
}
```

#### Test 1.4: SVGFill enum

```swift
func testSVGFillNone() {
    let fill = SVGFill.none
    if case .none = fill {
        // Success
    } else {
        XCTFail("Expected .none")
    }
}

func testSVGFillSolid() {
    let fill = SVGFill.solid(SVGColor("#FF0000")!)
    if case .solid(let color) = fill {
        XCTAssertEqual(color.red, 255)
    } else {
        XCTFail("Expected .solid")
    }
}

func testSVGFillLinearGradient() {
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 1, y2: 1, stops: [])
    let fill = SVGFill.linearGradient(gradient)

    if case .linearGradient(let g) = fill {
        XCTAssertEqual(g.id, "g")
    } else {
        XCTFail("Expected .linearGradient")
    }
}
```

#### Implementation 1: SVGTypes.swift additions

```swift
// Sources/SVGKit/SVGTypes.swift

/// Gradient color stop
public struct SVGGradientStop: Sendable, Equatable {
    public let offset: Double
    public let color: SVGColor
    public let opacity: Double

    public init(offset: Double, color: SVGColor, opacity: Double = 1.0) {
        self.offset = offset
        self.color = color
        self.opacity = opacity
    }
}

/// Linear gradient definition
public struct SVGLinearGradient: Sendable, Equatable {
    public let id: String
    public let x1, y1, x2, y2: Double
    public let stops: [SVGGradientStop]
    public let spreadMethod: SpreadMethod

    public enum SpreadMethod: String, Sendable {
        case pad, reflect, repeating = "repeat"
    }

    public init(
        id: String,
        x1: Double, y1: Double,
        x2: Double, y2: Double,
        stops: [SVGGradientStop],
        spreadMethod: SpreadMethod = .pad
    ) {
        self.id = id
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.stops = stops
        self.spreadMethod = spreadMethod
    }
}

/// Radial gradient definition
public struct SVGRadialGradient: Sendable, Equatable {
    public let id: String
    public let cx, cy, r: Double
    public let fx, fy: Double?
    public let stops: [SVGGradientStop]
    public let spreadMethod: SVGLinearGradient.SpreadMethod

    public init(
        id: String,
        cx: Double, cy: Double,
        r: Double,
        fx: Double? = nil, fy: Double? = nil,
        stops: [SVGGradientStop],
        spreadMethod: SVGLinearGradient.SpreadMethod = .pad
    ) {
        self.id = id
        self.cx = cx
        self.cy = cy
        self.r = r
        self.fx = fx
        self.fy = fy
        self.stops = stops
        self.spreadMethod = spreadMethod
    }
}

/// Fill type - solid color or gradient
public enum SVGFill: Sendable, Equatable {
    case none
    case solid(SVGColor)
    case linearGradient(SVGLinearGradient)
    case radialGradient(SVGRadialGradient)
}
```

______________________________________________________________________

### Phase 2: Gradient Parsing (SVGParser.swift)

#### Test 2.1: Parse linearGradient element

```swift
// Tests/SVGKitTests/SVGGradientParsingTests.swift

func testParseLinearGradientBasic() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1" x1="0" y1="0" x2="24" y2="24">
          <stop offset="0" stop-color="#FF0000"/>
          <stop offset="1" stop-color="#0000FF"/>
        </linearGradient>
      </defs>
      <rect fill="url(#grad1)" width="24" height="24"/>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))

    XCTAssertEqual(parsed.linearGradients.count, 1)

    let gradient = parsed.linearGradients["grad1"]
    XCTAssertNotNil(gradient)
    XCTAssertEqual(gradient?.x1, 0)
    XCTAssertEqual(gradient?.x2, 24)
    XCTAssertEqual(gradient?.stops.count, 2)
    XCTAssertEqual(gradient?.stops[0].color.red, 255)
    XCTAssertEqual(gradient?.stops[1].color.blue, 255)
}

func testParseLinearGradientPercentageCoords() throws {
    let svg = """
    <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#000"/>
          <stop offset="100%" stop-color="#FFF"/>
        </linearGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))
    let gradient = parsed.linearGradients["grad1"]

    // Percentages should be converted to viewport coordinates
    XCTAssertEqual(gradient?.x1, 0)
    XCTAssertEqual(gradient?.x2, 100)
}

func testParseLinearGradientWithSpreadMethod() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1" spreadMethod="reflect">
          <stop offset="0" stop-color="#000"/>
          <stop offset="1" stop-color="#FFF"/>
        </linearGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))
    let gradient = parsed.linearGradients["grad1"]

    XCTAssertEqual(gradient?.spreadMethod, .reflect)
}
```

#### Test 2.2: Parse radialGradient element

```swift
func testParseRadialGradientBasic() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="grad2" cx="12" cy="12" r="12">
          <stop offset="0" stop-color="#FFFFFF"/>
          <stop offset="1" stop-color="#000000"/>
        </radialGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))

    XCTAssertEqual(parsed.radialGradients.count, 1)

    let gradient = parsed.radialGradients["grad2"]
    XCTAssertNotNil(gradient)
    XCTAssertEqual(gradient?.cx, 12)
    XCTAssertEqual(gradient?.cy, 12)
    XCTAssertEqual(gradient?.r, 12)
    XCTAssertNil(gradient?.fx)
}

func testParseRadialGradientWithFocalPoint() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="grad2" cx="12" cy="12" r="12" fx="8" fy="8">
          <stop offset="0" stop-color="#FFF"/>
          <stop offset="1" stop-color="#000"/>
        </radialGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))
    let gradient = parsed.radialGradients["grad2"]

    XCTAssertEqual(gradient?.fx, 8)
    XCTAssertEqual(gradient?.fy, 8)
}
```

#### Test 2.3: Parse stop elements

```swift
func testParseStopWithOpacity() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1">
          <stop offset="0" stop-color="#FF0000" stop-opacity="0.5"/>
          <stop offset="1" stop-color="#0000FF" stop-opacity="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))
    let gradient = parsed.linearGradients["grad1"]

    XCTAssertEqual(gradient?.stops[0].opacity, 0.5)
    XCTAssertEqual(gradient?.stops[1].opacity, 1.0)
}

func testParseStopPercentageOffset() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1">
          <stop offset="0%" stop-color="#000"/>
          <stop offset="50%" stop-color="#888"/>
          <stop offset="100%" stop-color="#FFF"/>
        </linearGradient>
      </defs>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))
    let gradient = parsed.linearGradients["grad1"]

    XCTAssertEqual(gradient?.stops[0].offset, 0.0)
    XCTAssertEqual(gradient?.stops[1].offset, 0.5)
    XCTAssertEqual(gradient?.stops[2].offset, 1.0)
}
```

#### Test 2.4: Resolve url() references

```swift
func testResolveFillUrlReference() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="myGrad">
          <stop offset="0" stop-color="#F00"/>
          <stop offset="1" stop-color="#00F"/>
        </linearGradient>
      </defs>
      <rect fill="url(#myGrad)" width="24" height="24"/>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))

    XCTAssertEqual(parsed.paths.count, 1)

    if case .linearGradient(let gradient) = parsed.paths[0].fill {
        XCTAssertEqual(gradient.id, "myGrad")
    } else {
        XCTFail("Expected linearGradient fill")
    }
}

func testResolveFillUrlNotFound() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <rect fill="url(#nonexistent)" width="24" height="24"/>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))

    // Should fall back to none when gradient not found
    if case .none = parsed.paths[0].fill {
        // Success
    } else {
        XCTFail("Expected .none fill for missing gradient")
    }
}
```

#### Test 2.5: SVG without gradients (backward compatibility)

```swift
func testParseSVGWithoutGradients() throws {
    let svg = """
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <rect fill="#FF0000" width="24" height="24"/>
    </svg>
    """

    let parsed = try SVGParser.parse(Data(svg.utf8))

    XCTAssertTrue(parsed.linearGradients.isEmpty)
    XCTAssertTrue(parsed.radialGradients.isEmpty)

    if case .solid(let color) = parsed.paths[0].fill {
        XCTAssertEqual(color.red, 255)
    } else {
        XCTFail("Expected solid fill")
    }
}
```

#### Implementation 2: SVGParser.swift additions

```swift
// Sources/SVGKit/SVGParser.swift

// Add to ParsedSVG struct
public struct ParsedSVG: Sendable {
    // ... existing fields ...
    public let linearGradients: [String: SVGLinearGradient]
    public let radialGradients: [String: SVGRadialGradient]
}

// Add parsing methods
extension SVGParser {

    private static func parseDefs(
        _ element: XMLElement,
        viewBox: CGRect
    ) -> (linear: [String: SVGLinearGradient], radial: [String: SVGRadialGradient]) {
        var linearGradients: [String: SVGLinearGradient] = [:]
        var radialGradients: [String: SVGRadialGradient] = [:]

        for child in element.children ?? [] {
            guard let childElement = child as? XMLElement else { continue }
            let name = elementName(childElement)

            if name == "linearGradient" {
                if let gradient = parseLinearGradient(childElement, viewBox: viewBox) {
                    linearGradients[gradient.id] = gradient
                }
            } else if name == "radialGradient" {
                if let gradient = parseRadialGradient(childElement, viewBox: viewBox) {
                    radialGradients[gradient.id] = gradient
                }
            }
        }

        return (linearGradients, radialGradients)
    }

    private static func parseLinearGradient(
        _ element: XMLElement,
        viewBox: CGRect
    ) -> SVGLinearGradient? {
        guard let id = attributeValue(element, forName: "id") else { return nil }

        let x1 = parseCoordinate(attributeValue(element, forName: "x1"), dimension: viewBox.width) ?? 0
        let y1 = parseCoordinate(attributeValue(element, forName: "y1"), dimension: viewBox.height) ?? 0
        let x2 = parseCoordinate(attributeValue(element, forName: "x2"), dimension: viewBox.width) ?? viewBox.width
        let y2 = parseCoordinate(attributeValue(element, forName: "y2"), dimension: viewBox.height) ?? 0

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

    private static func parseRadialGradient(
        _ element: XMLElement,
        viewBox: CGRect
    ) -> SVGRadialGradient? {
        guard let id = attributeValue(element, forName: "id") else { return nil }

        let cx = parseCoordinate(attributeValue(element, forName: "cx"), dimension: viewBox.width) ?? viewBox.width / 2
        let cy = parseCoordinate(attributeValue(element, forName: "cy"), dimension: viewBox.height) ?? viewBox.height / 2
        let r = parseCoordinate(attributeValue(element, forName: "r"), dimension: viewBox.width) ?? viewBox.width / 2

        let fx = parseCoordinate(attributeValue(element, forName: "fx"), dimension: viewBox.width)
        let fy = parseCoordinate(attributeValue(element, forName: "fy"), dimension: viewBox.height)

        let spreadMethod = parseSpreadMethod(attributeValue(element, forName: "spreadMethod"))
        let stops = parseGradientStops(element)

        return SVGRadialGradient(
            id: id,
            cx: cx, cy: cy,
            r: r,
            fx: fx, fy: fy,
            stops: stops,
            spreadMethod: spreadMethod
        )
    }

    private static func parseGradientStops(_ element: XMLElement) -> [SVGGradientStop] {
        var stops: [SVGGradientStop] = []

        for child in element.children ?? [] {
            guard let stopElement = child as? XMLElement,
                  elementName(stopElement) == "stop" else { continue }

            let offsetStr = attributeValue(stopElement, forName: "offset") ?? "0"
            let offset = parseOffset(offsetStr)

            let colorStr = attributeValue(stopElement, forName: "stop-color") ?? "#000000"
            guard let color = SVGColor(colorStr) else { continue }

            let opacityStr = attributeValue(stopElement, forName: "stop-opacity") ?? "1"
            let opacity = Double(opacityStr) ?? 1.0

            stops.append(SVGGradientStop(offset: offset, color: color, opacity: opacity))
        }

        return stops.sorted { $0.offset < $1.offset }
    }

    private static func parseOffset(_ value: String) -> Double {
        if value.hasSuffix("%") {
            let numStr = String(value.dropLast())
            return (Double(numStr) ?? 0) / 100.0
        }
        return Double(value) ?? 0
    }

    private static func parseCoordinate(_ value: String?, dimension: CGFloat) -> Double? {
        guard let value = value else { return nil }
        if value.hasSuffix("%") {
            let numStr = String(value.dropLast())
            return (Double(numStr) ?? 0) / 100.0 * Double(dimension)
        }
        return Double(value)
    }

    private static func parseSpreadMethod(_ value: String?) -> SVGLinearGradient.SpreadMethod {
        switch value {
        case "reflect": return .reflect
        case "repeat": return .repeating
        default: return .pad
        }
    }

    private static func resolveFill(
        _ value: String?,
        linearGradients: [String: SVGLinearGradient],
        radialGradients: [String: SVGRadialGradient]
    ) -> SVGFill {
        guard let value = value else { return .none }
        if value == "none" { return .none }

        // Check for url(#id) reference
        if value.hasPrefix("url(#") && value.hasSuffix(")") {
            let id = String(value.dropFirst(5).dropLast(1))
            if let gradient = linearGradients[id] {
                return .linearGradient(gradient)
            }
            if let gradient = radialGradients[id] {
                return .radialGradient(gradient)
            }
            return .none
        }

        // Solid color
        if let color = SVGColor(value) {
            return .solid(color)
        }

        return .none
    }
}
```

______________________________________________________________________

### Phase 3: VD XML Generation (VectorDrawableXMLGenerator.swift)

#### Test 3.1: Generate gradient namespace

```swift
// Tests/SVGKitTests/VectorDrawableGradientTests.swift

func testVectorDrawableWithGradientHasAaptNamespace() throws {
    let svg = createSVGWithLinearGradient()
    let xml = VectorDrawableXMLGenerator.generate(from: svg)

    XCTAssertTrue(xml.contains("xmlns:aapt=\"http://schemas.android.com/aapt\""))
}

func testVectorDrawableWithoutGradientNoAaptNamespace() throws {
    let svg = createSVGWithSolidFill()
    let xml = VectorDrawableXMLGenerator.generate(from: svg)

    XCTAssertFalse(xml.contains("xmlns:aapt"))
}
```

#### Test 3.2: Generate linear gradient XML

```swift
func testGenerateLinearGradientFill() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FF0000")!),
        SVGGradientStop(offset: 1, color: SVGColor("#0000FF")!)
    ]
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .linearGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], linearGradients: ["g": gradient])

    let xml = VectorDrawableXMLGenerator.generate(from: svg)

    XCTAssertTrue(xml.contains("<aapt:attr name=\"android:fillColor\">"))
    XCTAssertTrue(xml.contains("android:type=\"linear\""))
    XCTAssertTrue(xml.contains("android:startX=\"0\""))
    XCTAssertTrue(xml.contains("android:endX=\"24\""))
    XCTAssertTrue(xml.contains("<item android:offset=\"0\""))
    XCTAssertTrue(xml.contains("android:color=\"#FFFF0000\""))
}
```

#### Test 3.3: Generate radial gradient XML

```swift
func testGenerateRadialGradientFill() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FFFFFF")!),
        SVGGradientStop(offset: 1, color: SVGColor("#000000")!)
    ]
    let gradient = SVGRadialGradient(id: "g", cx: 12, cy: 12, r: 12, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .radialGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], radialGradients: ["g": gradient])

    let xml = VectorDrawableXMLGenerator.generate(from: svg)

    XCTAssertTrue(xml.contains("android:type=\"radial\""))
    XCTAssertTrue(xml.contains("android:centerX=\"12\""))
    XCTAssertTrue(xml.contains("android:centerY=\"12\""))
    XCTAssertTrue(xml.contains("android:gradientRadius=\"12\""))
}
```

#### Test 3.4: Gradient stop opacity in ARGB

```swift
func testGradientStopWithOpacity() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FF0000")!, opacity: 0.5),
        SVGGradientStop(offset: 1, color: SVGColor("#0000FF")!, opacity: 1.0)
    ]
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .linearGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], linearGradients: ["g": gradient])

    let xml = VectorDrawableXMLGenerator.generate(from: svg)

    // 0.5 opacity = 0x80 alpha
    XCTAssertTrue(xml.contains("android:color=\"#80FF0000\""))
    XCTAssertTrue(xml.contains("android:color=\"#FF0000FF\""))
}
```

#### Implementation 3: VectorDrawableXMLGenerator additions

```swift
// Sources/SVGKit/VectorDrawableXMLGenerator.swift

extension VectorDrawableXMLGenerator {

    private static func hasGradients(_ svg: ParsedSVG) -> Bool {
        for path in svg.paths {
            if case .linearGradient = path.fill { return true }
            if case .radialGradient = path.fill { return true }
            if case .linearGradient = path.stroke { return true }
            if case .radialGradient = path.stroke { return true }
        }
        return false
    }

    private static func generateFillElement(_ fill: SVGFill, indent: String) -> String {
        switch fill {
        case .none:
            return ""
        case .solid(let color):
            return "\(indent)android:fillColor=\"\(color.hexARGB)\""
        case .linearGradient(let gradient):
            return generateLinearGradientElement(gradient, attrName: "android:fillColor", indent: indent)
        case .radialGradient(let gradient):
            return generateRadialGradientElement(gradient, attrName: "android:fillColor", indent: indent)
        }
    }

    private static func generateLinearGradientElement(
        _ gradient: SVGLinearGradient,
        attrName: String,
        indent: String
    ) -> String {
        var xml = "\(indent)<aapt:attr name=\"\(attrName)\">\n"
        xml += "\(indent)    <gradient\n"
        xml += "\(indent)        android:type=\"linear\"\n"
        xml += "\(indent)        android:startX=\"\(fmt(gradient.x1))\"\n"
        xml += "\(indent)        android:startY=\"\(fmt(gradient.y1))\"\n"
        xml += "\(indent)        android:endX=\"\(fmt(gradient.x2))\"\n"
        xml += "\(indent)        android:endY=\"\(fmt(gradient.y2))\">\n"

        for stop in gradient.stops {
            let argb = colorToARGB(stop.color, opacity: stop.opacity)
            xml += "\(indent)        <item android:offset=\"\(fmt(stop.offset))\" android:color=\"\(argb)\"/>\n"
        }

        xml += "\(indent)    </gradient>\n"
        xml += "\(indent)</aapt:attr>"
        return xml
    }

    private static func generateRadialGradientElement(
        _ gradient: SVGRadialGradient,
        attrName: String,
        indent: String
    ) -> String {
        var xml = "\(indent)<aapt:attr name=\"\(attrName)\">\n"
        xml += "\(indent)    <gradient\n"
        xml += "\(indent)        android:type=\"radial\"\n"
        xml += "\(indent)        android:centerX=\"\(fmt(gradient.cx))\"\n"
        xml += "\(indent)        android:centerY=\"\(fmt(gradient.cy))\"\n"
        xml += "\(indent)        android:gradientRadius=\"\(fmt(gradient.r))\">\n"

        for stop in gradient.stops {
            let argb = colorToARGB(stop.color, opacity: stop.opacity)
            xml += "\(indent)        <item android:offset=\"\(fmt(stop.offset))\" android:color=\"\(argb)\"/>\n"
        }

        xml += "\(indent)    </gradient>\n"
        xml += "\(indent)</aapt:attr>"
        return xml
    }

    private static func colorToARGB(_ color: SVGColor, opacity: Double) -> String {
        let alpha = Int(opacity * 255)
        return String(format: "#%02X%02X%02X%02X", alpha, color.red, color.green, color.blue)
    }
}
```

______________________________________________________________________

### Phase 4: Compose ImageVector Generation (ImageVectorGenerator.swift)

#### Test 4.1: Generate Brush.linearGradient

```swift
// Tests/SVGKitTests/ImageVectorGradientTests.swift

func testGenerateLinearGradientBrush() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FF0000")!),
        SVGGradientStop(offset: 1, color: SVGColor("#0000FF")!)
    ]
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .linearGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], linearGradients: ["g": gradient])

    let kotlin = ImageVectorGenerator.generate(from: svg, name: "TestIcon")

    XCTAssertTrue(kotlin.contains("import androidx.compose.ui.graphics.Brush"))
    XCTAssertTrue(kotlin.contains("import androidx.compose.ui.geometry.Offset"))
    XCTAssertTrue(kotlin.contains("Brush.linearGradient("))
    XCTAssertTrue(kotlin.contains("0.0f to Color(0xFFFF0000)"))
    XCTAssertTrue(kotlin.contains("1.0f to Color(0xFF0000FF)"))
    XCTAssertTrue(kotlin.contains("start = Offset(0.0f, 0.0f)"))
    XCTAssertTrue(kotlin.contains("end = Offset(24.0f, 24.0f)"))
}
```

#### Test 4.2: Generate Brush.radialGradient

```swift
func testGenerateRadialGradientBrush() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FFFFFF")!),
        SVGGradientStop(offset: 1, color: SVGColor("#000000")!)
    ]
    let gradient = SVGRadialGradient(id: "g", cx: 12, cy: 12, r: 12, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .radialGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], radialGradients: ["g": gradient])

    let kotlin = ImageVectorGenerator.generate(from: svg, name: "TestIcon")

    XCTAssertTrue(kotlin.contains("Brush.radialGradient("))
    XCTAssertTrue(kotlin.contains("center = Offset(12.0f, 12.0f)"))
    XCTAssertTrue(kotlin.contains("radius = 12.0f"))
}
```

#### Test 4.3: Gradient stop with opacity

```swift
func testGradientStopOpacityInCompose() throws {
    let stops = [
        SVGGradientStop(offset: 0, color: SVGColor("#FF0000")!, opacity: 0.5),
        SVGGradientStop(offset: 1, color: SVGColor("#0000FF")!, opacity: 1.0)
    ]
    let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 24, y2: 0, stops: stops)
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .linearGradient(gradient))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path], linearGradients: ["g": gradient])

    let kotlin = ImageVectorGenerator.generate(from: svg, name: "TestIcon")

    // 0.5 opacity = 0x80 alpha
    XCTAssertTrue(kotlin.contains("Color(0x80FF0000)"))
    XCTAssertTrue(kotlin.contains("Color(0xFF0000FF)"))
}
```

#### Test 4.4: Backward compatibility (solid colors still work)

```swift
func testSolidColorStillWorks() throws {
    let path = SVGPath(pathData: "M0 0h24v24H0z", fill: .solid(SVGColor("#FF0000")!))
    let svg = ParsedSVG(width: 24, height: 24, paths: [path])

    let kotlin = ImageVectorGenerator.generate(from: svg, name: "TestIcon")

    XCTAssertTrue(kotlin.contains("SolidColor(Color(0xFFFF0000))"))
    XCTAssertFalse(kotlin.contains("Brush.linearGradient"))
}
```

#### Implementation 4: ImageVectorGenerator additions

```swift
// Sources/SVGKit/ImageVectorGenerator.swift

extension ImageVectorGenerator {

    private static func generateFillBrush(_ fill: SVGFill) -> String {
        switch fill {
        case .none:
            return "null"
        case .solid(let color):
            return "SolidColor(Color(\(color.composeHex)))"
        case .linearGradient(let gradient):
            return generateLinearGradientBrush(gradient)
        case .radialGradient(let gradient):
            return generateRadialGradientBrush(gradient)
        }
    }

    private static func generateLinearGradientBrush(_ gradient: SVGLinearGradient) -> String {
        var code = "Brush.linearGradient(\n"
        code += "                colorStops = arrayOf(\n"

        for stop in gradient.stops {
            let hex = colorToComposeHex(stop.color, opacity: stop.opacity)
            code += "                    \(fmt(stop.offset))f to Color(\(hex)),\n"
        }

        code += "                ),\n"
        code += "                start = Offset(\(fmt(gradient.x1))f, \(fmt(gradient.y1))f),\n"
        code += "                end = Offset(\(fmt(gradient.x2))f, \(fmt(gradient.y2))f)\n"
        code += "            )"
        return code
    }

    private static func generateRadialGradientBrush(_ gradient: SVGRadialGradient) -> String {
        var code = "Brush.radialGradient(\n"
        code += "                colorStops = arrayOf(\n"

        for stop in gradient.stops {
            let hex = colorToComposeHex(stop.color, opacity: stop.opacity)
            code += "                    \(fmt(stop.offset))f to Color(\(hex)),\n"
        }

        code += "                ),\n"
        code += "                center = Offset(\(fmt(gradient.cx))f, \(fmt(gradient.cy))f),\n"
        code += "                radius = \(fmt(gradient.r))f\n"
        code += "            )"
        return code
    }

    private static func colorToComposeHex(_ color: SVGColor, opacity: Double) -> String {
        let alpha = Int(opacity * 255)
        return String(format: "0x%02X%02X%02X%02X", alpha, color.red, color.green, color.blue)
    }

    private static func needsBrushImports(_ svg: ParsedSVG) -> Bool {
        for path in svg.paths {
            if case .linearGradient = path.fill { return true }
            if case .radialGradient = path.fill { return true }
        }
        return false
    }
}
```

______________________________________________________________________

## Files to Modify

| File                                              | Changes                     |
| ------------------------------------------------- | --------------------------- |
| `Sources/SVGKit/SVGTypes.swift`                   | Add gradient types          |
| `Sources/SVGKit/SVGParser.swift`                  | Add gradient parsing        |
| `Sources/SVGKit/VectorDrawableXMLGenerator.swift` | Add gradient XML generation |
| `Sources/SVGKit/ImageVectorGenerator.swift`       | Add Brush generation        |

## New Test Files

| File                                                  | Tests         |
| ----------------------------------------------------- | ------------- |
| `Tests/SVGKitTests/SVGGradientTests.swift`            | Type tests    |
| `Tests/SVGKitTests/SVGGradientParsingTests.swift`     | Parser tests  |
| `Tests/SVGKitTests/VectorDrawableGradientTests.swift` | VD XML tests  |
| `Tests/SVGKitTests/ImageVectorGradientTests.swift`    | Compose tests |

## Execution Order (TDD)

1. Write `SVGGradientTests.swift` → Run (fail) → Implement types → Run (pass)
2. Write `SVGGradientParsingTests.swift` → Run (fail) → Implement parser → Run (pass)
3. Write `VectorDrawableGradientTests.swift` → Run (fail) → Implement VD generator → Run (pass)
4. Write `ImageVectorGradientTests.swift` → Run (fail) → Implement Compose generator → Run (pass)

## API Compatibility

- **Vector Drawable**: Requires `minSdkVersion 24` (Android 7.0)
- **Compose**: All versions (Brush API is stable)

## Limitations

1. **Elliptic radial gradients**: Android uses circular only, use `r` as radius
2. **spreadMethod reflect/repeat**: Android VD may not support, fall back to pad
3. **gradientTransform**: Not implemented in v1, can add later
4. **Sweep gradients**: Not in scope for v1

## References

- [usvg gradient spec](https://github.com/linebender/resvg/blob/main/crates/usvg/docs/spec.adoc)
- [FigX image_vector/usvg.rs](https://github.com/tonykolomeytsev/figx/blob/master/crates/lib/image_vector/src/usvg.rs)
- [FigX svg2drawable](https://github.com/tonykolomeytsev/figx/blob/master/crates/lib/svg2drawable/src/lib.rs)
- [Android VectorDrawable gradients](https://developer.android.com/reference/android/graphics/drawable/VectorDrawable)
- [Compose Brush API](https://developer.android.com/reference/kotlin/androidx/compose/ui/graphics/Brush)
