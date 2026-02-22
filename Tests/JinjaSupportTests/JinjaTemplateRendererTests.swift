import Foundation
@testable import JinjaSupport
import XCTest

final class JinjaTemplateRendererTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("JinjaSupportTests-\(UUID().uuidString)")
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Fallback from custom path to bundle

    func testLoadTemplate_fallsThroughToBundleWhenNotInCustomPath() throws {
        // Given: a custom path that does NOT contain the requested template
        let bundleDir = tempDir.appendingPathComponent("bundle/Resources")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "bundle content".write(
            to: bundleDir.appendingPathComponent("fallback.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = try XCTUnwrap(Bundle(path: tempDir.appendingPathComponent("bundle").path))
        let customPath = tempDir.appendingPathComponent("custom")
        try FileManager.default.createDirectory(at: customPath, withIntermediateDirectories: true)

        let renderer = JinjaTemplateRenderer(bundle: bundle)

        // When: loading a template that only exists in the bundle
        let result = try renderer.loadTemplate(named: "fallback.jinja", templatesPath: customPath)

        // Then: falls back to bundle
        XCTAssertEqual(result, "bundle content")
    }

    func testLoadTemplate_prefersCustomPathOverBundle() throws {
        // Given: both custom path and bundle have the template
        let bundleDir = tempDir.appendingPathComponent("bundle/Resources")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "bundle content".write(
            to: bundleDir.appendingPathComponent("shared.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = try XCTUnwrap(Bundle(path: tempDir.appendingPathComponent("bundle").path))
        let customPath = tempDir.appendingPathComponent("custom")
        try FileManager.default.createDirectory(at: customPath, withIntermediateDirectories: true)
        try "custom content".write(
            to: customPath.appendingPathComponent("shared.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let renderer = JinjaTemplateRenderer(bundle: bundle)

        // When: loading a template that exists in both locations
        let result = try renderer.loadTemplate(named: "shared.jinja", templatesPath: customPath)

        // Then: custom path takes priority
        XCTAssertEqual(result, "custom content")
    }

    func testLoadTemplate_throwsWhenNotFoundAnywhere() throws {
        // Given: empty custom path and empty bundle
        let bundleDir = tempDir.appendingPathComponent("bundle")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        let bundle = try XCTUnwrap(Bundle(path: bundleDir.path))
        let customPath = tempDir.appendingPathComponent("custom")
        try FileManager.default.createDirectory(at: customPath, withIntermediateDirectories: true)

        let renderer = JinjaTemplateRenderer(bundle: bundle)

        // When/Then: throws not found
        XCTAssertThrowsError(try renderer.loadTemplate(named: "missing.jinja", templatesPath: customPath)) { error in
            guard case let TemplateLoadError.notFound(name, paths) = error else {
                XCTFail("Expected TemplateLoadError.notFound, got \(error)")
                return
            }
            XCTAssertEqual(name, "missing.jinja")
            XCTAssertTrue(paths.contains(customPath.path), "Should include custom path in searched paths")
        }
    }

    func testLoadTemplate_fallbackWithDefaultTemplatesPath() throws {
        // Given: renderer initialized with defaultTemplatesPath that misses a file
        let bundleDir = tempDir.appendingPathComponent("bundle/Resources")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "from bundle".write(
            to: bundleDir.appendingPathComponent("include.jinja.include"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = try XCTUnwrap(Bundle(path: tempDir.appendingPathComponent("bundle").path))
        let customPath = tempDir.appendingPathComponent("custom")
        try FileManager.default.createDirectory(at: customPath, withIntermediateDirectories: true)

        let renderer = JinjaTemplateRenderer(bundle: bundle, templatesPath: customPath)

        // When: loading without explicit templatesPath (uses defaultTemplatesPath)
        let result = try renderer.loadTemplate(named: "include.jinja.include")

        // Then: falls back to bundle
        XCTAssertEqual(result, "from bundle")
    }
}
