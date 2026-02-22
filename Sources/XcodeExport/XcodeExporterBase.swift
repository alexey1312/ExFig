import ExFigCore
import Foundation
import Jinja

enum TemplateLoadError: Error, LocalizedError {
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case let .notFound(name):
            "Template not found: \(name)"
        }
    }
}

public class XcodeExporterBase {
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
        let templateString = try loadTemplate(named: name, templatesPath: templatesPath)
        let jinjaContext = try context.mapValues { try Value(any: $0) }
        let template = try Template(templateString)
        return try template.render(jinjaContext)
    }

    func loadTemplate(named name: String, templatesPath: URL?) throws -> String {
        if let customPath = templatesPath {
            let url = customPath.appendingPathComponent(name)
            return try String(contentsOf: url, encoding: .utf8)
        }
        let resourcePath = Bundle.module.resourcePath ?? ""
        for dir in [resourcePath + "/Resources", resourcePath] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                return contents
            }
        }
        throw TemplateLoadError.notFound(name)
    }

    func contextWithHeader(
        _ context: [String: Any],
        templatesPath: URL?
    ) throws -> [String: Any] {
        var ctx = context
        ctx["header"] = try loadTemplate(named: "header.jinja", templatesPath: templatesPath)
        return ctx
    }

    func contextWithHeaderAndBundle(
        _ context: [String: Any],
        templatesPath: URL?
    ) throws -> [String: Any] {
        var ctx = try contextWithHeader(context, templatesPath: templatesPath)
        let bundleCtx = context.filter { ["resourceBundleNames"].contains($0.key) }
        let bundleExtension = try renderTemplate(
            name: "Bundle+extension.swift.jinja.include",
            context: bundleCtx,
            templatesPath: templatesPath
        )
        ctx["bundleExtension"] = bundleExtension
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
