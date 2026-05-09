import ArgumentParser
import Foundation

/// Centralized validation rules for fault-tolerance and batch knobs.
///
/// These rules are shared between CLI `validate()` (raises `ValidationError`) and
/// the CLI-side `effective*` accessors on `FaultToleranceOptions` /
/// `HeavyFaultToleranceOptions` (clamp + warn when reading PKL config values).
/// Keeping them in one place removes the drift hazard that comes with several
/// nearly-identical `validate()` blocks.
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

    /// Sanitize a PKL `figma.timeout`. Unlike the other knobs, `nil` means "no value
    /// configured" and is preserved (downstream uses `FigmaClient`'s default).
    /// Out-of-range values fall back to `FaultToleranceDefaults.timeoutSeconds` and emit
    /// `.invalidConfigValue` at most once per (key, value) pair (deduped via `warnOnce`).
    static func sanitizedTimeout(_ value: Int?, ui: TerminalUI?) -> Int? {
        guard let value else { return nil }
        if FaultToleranceDefaults.timeoutRange.contains(value) {
            return value
        }
        warnOnce(
            key: "figma.timeout",
            value: value,
            fallback: FaultToleranceDefaults.timeoutSeconds,
            ui: ui
        )
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

    /// Tracks `(key, value)` pairs we've already warned about so the same out-of-range PKL
    /// value doesn't dilute the log when sanitize() is called from many sites in one run.
    private static let warnedKeys = Lock<Set<String>>([])

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
        warnOnce(key: key, value: value, fallback: fallback, ui: ui)
        return fallback
    }

    /// Emits `.invalidConfigValue` at most once per `(key, value)` pair within this process.
    /// Test-only `resetWarnedKeys()` clears the dedup cache between scenarios.
    static func warnOnce(key: String, value: Int, fallback: Int, ui: TerminalUI?) {
        let dedupKey = "\(key)=\(value)"
        let shouldEmit = warnedKeys.withLock { keys -> Bool in
            keys.insert(dedupKey).inserted
        }
        guard shouldEmit else { return }
        ui?.warning(.invalidConfigValue(key: key, value: value, fallback: fallback))
    }

    /// Test hook: clears the per-process warning dedup cache.
    static func resetWarnedKeys() {
        warnedKeys.withLock { $0.removeAll() }
    }
}
