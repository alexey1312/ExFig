import ExFigCore
import Foundation
import JinjaSupport

public class FlutterExporter {
    let renderer: JinjaTemplateRenderer

    init(templatesPath: URL?) {
        renderer = JinjaTemplateRenderer(bundle: Bundle.module, templatesPath: templatesPath)
    }

    func renderTemplate(name: String, context: [String: Any]) throws -> String {
        try renderer.renderTemplate(name: name, context: context)
    }

    func renderTemplate(source: String, context: [String: Any]) throws -> String {
        try renderer.renderTemplate(source: source, context: context)
    }

    func loadTemplate(named name: String) throws -> String {
        try renderer.loadTemplate(named: name)
    }

    func contextWithHeader(_ context: [String: Any]) throws -> [String: Any] {
        try renderer.contextWithHeader(context)
    }

    func makeFileContents(for string: String, directory: URL, file: URL) throws -> FileContents {
        FileContents(
            destination: Destination(directory: directory, file: file),
            data: Data(string.utf8)
        )
    }
}
