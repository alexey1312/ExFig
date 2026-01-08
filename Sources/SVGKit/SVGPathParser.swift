import Foundation

/// Represents an SVG path command for conversion to ImageVector
public enum SVGPathCommand: Equatable, Sendable {
    case moveTo(x: Double, y: Double, relative: Bool)
    case lineTo(x: Double, y: Double, relative: Bool)
    case horizontalLineTo(x: Double, relative: Bool)
    case verticalLineTo(y: Double, relative: Bool)
    case curveTo(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double, relative: Bool)
    case smoothCurveTo(x2: Double, y2: Double, x: Double, y: Double, relative: Bool)
    case quadraticBezierCurveTo(x1: Double, y1: Double, x: Double, y: Double, relative: Bool)
    case smoothQuadraticBezierCurveTo(x: Double, y: Double, relative: Bool)
    case arcTo(
        rx: Double,
        ry: Double,
        xAxisRotation: Double,
        largeArcFlag: Bool,
        sweepFlag: Bool,
        x: Double,
        y: Double,
        relative: Bool
    )
    case closePath
}

/// Parses SVG path data string into a sequence of commands
public struct SVGPathParser: Sendable {
    public init() {}

    // Parses an SVG path data string (d attribute) into commands
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func parse(_ pathData: String) throws -> [SVGPathCommand] {
        var commands: [SVGPathCommand] = []
        let scanner = PathScanner(pathData)

        while !scanner.isAtEnd {
            scanner.skipWhitespaceAndCommas()
            guard let command = scanner.scanCommand() else {
                if scanner.isAtEnd { break }
                throw SVGParseError.unexpectedCharacter(scanner.currentCharacter ?? "?")
            }

            let relative = command.first?.isLowercase ?? false
            let commandChar = command.uppercased()

            switch commandChar {
            case "M":
                let coords = try scanner.scanCoordinatePairs()
                for (index, pair) in coords.enumerated() {
                    if index == 0 {
                        commands.append(.moveTo(x: pair.0, y: pair.1, relative: relative))
                    } else {
                        // Subsequent coordinate pairs after M are treated as lineTo
                        commands.append(.lineTo(x: pair.0, y: pair.1, relative: relative))
                    }
                }
            case "L":
                let coords = try scanner.scanCoordinatePairs()
                for pair in coords {
                    commands.append(.lineTo(x: pair.0, y: pair.1, relative: relative))
                }
            case "H":
                let values = try scanner.scanNumbers()
                for x in values {
                    commands.append(.horizontalLineTo(x: x, relative: relative))
                }
            case "V":
                let values = try scanner.scanNumbers()
                for y in values {
                    commands.append(.verticalLineTo(y: y, relative: relative))
                }
            case "C":
                let coords = try scanner.scanCoordinatePairs(count: 3)
                for i in stride(from: 0, to: coords.count, by: 3) {
                    commands.append(.curveTo(
                        x1: coords[i].0, y1: coords[i].1,
                        x2: coords[i + 1].0, y2: coords[i + 1].1,
                        x: coords[i + 2].0, y: coords[i + 2].1,
                        relative: relative
                    ))
                }
            case "S":
                let coords = try scanner.scanCoordinatePairs(count: 2)
                for i in stride(from: 0, to: coords.count, by: 2) {
                    commands.append(.smoothCurveTo(
                        x2: coords[i].0, y2: coords[i].1,
                        x: coords[i + 1].0, y: coords[i + 1].1,
                        relative: relative
                    ))
                }
            case "Q":
                let coords = try scanner.scanCoordinatePairs(count: 2)
                for i in stride(from: 0, to: coords.count, by: 2) {
                    commands.append(.quadraticBezierCurveTo(
                        x1: coords[i].0, y1: coords[i].1,
                        x: coords[i + 1].0, y: coords[i + 1].1,
                        relative: relative
                    ))
                }
            case "T":
                let coords = try scanner.scanCoordinatePairs()
                for pair in coords {
                    commands.append(.smoothQuadraticBezierCurveTo(x: pair.0, y: pair.1, relative: relative))
                }
            case "A":
                let arcs = try scanner.scanArcArguments()
                for arc in arcs {
                    commands.append(.arcTo(
                        rx: arc.rx, ry: arc.ry,
                        xAxisRotation: arc.xAxisRotation,
                        largeArcFlag: arc.largeArcFlag,
                        sweepFlag: arc.sweepFlag,
                        x: arc.x, y: arc.y,
                        relative: relative
                    ))
                }
            case "Z":
                commands.append(.closePath)
            default:
                throw SVGParseError.unknownCommand(commandChar)
            }
        }

        return commands
    }
}

// MARK: - Errors

public enum SVGParseError: Error, LocalizedError {
    case unexpectedCharacter(String)
    case unexpectedEndOfInput
    case invalidNumber(String)
    case unknownCommand(String)
    case invalidArcArguments

    public var errorDescription: String? {
        switch self {
        case let .unexpectedCharacter(char):
            "Unexpected character: \(char)"
        case .unexpectedEndOfInput:
            "Unexpected end of path data"
        case let .invalidNumber(str):
            "Invalid number: \(str)"
        case let .unknownCommand(cmd):
            "Unknown SVG path command: \(cmd)"
        case .invalidArcArguments:
            "Invalid arc arguments"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unexpectedCharacter, .unknownCommand:
            "Check SVG path syntax"
        case .unexpectedEndOfInput:
            "Ensure path data is complete"
        case .invalidNumber:
            "Check numeric values in path data"
        case .invalidArcArguments:
            "Verify arc command parameters (rx, ry, rotation, flags, x, y)"
        }
    }
}

// MARK: - Internal Scanner

private final class PathScanner: @unchecked Sendable {
    private let originalInput: String
    private let input: String.UTF8View
    private var index: String.UTF8View.Index

    // Lookup table for whitespace characters
    // 0x09: tab, 0x0A: line feed, 0x0C: form feed, 0x0D: carriage return, 0x20: space
    private static let whitespaceBytes: Set<UInt8> = [0x09, 0x0A, 0x0C, 0x0D, 0x20]

    var isAtEnd: Bool {
        index >= input.endIndex
    }

    var currentCharacter: String? {
        guard !isAtEnd else { return nil }
        return String(UnicodeScalar(input[index]))
    }

    init(_ input: String) {
        self.originalInput = input
        self.input = input.utf8
        index = self.input.startIndex
    }

    func skipWhitespaceAndCommas() {
        while !isAtEnd {
            let byte = input[index]
            // Skip whitespace and comma (0x2C)
            if PathScanner.whitespaceBytes.contains(byte) || byte == 0x2C {
                index = input.index(after: index)
            } else {
                break
            }
        }
    }

    func scanCommand() -> String? {
        skipWhitespaceAndCommas()
        guard !isAtEnd else { return nil }
        let byte = input[index]
        // Check for ASCII letters (A-Z, a-z)
        if byte >= 0x41 && byte <= 0x5A || byte >= 0x61 && byte <= 0x7A {
            index = input.index(after: index)
            return String(UnicodeScalar(byte))
        }
        return nil
    }

    // swiftlint:disable:next cyclomatic_complexity
    func scanNumber() throws -> Double? {
        skipWhitespaceAndCommas()
        guard !isAtEnd else { return nil }

        let startIndex = index
        let firstByte = input[index]

        // Check if this is a command letter, not a number
        // A-Z (0x41-0x5A) or a-z (0x61-0x7A)
        // Except 'e' or 'E' which could be part of a number, but not at the start
        if firstByte >= 0x41 && firstByte <= 0x5A || firstByte >= 0x61 && firstByte <= 0x7A {
            return nil
        }

        // Handle sign
        // + (0x2B), - (0x2D)
        if firstByte == 0x2D || firstByte == 0x2B {
            index = input.index(after: index)
        }

        // Scan digits and decimal point
        var hasDecimal = false
        var hasExponent = false

        while !isAtEnd {
            let byte = input[index]
            // 0-9 (0x30-0x39)
            if byte >= 0x30 && byte <= 0x39 {
                index = input.index(after: index)
            } else if byte == 0x2E, !hasDecimal, !hasExponent { // .
                hasDecimal = true
                index = input.index(after: index)
            } else if byte == 0x65 || byte == 0x45, !hasExponent { // e or E
                hasExponent = true
                index = input.index(after: index)
                // Handle optional sign after exponent
                if !isAtEnd {
                    let nextByte = input[index]
                    if nextByte == 0x2B || nextByte == 0x2D { // + or -
                        index = input.index(after: index)
                    }
                }
            } else {
                break
            }
        }

        let substring = originalInput[startIndex ..< index]
        // Optimize: Use Substring directly to avoid String allocation
        guard !substring.isEmpty, let value = Double(substring) else {
            if substring.isEmpty { return nil }
            throw SVGParseError.invalidNumber(String(substring))
        }

        return value
    }

    func scanNumbers() throws -> [Double] {
        var numbers: [Double] = []
        while let num = try scanNumber() {
            numbers.append(num)
        }
        return numbers
    }

    func scanCoordinatePairs(count: Int = 1) throws -> [(Double, Double)] {
        var pairs: [(Double, Double)] = []
        while let x = try scanNumber() {
            guard let y = try scanNumber() else {
                throw SVGParseError.unexpectedEndOfInput
            }
            pairs.append((x, y))
        }
        return pairs
    }

    func scanArcArguments() throws -> [ArcArgument] {
        var arcs: [ArcArgument] = []
        while let rx = try scanNumber() {
            guard let ry = try scanNumber(),
                  let xAxisRotation = try scanNumber(),
                  let largeArcFlagValue = try scanNumber(),
                  let sweepFlagValue = try scanNumber(),
                  let x = try scanNumber(),
                  let y = try scanNumber()
            else {
                throw SVGParseError.invalidArcArguments
            }

            arcs.append(ArcArgument(
                rx: rx, ry: ry,
                xAxisRotation: xAxisRotation,
                largeArcFlag: largeArcFlagValue != 0,
                sweepFlag: sweepFlagValue != 0,
                x: x, y: y
            ))
        }
        return arcs
    }
}

private struct ArcArgument {
    let rx: Double
    let ry: Double
    let xAxisRotation: Double
    let largeArcFlag: Bool
    let sweepFlag: Bool
    let x: Double
    let y: Double
}
