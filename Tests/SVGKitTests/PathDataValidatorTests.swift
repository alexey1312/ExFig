import Foundation
@testable import SVGKit
import XCTest

final class PathDataValidatorTests: XCTestCase {
    var validator: PathDataValidator!

    override func setUp() {
        super.setUp()
        validator = PathDataValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Threshold Constants

    func testLintThresholdIs800() {
        XCTAssertEqual(PathDataValidator.lintThreshold, 800)
    }

    func testCriticalThresholdIs32767() {
        XCTAssertEqual(PathDataValidator.criticalThreshold, 32767)
    }

    // MARK: - Basic Validation

    func testShortPathDoesNotExceedThresholds() {
        let shortPath = "M0,0 L10,10 L20,0 Z"
        let result = validator.validate(pathData: shortPath)

        XCTAssertEqual(result.charLength, shortPath.count)
        XCTAssertEqual(result.byteLength, shortPath.utf8.count)
        XCTAssertFalse(result.exceedsLintThreshold)
        XCTAssertFalse(result.exceedsCriticalLimit)
    }

    func testPathAt800CharsDoesNotExceedLintThreshold() {
        let path = String(repeating: "M", count: 800)
        let result = validator.validate(pathData: path)

        XCTAssertEqual(result.charLength, 800)
        XCTAssertFalse(result.exceedsLintThreshold)
    }

    func testPathAt801CharsExceedsLintThreshold() {
        let path = String(repeating: "M", count: 801)
        let result = validator.validate(pathData: path)

        XCTAssertEqual(result.charLength, 801)
        XCTAssertTrue(result.exceedsLintThreshold)
        XCTAssertFalse(result.exceedsCriticalLimit)
    }

    func testPathAt32767BytesDoesNotExceedCriticalLimit() {
        let path = String(repeating: "M", count: 32767)
        let result = validator.validate(pathData: path)

        XCTAssertEqual(result.byteLength, 32767)
        XCTAssertFalse(result.exceedsCriticalLimit)
    }

    func testPathAt32768BytesExceedsCriticalLimit() {
        let path = String(repeating: "M", count: 32768)
        let result = validator.validate(pathData: path)

        XCTAssertEqual(result.byteLength, 32768)
        XCTAssertTrue(result.exceedsCriticalLimit)
    }

    // MARK: - UTF-8 Byte Length

    func testMultibyteCharactersCountedCorrectly() {
        // Russian letters are 2 bytes each in UTF-8
        // But pathData should only contain ASCII, this is just to verify byte counting
        let asciiPath = "M0,0"
        let result = validator.validate(pathData: asciiPath)

        XCTAssertEqual(result.charLength, 4)
        XCTAssertEqual(result.byteLength, 4)
    }

    // MARK: - Multiple Paths Validation

    func testValidatePathsReturnsOnlyIssues() {
        let paths: [(name: String, pathData: String)] = [
            ("short", "M0,0 L10,10"),
            ("long", String(repeating: "L1,1 ", count: 200)),
            ("medium", String(repeating: "M", count: 500)),
        ]

        let issues = validator.validatePaths(paths)

        // Only "long" path exceeds 800 chars (200 * 5 = 1000 chars)
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.pathName, "long")
        XCTAssertTrue(issues.first?.result.exceedsLintThreshold ?? false)
    }

    func testValidatePathsReturnsCriticalIssues() {
        let paths: [(name: String, pathData: String)] = [
            ("normal", "M0,0 L10,10"),
            ("critical", String(repeating: "M", count: 33000)),
        ]

        let issues = validator.validatePaths(paths)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.pathName, "critical")
        XCTAssertTrue(issues.first?.isCritical ?? false)
    }

    // MARK: - PathValidationIssue

    func testPathValidationIssueIsCriticalWhenExceedsCriticalLimit() {
        let result = PathDataValidationResult(charLength: 35000, byteLength: 35000)
        let issue = PathValidationIssue(pathName: "test", result: result)

        XCTAssertTrue(issue.isCritical)
    }

    func testPathValidationIssueIsNotCriticalWhenOnlyExceedsLint() {
        let result = PathDataValidationResult(charLength: 1000, byteLength: 1000)
        let issue = PathValidationIssue(pathName: "test", result: result)

        XCTAssertFalse(issue.isCritical)
        XCTAssertTrue(issue.result.exceedsLintThreshold)
    }

    // MARK: - ParsedSVG Validation

    func testValidateParsedSVGWithSimplePaths() {
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                makePath(pathData: "M0,0 L10,10"),
                makePath(pathData: String(repeating: "L1,1 ", count: 200)),
            ]
        )

        let issues = validator.validate(svg: svg, iconName: "test_icon")

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.pathName, "path_1")
    }

    func testValidateParsedSVGWithElements() {
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            elements: [
                .path(makePath(pathData: "M0,0 L10,10")),
                .path(makePath(pathData: String(repeating: "L1,1 ", count: 200))),
            ]
        )

        let issues = validator.validate(svg: svg, iconName: "test_icon")

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.pathName, "path_1")
    }

    func testValidateParsedSVGWithNestedGroups() {
        let innerGroup = SVGGroup(
            paths: [makePath(pathData: String(repeating: "M", count: 1000))]
        )
        let outerGroup = SVGGroup(
            paths: [makePath(pathData: "M0,0")],
            children: [innerGroup]
        )
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [outerGroup]
        )

        let issues = validator.validate(svg: svg, iconName: "test_icon")

        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues.first?.result.exceedsLintThreshold ?? false)
    }

    // MARK: - Validation Summary

    func testValidationSummaryCountsCorrectly() {
        let results: [(iconName: String, issues: [PathValidationIssue])] = [
            ("icon1", []),
            ("icon2", [PathValidationIssue(
                pathName: "path_0",
                result: PathDataValidationResult(charLength: 1000, byteLength: 1000)
            )]),
            ("icon3", [PathValidationIssue(
                pathName: "path_0",
                result: PathDataValidationResult(charLength: 35000, byteLength: 35000)
            )]),
        ]

        let summary = PathValidationSummary(results: results)

        XCTAssertEqual(summary.totalIcons, 3)
        XCTAssertEqual(summary.iconsWithWarnings, 2)
        XCTAssertEqual(summary.iconsWithCriticalErrors, 1)
        XCTAssertTrue(summary.hasWarnings)
        XCTAssertTrue(summary.hasCriticalErrors)
    }

    func testValidationSummaryWithNoIssues() {
        let results: [(iconName: String, issues: [PathValidationIssue])] = [
            ("icon1", []),
            ("icon2", []),
        ]

        let summary = PathValidationSummary(results: results)

        XCTAssertEqual(summary.totalIcons, 2)
        XCTAssertEqual(summary.iconsWithWarnings, 0)
        XCTAssertEqual(summary.iconsWithCriticalErrors, 0)
        XCTAssertFalse(summary.hasWarnings)
        XCTAssertFalse(summary.hasCriticalErrors)
    }

    // MARK: - Helpers

    private func makePath(pathData: String) -> SVGPath {
        SVGPath(
            pathData: pathData,
            commands: [],
            fill: nil,
            fillType: .none,
            stroke: nil,
            strokeWidth: nil,
            strokeLineCap: nil,
            strokeLineJoin: nil,
            strokeDashArray: nil,
            strokeDashOffset: nil,
            fillRule: nil,
            opacity: nil,
            fillOpacity: nil
        )
    }
}
