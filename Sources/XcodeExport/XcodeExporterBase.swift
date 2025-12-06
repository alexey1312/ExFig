import ExFigCore
import Foundation
import PathKit
import Stencil
import StencilSwiftKit

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

    func makeEnvironment(templatesPath: URL?) -> Environment {
        let loader = if let templateURL = templatesPath {
            FileSystemLoader(paths: [Path(templateURL.path)])
        } else {
            FileSystemLoader(paths: [
                Path((Bundle.module.resourcePath ?? "") + "/Resources"),
                Path(Bundle.module.resourcePath ?? ""),
            ])
        }
        let ext = Extension()
        ext.registerStencilSwiftExtensions()
        return Environment(loader: loader, extensions: [ext])
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
