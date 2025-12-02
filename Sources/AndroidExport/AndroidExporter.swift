import ExFigCore
import Foundation
import PathKit
import Stencil
import StencilSwiftKit

public class AndroidExporter {
    private let templatesPath: URL?

    init(templatesPath: URL?) {
        self.templatesPath = templatesPath
    }

    func makeEnvironment() -> Environment {
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

    func makeFileContents(for string: String, directory: URL, file: URL) throws -> FileContents {
        FileContents(
            destination: Destination(directory: directory, file: file),
            data: Data(string.utf8)
        )
    }
}
