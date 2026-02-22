import ExFigCore
import Foundation
import JinjaSupport

public class XcodeExporterBase {
    private let renderer: JinjaTemplateRenderer

    init() {
        renderer = JinjaTemplateRenderer(bundle: Bundle.module)
    }

    /// All Swift keywords that need escaping with backticks when used as identifiers.
    /// Using a Set for O(1) lookup instead of O(n) array search.
    private static let swiftKeywords: Set<String> = [
        // Declaration keywords
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var",
        // Statement keywords
        "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
        "switch", "where", "while",
        // Expression keywords
        "Any", "as", "false", "is", "nil", "self", "Self", "super", "throws", "true", "try",
        // Other keywords
        "associativity", "convenience", "didSet", "dynamic", "final", "get",
        "indirect", "infix", "lazy", "left", "mutating", "none", "nonmutating",
        "optional", "override", "postfix", "precedence", "prefix", "Protocol",
        "required", "right", "set", "some", "Type", "unowned", "weak", "willSet",
    ]

    func normalizeName(_ name: String) -> String {
        if Self.swiftKeywords.contains(name) {
            return "`\(name)`"
        }
        return name
    }

    func renderTemplate(
        name: String,
        context: [String: Any],
        templatesPath: URL?
    ) throws -> String {
        try renderer.renderTemplate(name: name, context: context, templatesPath: templatesPath)
    }

    func renderTemplate(source: String, context: [String: Any], templateName: String? = nil) throws -> String {
        try renderer.renderTemplate(source: source, context: context, templateName: templateName)
    }

    func loadTemplate(named name: String, templatesPath: URL?) throws -> String {
        try renderer.loadTemplate(named: name, templatesPath: templatesPath)
    }

    func contextWithHeader(
        _ context: [String: Any],
        templatesPath: URL?
    ) throws -> [String: Any] {
        try renderer.contextWithHeader(context, templatesPath: templatesPath)
    }

    func contextWithHeaderAndBundle(
        _ context: [String: Any],
        templatesPath: URL?
    ) throws -> [String: Any] {
        var ctx = try contextWithHeader(context, templatesPath: templatesPath)
        let bundleExtension = try renderTemplate(
            name: "Bundle+extension.swift.jinja.include",
            context: ctx,
            templatesPath: templatesPath
        )
        let trimmed = bundleExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        ctx["bundleExtension"] = trimmed.isEmpty ? "" : bundleExtension
        return ctx
    }

    func makeFileContents(for string: String, url: URL) throws -> FileContents {
        guard let fileURL = URL(string: url.lastPathComponent) else {
            fatalError("Invalid file URL: \(url.lastPathComponent)")
        }
        let directoryURL = url.deletingLastPathComponent()

        return FileContents(
            destination: Destination(directory: directoryURL, file: fileURL),
            data: Data(string.utf8)
        )
    }

    func makeFileContents(for string: String, directory: URL, file: URL) throws -> FileContents {
        FileContents(
            destination: Destination(directory: directory, file: file),
            data: Data(string.utf8)
        )
    }
}
