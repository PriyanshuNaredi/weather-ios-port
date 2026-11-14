import XCTest
@testable import WeatherLogic

// Stability-fix tests (crash/navigation/scroll mission, Phase 6). Covers the
// pure logic extracted from the fixes: pager index clamping, temperature
// range-band geometry, task-cancellation loop exits, and the DiagLog session
// clean/abnormal-end protocol that backs the crash-evidence channel.
// These are HOST-side logic tests — not touchscreen/device tests.

final class PagerIndexTests: XCTestCase {

    func testClampInsideRange() {
        XCTAssertEqual(PagerIndexPolicy.clamp(1, count: 3), 1)
    }

    func testClampAboveRangeAfterCityRemoval() {
        // Stale scrollPosition binding firing index 3 when only 2 cities remain.
        XCTAssertEqual(PagerIndexPolicy.clamp(3, count: 2), 1)
    }

    func testClampNegative() {
        XCTAssertEqual(PagerIndexPolicy.clamp(-1, count: 5), 0)
    }

    func testClampWithNoCities() {
        XCTAssertEqual(PagerIndexPolicy.clamp(0, count: 0), 0)
        XCTAssertEqual(PagerIndexPolicy.clamp(7, count: 0), 0)
    }
}

final class RangeSpanTests: XCTestCase {

    func testNilEndpointsReturnNil() {
        XCTAssertNil(RangeSpan.band(low: nil, high: 5, min: 0, max: 10))
        XCTAssertNil(RangeSpan.band(low: 1, high: nil, min: 0, max: 10))
    }

    func testBandOrderingWithinRange() {
        let band = RangeSpan.band(low: 4, high: 8, min: 0, max: 10)!
        XCTAssertEqual(band.left, 0.4, accuracy: 1e-9)
        XCTAssertEqual(band.right, 0.8, accuracy: 1e-9)
        XCTAssertLessThan(band.left, band.right)
    }

    func testBandNeverThinnerThanMinimumFraction() {
        // low == high → degenerate band must still be >= minBandFraction wide.
        let band = RangeSpan.band(low: 5, high: 5, min: 0, max: 10)!
        XCTAssertGreaterThanOrEqual(band.right - band.left, RangeSpan.minBandFraction)
    }

    func testDegenerateGlobalRangeFallsBack() {
        // All lows/highs identical → max - min == 0 → range falls back to 1.0.
        let band = RangeSpan.band(low: 3, high: 3, min: 3, max: 3)!
        XCTAssertEqual(band.left, 0.0, accuracy: 1e-9)
        XCTAssertEqual(band.right, RangeSpan.minBandFraction, accuracy: 1e-9)
    }
}

final class CancellationLoopTests: XCTestCase {

    /// The fixed timer-loop pattern (`while !Task.isCancelled` + do/catch
    /// sleep) must exit promptly when the surrounding task is cancelled —
    /// the bug class behind the leaked 15-minute per-page retry loops.
    func testTimerLoopExitsOnCancellation() async {
        actor Counter { var n = 0; func bump() { n += 1 }; func value() -> Int { n } }
        let counter = Counter()

        let task = Task {
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 50_000_000) }
                catch { break }   // cancelled with the view
                await counter.bump()
            }
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()
        try? await Task.sleep(nanoseconds: 200_000_000)   // let the loop exit
        let bumpsAfterCancel = await counter.value()
        // A cancelled loop must stop ticking: wait another interval and confirm
        // the counter no longer increases.
        try? await Task.sleep(nanoseconds: 300_000_000)
        let bumpsLater = await counter.value()
        XCTAssertEqual(bumpsAfterCancel, bumpsLater,
                       "timer loop must stop ticking after cancellation")
        XCTAssertLessThan(bumpsLater, 60, "loop ticked far longer than the observed window")
    }
}

final class DiagSessionCleanTests: XCTestCase {

    /// markSessionClean appends the marker; a session file carrying the
    /// marker is NOT reported as an abnormal previous session. Exercises the
    /// disk protocol with an injected directory (temp scratch, never the app).
    func testCleanSessionIsNotReportedAbnormal() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("diagtest-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        // Session 1: record something, then end cleanly.
        let first = DiagLog(directory: dir)
        first.record("alpha event")
        first.markSessionClean()
        // Session 2: begins after session 1's clean end.
        let second = DiagLog(directory: dir)
        XCTAssertNil(second.previousSessionTextLog(),
                     "a cleanly-ended session must not be reported as abnormal")
    }

    /// A session that ends WITHOUT the marker (crash/watchdog/jetsam) IS
    /// reported by the next session — the crash-evidence channel.
    func testAbnormalSessionIsReported() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("diagtest-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let first = DiagLog(directory: dir)
        first.record("event before termination")
        // No markSessionClean — simulates termination.
        let second = DiagLog(directory: dir)
        let report = second.previousSessionTextLog()
        XCTAssertNotNil(report)
        XCTAssertTrue(report?.contains("event before termination") ?? false)
    }
}

// Watchdog-fix tests (2026-11-14): the WeatherMapView tile-fetch task group's
// priming loop previously spun forever on the main actor when fewer pending
// tiles existed than maxConcurrentTileFetches (addNext() no-opped on iterator
// exhaustion while the loop waited for the concurrency ceiling) — freezing the
// UI until the OS watchdog killed the app. These tests pin the scheduler
// semantics via the pure TileCachePolicy.simulateTileScheduler reference,
// which mirrors the view's fixed loop (exhaustion flag + concurrency limit).
final class TileSchedulerTests: XCTestCase {

    let limit = TileCachePolicy.maxConcurrentTileFetches

    func testZeroPendingTilesSchedulesAndDrainsNothing() {
        let sim = TileCachePolicy.simulateTileScheduler(pendingCount: 0, limit: limit)
        XCTAssertEqual(sim.primed, 0)
        XCTAssertEqual(sim.completed, 0)
    }

    func testOnePendingTile() {
        let sim = TileCachePolicy.simulateTileScheduler(pendingCount: 1, limit: limit)
        XCTAssertEqual(sim.primed, 1)
        XCTAssertEqual(sim.completed, 1)
    }

    func testSevenPendingTiles() {
        let sim = TileCachePolicy.simulateTileScheduler(pendingCount: 7, limit: limit)
        XCTAssertEqual(sim.primed, 7)
        XCTAssertEqual(sim.completed, 7)
    }

    func testExactlyEightPendingTilesFillsTheCeiling() {
        XCTAssertEqual(limit, 8, "the Android-parity concurrency cap")
        let sim = TileCachePolicy.simulateTileScheduler(pendingCount: limit, limit: limit)
        XCTAssertEqual(sim.primed, 8)
        XCTAssertEqual(sim.completed, 8)
    }

    func testMoreThanEightPendingTilesKeepsTheCeilingAndDrainsAll() {
        let sim = TileCachePolicy.simulateTileScheduler(pendingCount: 25, limit: limit)
        XCTAssertEqual(sim.primed, 8, "priming wave must stop at the concurrency limit")
        XCTAssertEqual(sim.completed, 25, "all scheduled tasks must drain")
    }

    func testIteratorExhaustionTerminatesThePrimingLoop() {
        // For every pending count, the priming loop must terminate in bounded
        // iterations (the old loop spun forever whenever pending < limit) and
        // never exceed the concurrency limit.
        for pending in 0...40 {
            let sim = TileCachePolicy.simulateTileScheduler(pendingCount: pending, limit: limit)
            XCTAssertLessThanOrEqual(sim.primed, limit)
            XCTAssertLessThanOrEqual(sim.primingIterations, pending + 1,
                                     "priming loop must stop at iterator exhaustion")
            if pending < limit {
                XCTAssertEqual(sim.primed, pending,
                               "all pending tiles must be scheduled despite exhaustion")
            }
        }
    }

    func testAllScheduledTasksDrainForEveryCount() {
        for pending in 0...40 {
            let sim = TileCachePolicy.simulateTileScheduler(pendingCount: pending, limit: limit)
            XCTAssertEqual(sim.completed, pending,
                           "scheduler must drain exactly the pending tiles")
        }
    }
}
