import Foundation
import Jinja

public final class JinjaTemplateRenderer: @unchecked Sendable {
    private let bundle: Bundle
    /// The default templates path, used when individual loadTemplate() calls don't provide an override.
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
            } catch let error as CocoaError
                where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile
            {
                // File not found at custom path — fall through to bundle
                // (expected for partials like header.jinja or .include files)
                searchedPaths.append(customPath.path)
            } catch {
                // File exists but cannot be read (permission, encoding, I/O) — surface the error
                throw TemplateLoadError.customPathFailed(
                    name: name,
                    path: customPath.path,
                    underlyingError: error
                )
            }
        }
        guard let resourcePath = bundle.resourcePath else {
            throw TemplateLoadError.notFound(
                name: name,
                searchedPaths: searchedPaths + ["(bundle.resourcePath is nil)"]
            )
        }
        let bundleDirs = [resourcePath + "/Resources", resourcePath]
        searchedPaths += bundleDirs
        for dir in bundleDirs {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                // Catch all errors (not just CocoaError) for Linux compatibility —
                // Foundation on Linux may throw non-CocoaError for file-not-found.
                continue
            }
        }
        throw TemplateLoadError.notFound(name: name, searchedPaths: searchedPaths)
    }

    public func renderTemplate(
        source: String,
        context: [String: Any],
        templateName: String? = nil
    ) throws -> String {
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
        do {
            let template = try Template(source)
            return try template.render(jinjaContext)
        } catch let error as TemplateLoadError {
            throw error
        } catch {
            if let name = templateName {
                throw TemplateLoadError.renderFailed(name: name, underlyingError: error)
            }
            throw error
        }
    }

    public func renderTemplate(
        name: String,
        context: [String: Any],
        templatesPath: URL? = nil
    ) throws -> String {
        let templateString = try loadTemplate(named: name, templatesPath: templatesPath)
        do {
            return try renderTemplate(source: templateString, context: context, templateName: name)
        } catch let error as TemplateLoadError {
            throw error
        } catch {
            throw TemplateLoadError.renderFailed(name: name, underlyingError: error)
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
