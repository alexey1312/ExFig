import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Checks that variable collections used in config don't contain deleted-but-referenced variables.
struct DeletedVariablesRule: LintRule {
    let id = "deleted-variables"
    let name = "No deleted variables"
    let description = "Variable collections must not contain deletedButReferenced variables"
    let severity: LintSeverity = .warning

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        var diagnostics: [LintDiagnostic] = []

        let fileIds = collectVariableFileIds(from: config)
        guard !fileIds.isEmpty else { return [] }

        for fileId in fileIds {
            guard !fileId.isEmpty else { continue }

            let variables: VariablesMeta
            do {
                variables = try await context.cache.variables(for: fileId, client: context.client)
            } catch {
                continue
            }

            for (variableId, variable) in variables.variables
                where variable.deletedButReferenced == true
            {
                diagnostics.append(LintDiagnostic(
                    ruleId: id,
                    ruleName: name,
                    severity: .warning,
                    message: "Variable '\(variable.name)' is deleted but still referenced",
                    componentName: variable.name,
                    nodeId: variableId,
                    suggestion: "Remove all references to this variable, or restore it"
                ))
            }
        }

        return diagnostics
    }

    private func collectVariableFileIds(from config: ExFig.ModuleImpl) -> Set<String> {
        var fileIds: Set<String> = []
        let defaultFileId = config.figma?.lightFileId ?? ""

        // Colors with variablesColors (on common config, not common.colors)
        if config.common?.variablesColors != nil {
            fileIds.insert(defaultFileId)
        }

        /// Icons with variablesDarkMode
        func addFromIcons(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                if let vdm = entry.variablesDarkMode {
                    fileIds.insert(entry.figmaFileId ?? defaultFileId)
                    if let libFileId = vdm.variablesFileId, !libFileId.isEmpty {
                        fileIds.insert(libFileId)
                    }
                }
            }
        }

        if let ios = config.ios { addFromIcons(ios.icons) }
        if let android = config.android { addFromIcons(android.icons) }
        if let flutter = config.flutter { addFromIcons(flutter.icons) }
        if let web = config.web { addFromIcons(web.icons) }

        return fileIds
    }
}
