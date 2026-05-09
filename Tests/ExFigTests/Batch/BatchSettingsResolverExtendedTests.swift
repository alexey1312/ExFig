@testable import ExFigCLI
import Foundation
import XCTest

/// Coverage for multi-config / verbose / partial-config / sanitizer paths in
/// `BatchSettingsResolver`. Lives in its own suite to keep the original
/// `BatchSettingsResolverTests` under SwiftLint's type/file length limits.
final class BatchSettingsResolverExtendedTests: XCTestCase {
    // MARK: - Multi-Config: First Wins (T1)

    func testFirstConfigWinsAndSubsequentConfigsAreIgnored() async throws {
        let firstURL = try BatchResolverFixture.make(
            figma: "rateLimit = 25\nmaxRetries = 6",
            batch: "parallel = 8"
        )
        let secondURL = try BatchResolverFixture.make(
            figma: "rateLimit = 999\nmaxRetries = 99",
            batch: "parallel = 99"
        )
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [firstURL, secondURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 8, "first config wins")
        XCTAssertEqual(resolved.rateLimit, 25, "first config wins")
        XCTAssertEqual(resolved.maxRetries, 6, "first config wins")
    }

    // MARK: - Float64 timeout conversion (T2)

    func testFloat64TimeoutFromConfigConvertedToInt() async throws {
        // PKL `timeout` is `Number?` (Float64 in Swift codegen). Use a value with non-zero
        // fractional part so the pkl-swift decoder treats it as Double.
        let configURL = try BatchResolverFixture.make(figma: "timeout = 60.5", batch: nil)
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.timeout, 60, "Float64 → Int truncates fractional part")
    }

    func testFractionalConfigTimeoutTruncatedToInt() async throws {
        let configURL = try BatchResolverFixture.make(figma: "timeout = 30.7", batch: nil)
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.timeout, 30, "Float64 → Int truncates fractional part")
    }

    // MARK: - Verbose=true triggers ignored-block scan (T3)

    func testVerboseTriggersIgnoredPerTargetWarnings() async throws {
        let firstURL = try BatchResolverFixture.make(
            figma: "rateLimit = 25",
            batch: "parallel = 8"
        )
        let secondURL = try BatchResolverFixture.make(figma: nil, batch: "parallel = 99")
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }
        let ui = TerminalUI(outputMode: .quiet)

        // Should not crash with verbose=true; first-config values still win.
        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [firstURL, secondURL],
            verbose: true,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 8)
        XCTAssertEqual(resolved.rateLimit, 25)
    }

    // MARK: - Empty PKL section uses PKL defaults (T4)

    func testEmptyConfigSectionsResolveToDefaults() async throws {
        let configURL = try BatchResolverFixture.make(figma: "", batch: "")
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 3)
        XCTAssertFalse(resolved.failFast)
        XCTAssertFalse(resolved.resume)
        XCTAssertEqual(resolved.rateLimit, 10)
        XCTAssertEqual(resolved.maxRetries, 4)
        XCTAssertEqual(resolved.concurrentDownloads, 20)
        XCTAssertEqual(resolved.timeout, 30) // PKL default for figma.timeout
    }

    // MARK: - Partial PKL config (T5)

    func testPartialBatchBlockOnlyParallel() async throws {
        let configURL = try BatchResolverFixture.make(figma: nil, batch: "parallel = 5")
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 5)
        XCTAssertFalse(resolved.failFast)
        XCTAssertFalse(resolved.resume)
    }

    // MARK: - Sanitizer (I2)

    func testOutOfRangeRateLimitFromConfigFallsBackToDefault() {
        // PKL constraints would reject 0/negative on amends, but a hand-written config
        // could bypass them. Verify the sanitizer drops back to default.
        let ui = TerminalUI(outputMode: .quiet)
        XCTAssertEqual(FaultToleranceValidator.sanitizedRateLimit(0, ui: ui), 10)
        XCTAssertEqual(FaultToleranceValidator.sanitizedRateLimit(-5, ui: ui), 10)
        XCTAssertEqual(FaultToleranceValidator.sanitizedConcurrentDownloads(0, ui: ui), 20)
        XCTAssertEqual(FaultToleranceValidator.sanitizedMaxRetries(-1, ui: ui), 4)
        XCTAssertEqual(FaultToleranceValidator.sanitizedMaxRetries(1000, ui: ui), 4)
    }

    // MARK: - PKL/Swift defaults parity (T4 reinforced)

    func testPKLDefaultsMatchSwiftDefaults() {
        XCTAssertEqual(FaultToleranceDefaults.parallel, 3)
        XCTAssertEqual(FaultToleranceDefaults.rateLimit, 10)
        XCTAssertEqual(FaultToleranceDefaults.maxRetries, 4)
        XCTAssertEqual(FaultToleranceDefaults.concurrentDownloads, 20)
        XCTAssertEqual(FaultToleranceDefaults.timeoutSeconds, 30)
    }
}

/// Shared PKL fixture builder for `BatchSettingsResolver` tests.
enum BatchResolverFixture {
    static func make(figma: String?, batch: String?) throws -> URL {
        let schemasDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/ExFigCLI/Resources/Schemas")
        let exfigPath = schemasDir.appendingPathComponent("ExFig.pkl").path
        let figmaPath = schemasDir.appendingPathComponent("Figma.pkl").path
        let batchPath = schemasDir.appendingPathComponent("Batch.pkl").path

        var lines: [String] = [
            "amends \"\(exfigPath)\"",
            "import \"\(figmaPath)\"",
            "import \"\(batchPath)\"",
        ]
        if let figma {
            lines.append("figma = new Figma.FigmaConfig {")
            for line in figma.split(separator: "\n") {
                lines.append("  \(line)")
            }
            lines.append("}")
        }
        if let batch {
            lines.append("batch = new Batch.BatchConfig {")
            for line in batch.split(separator: "\n") {
                lines.append("  \(line)")
            }
            lines.append("}")
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("batch-settings-resolver-\(UUID().uuidString).pkl")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
