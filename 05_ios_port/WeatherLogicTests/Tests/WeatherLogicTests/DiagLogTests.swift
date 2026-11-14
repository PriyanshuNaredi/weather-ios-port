import Foundation
import Testing
@testable import WeatherLogic

// Diagnostics instrumentation tests (runtime-debugging mission, Phase 5).
// DiagLog.swift is copied verbatim into this package by logic-tests.sh, so
// these verify the exact ring-buffer logic the device build uses: bounded
// capacity, oldest-first drop counting, ordered snapshots, clear, and the
// export format. (footprintMB is Darwin-gated and returns nil on Linux —
// intentionally not asserted here.)

struct DiagLogTests {
    private func filled(_ n: Int) -> DiagLog {
        let log = DiagLog()
        for i in 0..<n { log.record("event-\(i)") }
        return log
    }

    @Test func belowCapacityKeepsEverything() {
        let (entries, dropped) = filled(10).snapshot()
        #expect(entries.count == 10)
        #expect(dropped == 0)
        #expect(entries.first?.message == "event-0")
        #expect(entries.last?.message == "event-9")
    }

    @Test func atCapacityDropsOldestAndCountsThem() {
        let (entries, dropped) = filled(DiagLog.capacity + 7).snapshot()
        #expect(entries.count == DiagLog.capacity)
        #expect(dropped == 7)
        // Newest entries survive; the oldest are the ones dropped.
        #expect(entries.last?.message == "event-\(DiagLog.capacity + 6)")
    }

    @Test func clearEmptiesBufferAndResetsDropCount() {
        let log = filled(DiagLog.capacity + 3)
        log.clear()
        let (entries, dropped) = log.snapshot()
        #expect(entries.isEmpty)
        #expect(dropped == 0)   // clear resets the counter (Diagnostics "Clear" button semantics)
    }

    @Test func exportTextReportsCountsAndMessages() {
        let log = DiagLog()
        log.record("nav screen -> map")
        let text = log.exportTextLog()
        #expect(text.contains("1 events"))
        #expect(text.contains("nav screen -> map"))
    }

    @Test func exportTextMentionsDroppedEvents() {
        let log = filled(DiagLog.capacity + 5)
        let text = log.exportTextLog()
        #expect(text.contains("5 older dropped"))
    }

    @Test func timestampsAreMonotonicNonDecreasing() {
        let log = filled(50)
        let (entries, _) = log.snapshot()
        let stamps = entries.map { $0.seconds }
        #expect(zip(stamps, stamps.dropFirst()).allSatisfy { $0 <= $1 })
    }
}
