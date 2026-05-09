import ExFigConfig
import Foundation

/// Caches PKL evaluation results by config URL so the first config (and any subsequent ones
/// pre-checked under `--verbose`) doesn't pay the eval cost twice.
///
/// PKL evaluation spawns a subprocess and is expensive — re-using the parsed module across
/// `BatchSettingsResolver`, `logIgnoredPerTargetSettings`, and `BatchConfigRunner` saves a
/// noticeable chunk of pre-batch latency.
actor PKLModuleCache {
    private var modules: [URL: ExFig.ModuleImpl] = [:]

    init() {}

    func set(_ module: ExFig.ModuleImpl?, for url: URL) {
        guard let module else { return }
        modules[standardize(url)] = module
    }

    func get(for url: URL) -> ExFig.ModuleImpl? {
        modules[standardize(url)]
    }

    private func standardize(_ url: URL) -> URL {
        url.standardizedFileURL
    }
}
