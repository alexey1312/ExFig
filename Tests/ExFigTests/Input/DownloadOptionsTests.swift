@testable import ExFig
import XCTest

final class DownloadOptionsTests: XCTestCase {
    // MARK: - Required Options

    func testParsesRequiredOptions() throws {
        let options = try DownloadOptions.parse([
            "--file-id", "abc123",
            "--frame", "Illustrations",
            "--output", "./images",
        ])

        XCTAssertEqual(options.fileId, "abc123")
        XCTAssertEqual(options.frameName, "Illustrations")
        XCTAssertEqual(options.outputPath, "./images")
    }

    func testParsesShortOptions() throws {
        let options = try DownloadOptions.parse([
            "-f", "xyz789",
            "-r", "Icons",
            "-o", "/tmp/output",
        ])

        XCTAssertEqual(options.fileId, "xyz789")
        XCTAssertEqual(options.frameName, "Icons")
        XCTAssertEqual(options.outputPath, "/tmp/output")
    }

    func testFailsWithoutRequiredOptions() {
        XCTAssertThrowsError(try DownloadOptions.parse([]))
        XCTAssertThrowsError(try DownloadOptions.parse(["--file-id", "abc"]))
        XCTAssertThrowsError(try DownloadOptions.parse(["--file-id", "abc", "--frame", "Icons"]))
    }

    // MARK: - Format Options

    func testDefaultFormat() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
        ])

        XCTAssertEqual(options.format, .png)
    }

    func testParsesAllFormats() throws {
        for format in ImageFormat.allCases {
            let options = try DownloadOptions.parse([
                "-f", "abc", "-r", "Frame", "-o", "./out",
                "--format", format.rawValue,
            ])
            XCTAssertEqual(options.format, format)
        }
    }

    func testDefaultScaleForPNG() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--format", "png",
        ])

        XCTAssertNil(options.scale)
        XCTAssertEqual(options.effectiveScale, 3.0)
    }

    func testCustomScale() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--scale", "2",
        ])

        XCTAssertEqual(options.scale, 2.0)
        XCTAssertEqual(options.effectiveScale, 2.0)
    }

    func testScaleIgnoredForVectorFormats() throws {
        let svgOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--format", "svg", "--scale", "2",
        ])

        XCTAssertTrue(svgOptions.isVectorFormat)
        XCTAssertEqual(svgOptions.effectiveScale, 1.0)

        let pdfOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--format", "pdf", "--scale", "3",
        ])

        XCTAssertTrue(pdfOptions.isVectorFormat)
        XCTAssertEqual(pdfOptions.effectiveScale, 1.0)
    }

    // MARK: - Scale Validation

    func testScaleValidationFailsForNegative() {
        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--scale", "-1",
        ]))
    }

    func testScaleValidationFailsForZero() {
        // ArgumentParser calls validate() during parsing
        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--scale", "0",
        ]))
    }

    func testScaleValidationFailsForTooLarge() {
        // ArgumentParser calls validate() during parsing
        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--scale", "5",
        ]))
    }

    func testScaleValidationPassesForValidRange() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--scale", "0.5",
        ])

        XCTAssertEqual(options.scale, 0.5)
    }

    // MARK: - Filtering Options

    func testParsesFilter() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--filter", "icon/*",
        ])

        XCTAssertEqual(options.filter, "icon/*")
    }

    func testParsesNameStyle() throws {
        let camelOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--name-style", "camelCase",
        ])
        XCTAssertEqual(camelOptions.nameStyle, .camelCase)

        let snakeOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--name-style", "snake_case",
        ])
        XCTAssertEqual(snakeOptions.nameStyle, .snakeCase)
    }

    func testParsesNameRegexOptions() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--name-validate-regexp", "^icon_(.*)$",
            "--name-replace-regexp", "ic_$1",
        ])

        XCTAssertEqual(options.nameValidateRegexp, "^icon_(.*)$")
        XCTAssertEqual(options.nameReplaceRegexp, "ic_$1")
    }

    // MARK: - Dark Mode Options

    func testParsesDarkModeSuffix() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--dark-mode-suffix", "_dark",
        ])

        XCTAssertEqual(options.darkModeSuffix, "_dark")
    }

    // MARK: - WebP Options

    func testDefaultWebPOptions() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
        ])

        XCTAssertEqual(options.webpEncoding, .lossy)
        XCTAssertEqual(options.webpQuality, 80)
    }

    func testParsesWebPEncoding() throws {
        let lossyOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--webp-encoding", "lossy",
        ])
        XCTAssertEqual(lossyOptions.webpEncoding, .lossy)

        let losslessOptions = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--webp-encoding", "lossless",
        ])
        XCTAssertEqual(losslessOptions.webpEncoding, .lossless)
    }

    func testParsesWebPQuality() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--webp-quality", "90",
        ])

        XCTAssertEqual(options.webpQuality, 90)
    }

    func testWebPQualityValidationFails() {
        // ArgumentParser calls validate() during parsing
        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--webp-quality", "101",
        ]))

        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--webp-quality", "-1",
        ]))
    }

    // MARK: - Timeout Options

    func testDefaultTimeout() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
        ])

        XCTAssertEqual(options.timeout, 30)
    }

    func testParsesTimeout() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--timeout", "60",
        ])

        XCTAssertEqual(options.timeout, 60)
    }

    func testTimeoutValidationFails() {
        // ArgumentParser calls validate() during parsing
        XCTAssertThrowsError(try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "./out",
            "--timeout", "0",
        ]))
    }

    // MARK: - Output URL

    func testOutputURL() throws {
        let options = try DownloadOptions.parse([
            "-f", "abc", "-r", "Frame", "-o", "/tmp/images",
        ])

        XCTAssertEqual(options.outputURL.path, "/tmp/images")
    }
}
