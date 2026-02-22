import Foundation
import Jinja

public final class JinjaTemplateRenderer: @unchecked Sendable {
    private let bundle: Bundle
    /// Stored as "default" because individual loadTemplate() calls can override it per-invocation.
    private let defaultTemplatesPath: URL?

    public init(bundle: Bundle, templatesPath: URL? = nil) {
        self.bundle = bundle
        defaultTemplatesPath = templatesPath
    }

    public func loadTemplate(named name: String, templatesPath: URL? = nil) throws -> String {
        let effectivePath = templatesPath ?? defaultTemplatesPath
        var searchedPaths: [String] = []
        if let customPath = effectivePath {
            let url = customPath.appendingPathComponent(name)
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                // Any failure on custom path falls through to bundle (including
                // permission errors, encoding errors, and non-CocoaError types on Linux)
                searchedPaths.append(customPath.path)
            }
        }
        guard let resourcePath = bundle.resourcePath else {
            throw TemplateLoadError.notFound(
                name: name,
                searchedPaths: searchedPaths + ["(Bundle.module.resourcePath is nil)"]
            )
        }
        let bundleDirs = [resourcePath + "/Resources", resourcePath]
        searchedPaths += bundleDirs
        for dir in bundleDirs {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
                continue
            }
        }
        throw TemplateLoadError.notFound(name: name, searchedPaths: searchedPaths)
    }

    public func renderTemplate(source: String, context: [String: Any]) throws -> String {
        var jinjaContext: [String: Value] = [:]
        for (key, value) in context {
            do {
                jinjaContext[key] = try Value(any: value)
            } catch {
                throw TemplateLoadError.contextConversionFailed(
                    key: key,
                    valueType: String(describing: type(of: value)),
                    underlyingError: error
                )
            }
        }
        let template = try Template(source)
        return try template.render(jinjaContext)
    }

    public func renderTemplate(
        name: String,
        context: [String: Any],
        templatesPath: URL? = nil
    ) throws -> String {
        let templateString = try loadTemplate(named: name, templatesPath: templatesPath)
        do {
            return try renderTemplate(source: templateString, context: context)
        } catch let error as TemplateLoadError {
            throw error
        } catch {
            throw TemplateLoadError.renderFailed(templateName: name, underlyingError: error)
        }
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
