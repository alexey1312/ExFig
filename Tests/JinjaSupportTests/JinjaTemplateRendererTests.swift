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

    func testLoadTemplate_perCallPathOverridesDefaultPath() throws {
        // Given: renderer with defaultTemplatesPath, per-call path has different content
        let defaultPath = tempDir.appendingPathComponent("default")
        let perCallPath = tempDir.appendingPathComponent("perCall")
        try FileManager.default.createDirectory(at: defaultPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: perCallPath, withIntermediateDirectories: true)
        try "default content".write(
            to: defaultPath.appendingPathComponent("test.jinja"),
            atomically: true,
            encoding: .utf8
        )
        try "per-call content".write(
            to: perCallPath.appendingPathComponent("test.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = Bundle.main
        let renderer = JinjaTemplateRenderer(bundle: bundle, templatesPath: defaultPath)

        // When: loading with explicit per-call templatesPath
        let result = try renderer.loadTemplate(named: "test.jinja", templatesPath: perCallPath)

        // Then: per-call path takes priority over defaultTemplatesPath
        XCTAssertEqual(result, "per-call content")
    }

    func testLoadTemplate_throwsWhenBundleResourcePathIsNil() throws {
        // Given: a bundle with nil resourcePath, no custom path
        let bundle = Bundle(path: "/nonexistent") ?? Bundle.main
        guard bundle.resourcePath == nil else {
            // Cannot construct a nil-resourcePath bundle on this platform; skip
            return
        }
        let renderer = JinjaTemplateRenderer(bundle: bundle)

        // When/Then: throws notFound with diagnostic message
        XCTAssertThrowsError(try renderer.loadTemplate(named: "test.jinja")) { error in
            guard case let TemplateLoadError.notFound(_, paths) = error else {
                XCTFail("Expected notFound, got \(error)")
                return
            }
            XCTAssertTrue(paths.contains("(bundle.resourcePath is nil)"))
        }
    }

    // MARK: - renderTemplate(source:context:)

    func testRenderTemplate_withStringContext() throws {
        let renderer = makeRenderer()
        let result = try renderer.renderTemplate(
            source: "Hello, {{ name }}!",
            context: ["name": "World"]
        )
        XCTAssertEqual(result, "Hello, World!")
    }

    func testRenderTemplate_withBooleanContext() throws {
        let renderer = makeRenderer()
        let result = try renderer.renderTemplate(
            source: "{% if flag %}yes{% else %}no{% endif %}",
            context: ["flag": true]
        )
        XCTAssertEqual(result, "yes")
    }

    func testRenderTemplate_withNestedArrayOfDictionaries() throws {
        let renderer = makeRenderer()
        let items: [[String: String]] = [
            ["name": "Alice"],
            ["name": "Bob"],
        ]
        let result = try renderer.renderTemplate(
            source: "{% for item in items %}{{ item.name }}{% if not loop.last %}, {% endif %}{% endfor %}",
            context: ["items": items]
        )
        XCTAssertEqual(result, "Alice, Bob")
    }

    func testRenderTemplate_withEmptyContext() throws {
        let renderer = makeRenderer()
        let result = try renderer.renderTemplate(
            source: "static text",
            context: [:]
        )
        XCTAssertEqual(result, "static text")
    }

    func testRenderTemplate_withIntAndDoubleValues() throws {
        let renderer = makeRenderer()
        let result = try renderer.renderTemplate(
            source: "count={{ count }}, ratio={{ ratio }}",
            context: ["count": 42, "ratio": 3.14]
        )
        XCTAssertEqual(result, "count=42, ratio=3.14")
    }

    // MARK: - Error propagation

    func testRenderTemplate_invalidSyntaxThrowsError() throws {
        let renderer = makeRenderer()
        XCTAssertThrowsError(
            try renderer.renderTemplate(
                source: "{% for x in items %}no endfor",
                context: ["items": ["a"]]
            )
        )
    }

    func testRenderTemplate_invalidSyntaxWrapsWithTemplateName() throws {
        let renderer = makeRenderer()
        XCTAssertThrowsError(
            try renderer.renderTemplate(
                source: "{% for x in items %}no endfor",
                context: ["items": ["a"]],
                templateName: "broken.jinja"
            )
        ) { error in
            guard case let TemplateLoadError.renderFailed(name, _) = error else {
                XCTFail("Expected TemplateLoadError.renderFailed, got \(error)")
                return
            }
            XCTAssertEqual(name, "broken.jinja")
        }
    }

    func testRenderTemplate_unsupportedContextValueThrowsContextConversionFailed() throws {
        let renderer = makeRenderer()
        struct NotConvertible {}
        XCTAssertThrowsError(
            try renderer.renderTemplate(source: "{{ value }}", context: ["value": NotConvertible()])
        ) { error in
            guard case let TemplateLoadError.contextConversionFailed(key, valueType, _) = error else {
                XCTFail("Expected contextConversionFailed, got \(error)")
                return
            }
            XCTAssertEqual(key, "value")
            XCTAssertTrue(valueType.contains("NotConvertible"))
        }
    }

    func testRenderTemplateByName_wrapsRenderErrorWithTemplateName() throws {
        let bundleDir = tempDir.appendingPathComponent("bundle/Resources")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "{% for x in items %}no endfor".write(
            to: bundleDir.appendingPathComponent("bad.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = try XCTUnwrap(Bundle(path: tempDir.appendingPathComponent("bundle").path))
        let renderer = JinjaTemplateRenderer(bundle: bundle)

        XCTAssertThrowsError(
            try renderer.renderTemplate(name: "bad.jinja", context: ["items": ["a"]])
        ) { error in
            guard case let TemplateLoadError.renderFailed(name, _) = error else {
                XCTFail("Expected TemplateLoadError.renderFailed, got \(error)")
                return
            }
            XCTAssertEqual(name, "bad.jinja")
        }
    }

    // MARK: - contextWithHeader

    func testContextWithHeader_loadsHeaderAndMergesIntoContext() throws {
        let bundleDir = tempDir.appendingPathComponent("bundle/Resources")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "// Do not edit".write(
            to: bundleDir.appendingPathComponent("header.jinja"),
            atomically: true,
            encoding: .utf8
        )

        let bundle = try XCTUnwrap(Bundle(path: tempDir.appendingPathComponent("bundle").path))
        let renderer = JinjaTemplateRenderer(bundle: bundle)

        let ctx = try renderer.contextWithHeader(["foo": "bar"])

        XCTAssertEqual(ctx["foo"] as? String, "bar")
        XCTAssertEqual(ctx["header"] as? String, "// Do not edit")
    }

    // MARK: - Helpers

    private func makeRenderer() -> JinjaTemplateRenderer {
        JinjaTemplateRenderer(bundle: Bundle.main)
    }
}
