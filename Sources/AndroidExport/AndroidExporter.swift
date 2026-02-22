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

public class AndroidExporter {
    private let templatesPath: URL?

    init(templatesPath: URL?) {
        self.templatesPath = templatesPath
    }

    func renderTemplate(name: String, context: [String: Any]) throws -> String {
        let templateString = try loadTemplate(named: name)
        return try renderTemplate(source: templateString, context: context)
    }

    func renderTemplate(source: String, context: [String: Any]) throws -> String {
        let jinjaContext = try context.mapValues { try Value(any: $0) }
        let template = try Template(source)
        return try template.render(jinjaContext)
    }

    func loadTemplate(named name: String) throws -> String {
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

    func contextWithHeader(_ context: [String: Any]) throws -> [String: Any] {
        var ctx = context
        ctx["header"] = try loadTemplate(named: "header.jinja")
        return ctx
    }

    func makeFileContents(for string: String, directory: URL, file: URL) throws -> FileContents {
        FileContents(
            destination: Destination(directory: directory, file: file),
            data: Data(string.utf8)
        )
    }
}
