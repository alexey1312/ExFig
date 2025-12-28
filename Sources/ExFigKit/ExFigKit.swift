/// ExFigKit - Reusable library for ExFig CLI and GUI applications.
///
/// This module contains:
/// - Configuration parsing (Params)
/// - Progress reporting protocol (ProgressReporter)
/// - Error types (ExFigError)
///
/// ## Usage
///
/// ```swift
/// import ExFigKit
///
/// // Load configuration
/// let params = try Params.load(from: configURL)
///
/// // Create progress reporter
/// let reporter = MyProgressReporter()
/// await reporter.beginPhase("Loading colors")
/// ```
public enum ExFigKit {
    public static let version = "1.0.0"
}
