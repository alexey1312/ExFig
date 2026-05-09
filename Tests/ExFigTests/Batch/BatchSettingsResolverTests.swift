@testable import ExFigCLI
import Foundation
import XCTest

final class BatchSettingsResolverTests: XCTestCase {
    // MARK: - Defaults Without First Config

    func testAllDefaultsWhenNoConfigsNoCLI() async {
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 3)
        XCTAssertFalse(resolved.failFast)
        XCTAssertFalse(resolved.resume)
        XCTAssertEqual(resolved.rateLimit, 10)
        XCTAssertEqual(resolved.maxRetries, 4)
        XCTAssertEqual(resolved.concurrentDownloads, 20)
        XCTAssertNil(resolved.timeout)
    }

    // MARK: - CLI Wins When Config Missing

    func testCLIValuesUsedWhenNoFirstConfig() async {
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: 8,
            cliFailFast: true,
            cliResume: true,
            cliRateLimit: 25,
            cliMaxRetries: 6,
            cliConcurrentDownloads: 50,
            cliTimeout: 120,
            allConfigs: [],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 8)
        XCTAssertTrue(resolved.failFast)
        XCTAssertTrue(resolved.resume)
        XCTAssertEqual(resolved.rateLimit, 25)
        XCTAssertEqual(resolved.maxRetries, 6)
        XCTAssertEqual(resolved.concurrentDownloads, 50)
        XCTAssertEqual(resolved.timeout, 120)
    }

    // MARK: - First Config Wins When CLI Missing

    func testFirstConfigBatchAndFigmaFieldsUsedWhenNoCLI() async throws {
        let configURL = try makeConfigPKL(
            figma: "rateLimit = 25\nmaxRetries = 6\nconcurrentDownloads = 50",
            batch: "parallel = 8\nfailFast = true\nresume = true"
        )
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

        XCTAssertEqual(resolved.parallel, 8)
        XCTAssertTrue(resolved.failFast)
        XCTAssertTrue(resolved.resume)
        XCTAssertEqual(resolved.rateLimit, 25)
        XCTAssertEqual(resolved.maxRetries, 6)
        XCTAssertEqual(resolved.concurrentDownloads, 50)
    }

    func testCLIOverridesFirstConfig() async throws {
        let configURL = try makeConfigPKL(
            figma: "rateLimit = 25\nmaxRetries = 6",
            batch: "parallel = 8"
        )
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: 4,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: 30,
            cliMaxRetries: 2,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 4) // CLI wins
        XCTAssertEqual(resolved.rateLimit, 30) // CLI wins
        XCTAssertEqual(resolved.maxRetries, 2) // CLI wins
        XCTAssertEqual(resolved.concurrentDownloads, 20) // default (no CLI, no config)
    }

    // MARK: - Boolean OR Semantics

    func testFailFastORedFromCLIAndConfig() async throws {
        // Config has failFast=true, CLI doesn't pass it → result is true
        let configURL = try makeConfigPKL(figma: nil, batch: "failFast = true")
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

        XCTAssertTrue(resolved.failFast)
    }

    func testResumeORedFromCLIWhenConfigFalse() async throws {
        // Config has resume=false, CLI passes --resume → result is true
        let configURL = try makeConfigPKL(figma: nil, batch: "resume = false")
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: true,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui
        )

        XCTAssertTrue(resolved.resume)
    }

    // MARK: - Invalid First Config Falls Back

    func testInvalidFirstConfigFallsBackToDefaults() async {
        let bogusURL = URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).pkl")
        let ui = TerminalUI(outputMode: .quiet)

        let resolved = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [bogusURL],
            verbose: false,
            ui: ui
        )

        XCTAssertEqual(resolved.parallel, 3)
        XCTAssertEqual(resolved.rateLimit, 10)
        XCTAssertEqual(resolved.maxRetries, 4)
        XCTAssertEqual(resolved.concurrentDownloads, 20)
    }

    // MARK: - Helpers

    private func makeConfigPKL(figma: String?, batch: String?) throws -> URL {
        // Pull the schemas next to a per-test temp directory by referencing them via the project's
        // package URI substitution flow. For these unit tests we use the shipped local schemas.
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
