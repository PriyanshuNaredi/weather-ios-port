import Foundation

// Pure-logic policy for the custom Web-Mercator tile renderer's cache
// (stability fix for the memory-pressure crash). Kept Foundation-only so the
// Linux logic tests can verify eviction / dedupe / failure-throttling exactly.
// The TileLayer view consults this before every fetch and after every load.

enum TileCachePolicy {
    /// Bounded cache: at most 96 decoded tiles per layer
    /// (96 × 256×256×4 B ≈ 25 MB worst case — explicit memory ceiling).
    static let maxTiles = 96
    /// A tile that failed to download is not retried for this long, so an
    /// offline period can't turn into an unbounded fetch storm.
    static let failureRetryDelay: TimeInterval = 30
    /// Concurrent tile downloads cap.
    static let maxConcurrentTileFetches = 8
    /// Overall cache ceiling for the map screen (all layers combined),
    /// matched by the previous eviction guard.
    static let maxTotalTiles = 256

    // Disk cache budget — parity with the Android map HTTP cache (Maps.kt:81):
    // a bounded 48 MiB disk cache at `cacheDir/map-http` that survives restart.
    // Bounded in bytes, not tile count, because encoded tile sizes vary by zoom.
    static let maxDiskBytes = 48 * 1024 * 1024

    /// Disk eviction (parity: Android FileLruCache LRU-by-last-use under a byte
    /// budget). Pure and testable. Entries are (key, size, stamp) with `stamp`
    /// a monotonically increasing last-use counter; returns the keys to delete —
    /// oldest stamp first until the total fits `budgetBytes`. Keys in
    /// `protected` (just-written / on-screen tiles) are never evicted, matching
    /// Android's never-evict-what-you-just-stored behavior. A single oversized
    /// unprotected entry is evictable so the cache self-heals rather than
    /// pinning one big file forever.
    static func evictDisk(
        entries: [(key: String, size: Int, stamp: UInt64)],
        protected: Set<String>,
        budgetBytes: Int) -> [String] {
        let total = entries.reduce(0) { $0 + $1.size }
        guard total > budgetBytes else { return [] }
        var over = total - budgetBytes
        var evicted: [String] = []
        for entry in entries.sorted(by: { $0.stamp < $1.stamp })
        where !protected.contains(entry.key) && over > 0 {
            over -= entry.size
            evicted.append(entry.key)
        }
        return evicted
    }

    /// LRU eviction: keep the current viewport's tiles plus the most recently
    /// used others up to `limit`; return the keys to drop.
    /// `lastUse` maps key → monotonically increasing use counter.
    static func evict(entries: [String: UInt64], currentKeys: Set<String>, limit: Int) -> [String] {
        guard entries.count > limit else { return [] }
        let over = entries.count - limit
        // Never evict what's on screen; among the rest, drop the least
        // recently used first.
        let candidates = entries
            .filter { !currentKeys.contains($0.key) }
            .sorted { $0.value < $1.value }
        if candidates.count <= over { return candidates.map(\.key) }
        return Array(candidates.prefix(over)).map(\.key)
    }

    /// Should this tile be fetched now? Guards against duplicate in-flight
    /// requests and hammers on persistently failing URLs.
    static func shouldFetch(key: String, cached: Bool, inFlight: Bool,
                            lastFailure: Date?, now: Date) -> Bool {
        if cached || inFlight { return false }
        if let lastFailure, now.timeIntervalSince(lastFailure) < failureRetryDelay {
            return false
        }
        return true
    }

    /// Reference simulation of the WeatherMapView tile-fetch task-group
    /// scheduler, pure so the Linux tests can pin priming, iterator
    /// exhaustion (termination) and complete draining without SwiftUI.
    /// Mirrors the view exactly: prime until the iterator is exhausted or
    /// `limit` fetches are in flight, then each completion schedules the
    /// next pending tile until all are done. Returns (tiles started in the
    /// priming wave, iterations of the priming loop, tiles completed).
    static func simulateTileScheduler(pendingCount: Int, limit: Int) ->
        (primed: Int, primingIterations: Int, completed: Int) {
        var scheduled = 0
        var exhausted = pendingCount <= 0
        var primingIterations = 0
        while !exhausted && scheduled < limit {
            primingIterations += 1
            if scheduled < pendingCount {
                scheduled += 1
            } else {
                exhausted = true
            }
        }
        // Drain: every completion either schedules the next pending tile or
        // reduces the in-flight count; bounded by pendingCount total work.
        var completed = 0
        var inFlight = scheduled
        var remaining = pendingCount - scheduled
        while inFlight > 0 {
            completed += 1
            inFlight -= 1
            if remaining > 0 {
                inFlight += 1
                remaining -= 1
            }
        }
        return (scheduled, primingIterations, completed)
    }
}
