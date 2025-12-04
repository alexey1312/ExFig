@testable import FigmaAPI
import Testing

@Suite("SharedRateLimiter")
struct SharedRateLimiterTests {
    @Test("Initial status has full token bucket")
    func initialStatusHasFullBucket() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 60.0, burstCapacity: 3.0)
        let status = await limiter.status()

        #expect(status.availableTokens >= 2.9)
        #expect(status.maxTokens == 3.0)
        #expect(status.requestsPerMinute == 60.0)
        #expect(status.isPaused == false)
    }

    @Test("Acquire consumes token")
    func acquireConsumesToken() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 60.0, burstCapacity: 3.0)
        let configID = ConfigID("test-config")

        await limiter.acquire(for: configID)
        let status = await limiter.status()

        // Should have consumed one token (allowing some margin for timing)
        #expect(status.availableTokens < 3.0)
        #expect(status.configRequestCounts[configID] == 1)
    }

    @Test("Multiple acquires track request counts per config")
    func multipleAcquiresTrackCounts() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0) // High rate for fast test
        let config1 = ConfigID("config-1")
        let config2 = ConfigID("config-2")

        await limiter.acquire(for: config1)
        await limiter.acquire(for: config1)
        await limiter.acquire(for: config2)

        let status = await limiter.status()

        #expect(status.configRequestCounts[config1] == 2)
        #expect(status.configRequestCounts[config2] == 1)
    }

    @Test("Report rate limit sets pause")
    func reportRateLimitSetsPause() async {
        let limiter = SharedRateLimiter()

        await limiter.reportRateLimit(retryAfter: 5.0)
        let status = await limiter.status()

        #expect(status.isPaused == true)
        #expect(status.retryAfter == 5.0)
    }

    @Test("Clear pause removes pause state")
    func clearPauseRemovesPauseState() async {
        let limiter = SharedRateLimiter()

        await limiter.reportRateLimit(retryAfter: 5.0)
        await limiter.clearPause()
        let status = await limiter.status()

        #expect(status.isPaused == false)
        #expect(status.retryAfter == nil)
    }

    @Test("Reset stats clears all tracking")
    func resetStatsClearsTracking() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let configID = ConfigID("test")

        await limiter.acquire(for: configID)
        await limiter.reportRateLimit(retryAfter: 10.0)
        await limiter.resetAllStats()

        let status = await limiter.status()

        #expect(status.configRequestCounts.isEmpty)
        #expect(status.pendingRequestCount == 0)
        #expect(status.isPaused == false)
    }

    @Test("Reset stats for specific config")
    func resetStatsForSpecificConfig() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let config1 = ConfigID("config-1")
        let config2 = ConfigID("config-2")

        await limiter.acquire(for: config1)
        await limiter.acquire(for: config2)
        await limiter.resetStats(for: config1)

        let status = await limiter.status()

        #expect(status.configRequestCounts[config1] == nil)
        #expect(status.configRequestCounts[config2] == 1)
    }

    @Test("Status description shows rate info")
    func statusDescriptionShowsRateInfo() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 60.0, burstCapacity: 3.0)
        let status = await limiter.status()

        #expect(status.description.contains("60.0 req/min"))
    }

    @Test("Status description shows paused state")
    func statusDescriptionShowsPausedState() async {
        let limiter = SharedRateLimiter()
        await limiter.reportRateLimit(retryAfter: 30.0)
        let status = await limiter.status()

        #expect(status.description.contains("Paused"))
        #expect(status.description.contains("30s"))
    }

    @Test("Current rate is computed correctly")
    func currentRateIsComputedCorrectly() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 60.0)
        let status = await limiter.status()

        #expect(status.currentRate == 1.0) // 60 per minute = 1 per second
    }

    @Test("ConfigID equality")
    func configIDEquality() {
        let id1 = ConfigID("test")
        let id2 = ConfigID("test")
        let id3 = ConfigID("other")

        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("ConfigID hashable")
    func configIDHashable() {
        let id1 = ConfigID("test")
        let id2 = ConfigID("test")

        var set = Set<ConfigID>()
        set.insert(id1)
        set.insert(id2)

        #expect(set.count == 1)
    }
}

// MARK: - Rate Limit Distribution Fairness Tests

@Suite("Rate Limit Distribution Fairness")
struct RateLimitDistributionTests {
    @Test("Requests are distributed across configs")
    func requestsDistributedAcrossConfigs() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 6000.0, burstCapacity: 100.0) // High rate for fast test
        let config1 = ConfigID("config-1")
        let config2 = ConfigID("config-2")
        let config3 = ConfigID("config-3")

        // Simulate multiple requests from each config
        for _ in 0 ..< 10 {
            await limiter.acquire(for: config1)
            await limiter.acquire(for: config2)
            await limiter.acquire(for: config3)
        }

        let status = await limiter.status()

        // Each config should have exactly 10 requests
        #expect(status.configRequestCounts[config1] == 10)
        #expect(status.configRequestCounts[config2] == 10)
        #expect(status.configRequestCounts[config3] == 10)
    }

    @Test("Total request count is accurate")
    func totalRequestCountIsAccurate() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 6000.0, burstCapacity: 50.0)
        let configs = (1 ... 5).map { ConfigID("config-\($0)") }

        // Each config makes 5 requests
        for config in configs {
            for _ in 0 ..< 5 {
                await limiter.acquire(for: config)
            }
        }

        let status = await limiter.status()

        // Total should be 5 configs * 5 requests = 25
        let totalRequests = status.configRequestCounts.values.reduce(0, +)
        #expect(totalRequests == 25)
    }

    @Test("Rate limit fairness with interleaved requests")
    func rateLimitFairnessWithInterleavedRequests() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 6000.0, burstCapacity: 100.0)
        let fastConfig = ConfigID("fast-config")
        let slowConfig = ConfigID("slow-config")

        // Fast config makes many rapid requests
        for _ in 0 ..< 20 {
            await limiter.acquire(for: fastConfig)
        }

        // Slow config makes fewer requests
        for _ in 0 ..< 5 {
            await limiter.acquire(for: slowConfig)
        }

        let status = await limiter.status()

        // Both should have their requests counted accurately
        #expect(status.configRequestCounts[fastConfig] == 20)
        #expect(status.configRequestCounts[slowConfig] == 5)

        // Total should reflect all requests
        let totalRequests = status.configRequestCounts.values.reduce(0, +)
        #expect(totalRequests == 25)
    }

    @Test("Concurrent config requests track correctly")
    func concurrentConfigRequestsTrackCorrectly() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 6000.0, burstCapacity: 100.0)
        let configs = (1 ... 3).map { ConfigID("config-\($0)") }
        let requestsPerConfig = 10

        // Make concurrent requests from multiple configs
        await withTaskGroup(of: Void.self) { group in
            for config in configs {
                for _ in 0 ..< requestsPerConfig {
                    group.addTask {
                        await limiter.acquire(for: config)
                    }
                }
            }
        }

        let status = await limiter.status()

        // Verify each config got correct count despite concurrency
        for config in configs {
            #expect(status.configRequestCounts[config] == requestsPerConfig)
        }

        let totalRequests = status.configRequestCounts.values.reduce(0, +)
        #expect(totalRequests == configs.count * requestsPerConfig)
    }

    @Test("Reset preserves fairness for subsequent batches")
    func resetPreservesFairnessForSubsequentBatches() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 6000.0, burstCapacity: 100.0)
        let config1 = ConfigID("batch1-config")
        let config2 = ConfigID("batch2-config")

        // First batch
        for _ in 0 ..< 10 {
            await limiter.acquire(for: config1)
        }

        // Reset for new batch
        await limiter.resetAllStats()

        // Second batch
        for _ in 0 ..< 5 {
            await limiter.acquire(for: config2)
        }

        let status = await limiter.status()

        // Only second batch should be counted
        #expect(status.configRequestCounts[config1] == nil)
        #expect(status.configRequestCounts[config2] == 5)
        let totalRequests = status.configRequestCounts.values.reduce(0, +)
        #expect(totalRequests == 5)
    }

    @Test("Rate limit pause affects all configs equally")
    func rateLimitPauseAffectsAllConfigsEqually() async {
        let limiter = SharedRateLimiter(requestsPerMinute: 60.0, burstCapacity: 3.0)

        // Report a rate limit
        await limiter.reportRateLimit(retryAfter: 30.0)

        let status = await limiter.status()

        // All configs should see the pause
        #expect(status.isPaused == true)
        #expect(status.retryAfter == 30.0)
    }
}
