import ExFigCore
import Foundation
import Stencil

public final class XcodeTypographyExporter: XcodeExporterBase {
    private let output: XcodeTypographyOutput

    public init(output: XcodeTypographyOutput) {
        self.output = output
    }

    public func export(textStyles: [TextStyle]) throws -> [FileContents] {
        var files: [FileContents] = []

        // UIKit UIFont extension
        if let url = output.urls.fonts.fontExtensionURL {
            try files.append(makeUIFontExtension(textStyles: textStyles, fontExtensionURL: url))
        }

        // SwiftUI Font extension
        if let url = output.urls.fonts.swiftUIFontExtensionURL {
            try files.append(makeFontExtension(textStyles: textStyles, swiftUIFontExtensionURL: url))
        }

        // UIKit Labels
        if output.generateLabels, let labelsDirectory = output.urls.labels.labelsDirectory {
            // Label.swift
            try files.append(makeLabel(
                textStyles: textStyles,
                labelsDirectory: labelsDirectory,
                separateStyles: output.urls.labels.labelStyleExtensionsURL != nil
            ))

            // LabelStyle.swift
            try files.append(makeLabelStyle(labelsDirectory: labelsDirectory))

            // LabelStyle extensions
            if let url = output.urls.labels.labelStyleExtensionsURL {
                try files.append(makeLabelStyleExtensionFileContents(
                    textStyles: textStyles,
                    labelStyleExtensionURL: url
                ))
            }
        }

        return files
    }

    private func makeUIFontExtension(textStyles: [TextStyle], fontExtensionURL: URL) throws -> FileContents {
        let textStyles: [[String: Any]] = textStyles.map {
            [
                "name": $0.name,
                "fontName": $0.fontName,
                "fontSize": $0.fontSize,
                "supportsDynamicType": $0.fontStyle != nil,
                "type": $0.fontStyle?.uiKitStyleName ?? "",
            ]
        }
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let contents = try env.renderTemplate(name: "UIFont+extension.swift.stencil", context: [
            "textStyles": textStyles,
            "addObjcPrefix": output.addObjcAttribute,
        ])
        return try makeFileContents(for: contents, url: fontExtensionURL)
    }

    private func makeFontExtension(textStyles: [TextStyle], swiftUIFontExtensionURL: URL) throws -> FileContents {
        let textStyles: [[String: Any]] = textStyles.map {
            [
                "name": $0.name,
                "fontName": $0.fontName,
                "fontSize": $0.fontSize,
                "supportsDynamicType": $0.fontStyle != nil,
                "type": $0.fontStyle?.swiftUIStyleName ?? "",
            ]
        }
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let contents = try env.renderTemplate(name: "Font+extension.swift.stencil", context: [
            "textStyles": textStyles,
        ])
        return try makeFileContents(for: contents, url: swiftUIFontExtensionURL)
    }

    private func makeLabelStyleExtensionFileContents(
        textStyles: [TextStyle],
        labelStyleExtensionURL: URL
    ) throws -> FileContents {
        let dict = textStyles.map { style -> [String: Any] in
            let type: String = style.fontStyle?.uiKitStyleName ?? ""
            return [
                "className": (style.name.first?.uppercased() ?? "") + style.name.dropFirst(),
                "varName": style.name,
                "size": style.fontSize,
                "supportsDynamicType": style.fontStyle != nil,
                "type": type,
                "tracking": style.letterSpacing.floatingPointFixed,
                "lineHeight": style.lineHeight ?? 0,
                "textCase": style.textCase.rawValue,
            ]
        }
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let contents = try env.renderTemplate(name: "LabelStyle+extension.swift.stencil", context: ["styles": dict])

        let labelStylesSwiftExtension = try makeFileContents(for: contents, url: labelStyleExtensionURL)
        return labelStylesSwiftExtension
    }

    private func makeLabel(textStyles: [TextStyle], labelsDirectory: URL, separateStyles: Bool) throws -> FileContents {
        let dict = textStyles.map { style -> [String: Any] in
            let type: String = style.fontStyle?.uiKitStyleName ?? ""
            return [
                "className": (style.name.first?.uppercased() ?? "") + style.name.dropFirst(),
                "varName": style.name,
                "size": style.fontSize,
                "supportsDynamicType": style.fontStyle != nil,
                "type": type,
                "tracking": style.letterSpacing.floatingPointFixed,
                "lineHeight": style.lineHeight ?? 0,
                "textCase": style.textCase.rawValue,
            ]
        }
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let contents = try env.renderTemplate(name: "Label.swift.stencil", context: [
            "styles": dict,
            "separateStyles": separateStyles,
        ])
        // swiftlint:disable:next force_unwrapping
        return try makeFileContents(for: contents, directory: labelsDirectory, file: URL(string: "Label.swift")!)
    }

    private func makeLabelStyle(labelsDirectory: URL) throws -> FileContents {
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let labelStyleSwiftContents = try env.renderTemplate(name: "LabelStyle.swift.stencil")
        return try makeFileContents(
            for: labelStyleSwiftContents,
            directory: labelsDirectory,
            // swiftlint:disable:next force_unwrapping
            file: URL(string: "LabelStyle.swift")!
        )
    }
}
