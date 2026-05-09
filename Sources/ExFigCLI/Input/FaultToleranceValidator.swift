import ArgumentParser
import Foundation

/// Centralized validation rules for fault-tolerance and batch knobs.
///
/// These rules are shared between CLI `validate()` (raises `ValidationError`) and
/// PKL `effective*` accessors (clamp + warn). Keeping them in one place removes
/// the drift hazard that comes with three nearly-identical `validate()` blocks.
enum FaultToleranceValidator {
    // MARK: - CLI validation (throws)

    static func validateTimeout(_ value: Int?) throws {
        guard let value else { return }
        guard FaultToleranceDefaults.timeoutRange.contains(value) else {
            throw ValidationError(
                "Timeout must be between \(FaultToleranceDefaults.timeoutRange.lowerBound) " +
                    "and \(FaultToleranceDefaults.timeoutRange.upperBound) seconds"
            )
        }
    }

    static func validateRateLimit(_ value: Int?) throws {
        guard let value else { return }
        guard FaultToleranceDefaults.rateLimitRange.contains(value) else {
            throw ValidationError(
                "Rate limit must be between \(FaultToleranceDefaults.rateLimitRange.lowerBound) " +
                    "and \(FaultToleranceDefaults.rateLimitRange.upperBound) requests per minute"
            )
        }
    }

    static func validateMaxRetries(_ value: Int?) throws {
        guard let value else { return }
        guard FaultToleranceDefaults.maxRetriesRange.contains(value) else {
            throw ValidationError(
                "Max retries must be between \(FaultToleranceDefaults.maxRetriesRange.lowerBound) " +
                    "and \(FaultToleranceDefaults.maxRetriesRange.upperBound)"
            )
        }
    }

    static func validateConcurrentDownloads(_ value: Int?) throws {
        guard let value else { return }
        guard FaultToleranceDefaults.concurrentDownloadsRange.contains(value) else {
            throw ValidationError(
                "Concurrent downloads must be between " +
                    "\(FaultToleranceDefaults.concurrentDownloadsRange.lowerBound) and " +
                    "\(FaultToleranceDefaults.concurrentDownloadsRange.upperBound)"
            )
        }
    }

    static func validateParallel(_ value: Int?) throws {
        guard let value else { return }
        guard FaultToleranceDefaults.parallelRange.contains(value) else {
            throw ValidationError(
                "Parallel must be between \(FaultToleranceDefaults.parallelRange.lowerBound) " +
                    "and \(FaultToleranceDefaults.parallelRange.upperBound)"
            )
        }
    }

    // MARK: - PKL value sanitization (clamp + warn)

    static func sanitizedRateLimit(_ value: Int?, ui: TerminalUI?) -> Int {
        sanitize(
            value: value,
            range: FaultToleranceDefaults.rateLimitRange,
            fallback: FaultToleranceDefaults.rateLimit,
            key: "figma.rateLimit",
            ui: ui
        )
    }

    static func sanitizedMaxRetries(_ value: Int?, ui: TerminalUI?) -> Int {
        sanitize(
            value: value,
            range: FaultToleranceDefaults.maxRetriesRange,
            fallback: FaultToleranceDefaults.maxRetries,
            key: "figma.maxRetries",
            ui: ui
        )
    }

    static func sanitizedConcurrentDownloads(_ value: Int?, ui: TerminalUI?) -> Int {
        sanitize(
            value: value,
            range: FaultToleranceDefaults.concurrentDownloadsRange,
            fallback: FaultToleranceDefaults.concurrentDownloads,
            key: "figma.concurrentDownloads",
            ui: ui
        )
    }

    static func sanitizedTimeout(_ value: Int?, ui: TerminalUI?) -> Int? {
        guard let value else { return nil }
        if FaultToleranceDefaults.timeoutRange.contains(value) {
            return value
        }
        ui?.warning(.invalidConfigValue(
            key: "figma.timeout",
            value: value,
            fallback: FaultToleranceDefaults.timeoutSeconds
        ))
        return FaultToleranceDefaults.timeoutSeconds
    }

    static func sanitizedParallel(_ value: Int?, ui: TerminalUI?) -> Int {
        sanitize(
            value: value,
            range: FaultToleranceDefaults.parallelRange,
            fallback: FaultToleranceDefaults.parallel,
            key: "batch.parallel",
            ui: ui
        )
    }

    // MARK: - Internal

    private static func sanitize(
        value: Int?,
        range: ClosedRange<Int>,
        fallback: Int,
        key: String,
        ui: TerminalUI?
    ) -> Int {
        guard let value else { return fallback }
        if range.contains(value) {
            return value
        }
        ui?.warning(.invalidConfigValue(key: key, value: value, fallback: fallback))
        return fallback
    }
}
