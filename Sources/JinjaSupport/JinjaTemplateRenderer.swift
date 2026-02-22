import Foundation
import Jinja

public final class JinjaTemplateRenderer {
    private let bundle: Bundle
    private let defaultTemplatesPath: URL?

    public init(bundle: Bundle, templatesPath: URL? = nil) {
        self.bundle = bundle
        defaultTemplatesPath = templatesPath
    }

    public func loadTemplate(named name: String, templatesPath: URL? = nil) throws -> String {
        let effectivePath = templatesPath ?? defaultTemplatesPath
        if let customPath = effectivePath {
            let url = customPath.appendingPathComponent(name)
            return try String(contentsOf: url, encoding: .utf8)
        }
        let resourcePath = bundle.resourcePath ?? ""
        for dir in [resourcePath + "/Resources", resourcePath] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                return contents
            }
        }
        throw TemplateLoadError.notFound(name)
    }

    public func renderTemplate(source: String, context: [String: Any]) throws -> String {
        let jinjaContext = try context.mapValues { try Value(any: $0) }
        let template = try Template(source)
        return try template.render(jinjaContext)
    }

    public func renderTemplate(
        name: String,
        context: [String: Any],
        templatesPath: URL? = nil
    ) throws -> String {
        let templateString = try loadTemplate(named: name, templatesPath: templatesPath)
        return try renderTemplate(source: templateString, context: context)
    }

    public func contextWithHeader(
        _ context: [String: Any],
        templatesPath: URL? = nil
    ) throws -> [String: Any] {
        var ctx = context
        ctx["header"] = try loadTemplate(named: "header.jinja", templatesPath: templatesPath)
        return ctx
    }
}
