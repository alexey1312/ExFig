import Foundation

/// Single source of truth for fault-tolerance and batch defaults.
///
/// These values must be kept in sync with PKL schema defaults in
/// `Sources/ExFigCLI/Resources/Schemas/{Figma,Batch}.pkl`. The
/// `FaultToleranceDefaultsParityTests` test asserts the parity at runtime.
enum FaultToleranceDefaults {
    static let parallel = 3
    static let rateLimit = 10
    static let maxRetries = 4
    static let concurrentDownloads = 20
    static let timeoutSeconds = 30

    static let parallelRange = 1 ... 50
    static let rateLimitRange = 1 ... 600
    static let maxRetriesRange = 0 ... 100
    static let concurrentDownloadsRange = 1 ... 200
    static let timeoutRange = 1 ... 600
}
