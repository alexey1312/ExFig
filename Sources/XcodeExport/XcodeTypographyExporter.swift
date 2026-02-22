import ExFigCore
import Foundation

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
        let textStyles: [[String: Any]] = textStyles.sorted { $0.name < $1.name }.map {
            [
                "name": $0.name,
                "fontName": $0.fontName,
                "fontSize": $0.fontSize,
                "supportsDynamicType": $0.fontStyle != nil,
                "type": $0.fontStyle?.uiKitStyleName ?? "",
            ]
        }
        let context: [String: Any] = [
            "textStyles": textStyles,
            "addObjcPrefix": output.addObjcAttribute,
        ]
        let fullContext = try contextWithHeader(context, templatesPath: output.templatesPath)
        let contents = try renderTemplate(
            name: "UIFont+extension.swift.jinja",
            context: fullContext,
            templatesPath: output.templatesPath
        )
        return try makeFileContents(for: contents, url: fontExtensionURL)
    }

    private func makeFontExtension(textStyles: [TextStyle], swiftUIFontExtensionURL: URL) throws -> FileContents {
        let textStyles: [[String: Any]] = textStyles.sorted { $0.name < $1.name }.map {
            [
                "name": $0.name,
                "fontName": $0.fontName,
                "fontSize": $0.fontSize,
                "supportsDynamicType": $0.fontStyle != nil,
                "type": $0.fontStyle?.swiftUIStyleName ?? "",
            ]
        }
        let context: [String: Any] = [
            "textStyles": textStyles,
        ]
        let fullContext = try contextWithHeader(context, templatesPath: output.templatesPath)
        let contents = try renderTemplate(
            name: "Font+extension.swift.jinja",
            context: fullContext,
            templatesPath: output.templatesPath
        )
        return try makeFileContents(for: contents, url: swiftUIFontExtensionURL)
    }

    private func makeLabelStyleExtensionFileContents(
        textStyles: [TextStyle],
        labelStyleExtensionURL: URL
    ) throws -> FileContents {
        let dict = textStyles.sorted { $0.name < $1.name }.map { style -> [String: Any] in
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
        let context: [String: Any] = ["styles": dict]
        let fullContext = try contextWithHeader(context, templatesPath: output.templatesPath)
        let contents = try renderTemplate(
            name: "LabelStyle+extension.swift.jinja",
            context: fullContext,
            templatesPath: output.templatesPath
        )

        return try makeFileContents(for: contents, url: labelStyleExtensionURL)
    }

    private func makeLabel(textStyles: [TextStyle], labelsDirectory: URL, separateStyles: Bool) throws -> FileContents {
        let dict = textStyles.sorted { $0.name < $1.name }.map { style -> [String: Any] in
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
        let context: [String: Any] = [
            "styles": dict,
            "separateStyles": separateStyles,
        ]
        let fullContext = try contextWithHeader(context, templatesPath: output.templatesPath)
        let contents = try renderTemplate(
            name: "Label.swift.jinja",
            context: fullContext,
            templatesPath: output.templatesPath
        )
        // swiftlint:disable:next force_unwrapping
        return try makeFileContents(for: contents, directory: labelsDirectory, file: URL(string: "Label.swift")!)
    }

    private func makeLabelStyle(labelsDirectory: URL) throws -> FileContents {
        let fullContext = try contextWithHeader([:], templatesPath: output.templatesPath)
        let labelStyleSwiftContents = try renderTemplate(
            name: "LabelStyle.swift.jinja",
            context: fullContext,
            templatesPath: output.templatesPath
        )
        return try makeFileContents(
            for: labelStyleSwiftContents,
            directory: labelsDirectory,
            // swiftlint:disable:next force_unwrapping
            file: URL(string: "LabelStyle.swift")!
        )
    }
}
