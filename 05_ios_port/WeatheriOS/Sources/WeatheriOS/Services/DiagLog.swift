import Foundation

// On-device diagnostic ring buffer (runtime-debugging mission, Phase 1;
// crash/navigation/scroll mission extended it with disk persistence).
// os.Logger output is invisible without Console.app / a Mac, so the debug
// build also records every Diag.event in a bounded in-memory ring that the
// in-app Diagnostics screen displays and exports (copy / share).
//
// Disk persistence (new): when the app is terminated by a watchdog or jetsam,
// the in-app export is unreachable — the UI hangs or the process is gone. Every
// event is therefore ALSO appended to a per-session file in
// Application Support/weather-diag/. On the next launch the Diagnostics screen
// shows the previous session's log if that session ended without a clean-exit
// marker. Files: session-<unixtime>.log, at most `maxSessionFiles` kept.
//
// PRIVACY: callers must scrub messages of coordinates and city names before
// calling Diag.event (enforced by convention in Diagnostics.swift) — neither
// buffer nor disk file ever contains user location content.

final class DiagLog: @unchecked Sendable {
    static let shared = DiagLog()
    static let capacity = 600
    /// Bounded on-disk history: current session + 2 previous sessions.
    static let maxSessionFiles = 3

    struct Entry {
        let seconds: Double   // timeIntervalSinceReferenceDate
        let message: String
    }

    private let lock = NSLock()
    private var entries: [Entry] = []
    private var dropped = 0

    // Disk persistence state (all guarded by `lock`).
    private let directory: URL?
    private var sessionFile: URL?
    private var pendingDiskWrites: [String] = []

    /// Internal so the logic-test package can exercise an isolated instance;
    /// production code uses `shared` (injectable directory for disk tests).
    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } else {
            #if canImport(Darwin)
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let dir = base?.appendingPathComponent("weather-diag")
            if let dir { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
            self.directory = dir
            #else
            // Linux logic tests: no disk persistence unless a directory is injected.
            self.directory = nil
            #endif
        }
        beginSessionFile()
    }

    func record(_ message: String) {
        let entry = Entry(seconds: Date.timeIntervalSinceReferenceDate, message: message)
        lock.lock()
        if entries.count >= Self.capacity {
            entries.removeFirst(entries.count - Self.capacity + 1)
            dropped += 1
        }
        entries.append(entry)
        if sessionFile != nil { pendingDiskWrites.append(entry.diskLine) }
        lock.unlock()
        flushDisk()
    }

    /// Newest last. Safe snapshot for rendering / export.
    func snapshot() -> (entries: [Entry], dropped: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (entries, dropped)
    }

    func clear() {
        lock.lock()
        entries = []
        dropped = 0
        lock.unlock()
    }

    // MARK: - Session files

    /// Called at app start. Rotates old session files (keeps the newest
    /// `maxSessionFiles - 1` PREVIOUS sessions plus the new one) and reports
    /// the previous session's text when that session ended abnormally.
    @discardableResult
    private func beginSessionFile() -> String? {
        guard let directory else { return nil }
        lock.lock()
        defer { lock.unlock() }
        // Drain any pending writes SYNCHRONOUSLY first — the previous session's
        // last events may still be sitting in pendingDiskWrites when the app is
        // relaunched right after a termination (the exact crash-evidence case).
        if let file = sessionFile, !pendingDiskWrites.isEmpty {
            if let handle = try? FileHandle(forWritingTo: file) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                let data = Data(pendingDiskWrites.joined(separator: "\n").appending("\n").utf8)
                try? handle.write(contentsOf: data)
            }
            pendingDiskWrites = []
        }
        let stamp = Int(Date().timeIntervalSince1970)
        // Session fix: the timestamp alone can collide (two sessions within the
        // same second — e.g. a crash relaunch — would overwrite the previous
        // session file, destroying the evidence it holds). Add a unique suffix.
        var file = directory.appendingPathComponent("session-\(stamp).log")
        var uniquifier = 1
        while FileManager.default.fileExists(atPath: file.path) {
            file = directory.appendingPathComponent("session-\(stamp)-\(uniquifier).log")
            uniquifier += 1
        }
        do {
            try Data("session \(stamp) start\n".utf8).write(to: file, options: .atomic)
            sessionFile = file
        } catch {
            sessionFile = nil
        }
        // Garbage-collect old sessions, keeping the newest maxSessionFiles-1.
        let files = ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("session-") && $0.lastPathComponent.hasSuffix(".log") && $0 != file }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for old in files.dropFirst(Self.maxSessionFiles - 1) {
            try? FileManager.default.removeItem(at: old)
        }
        // Previous session = second-newest file overall (the newest is ours).
        if let previous = files.first, sessionFile != nil {
            let text = (try? String(contentsOf: previous, encoding: .utf8)) ?? ""
            if !text.contains("session end: clean") && !text.isEmpty {
                beginSessionReport = text
            }
        }
        return beginSessionReport
    }

    /// Text of the previous session when it ended without a clean-exit marker
    /// (watchdog termination, crash, jetsam). nil when the previous session
    /// ended cleanly or there is no previous session.
    static func previousSessionText() -> String? {
        shared.previousSessionTextLog()
    }

    /// Instance-level accessor (internal so the logic tests can exercise an
    /// isolated instance instead of the process-wide `shared`).
    func previousSessionTextLog() -> String? {
        lock.lock()
        let started = (sessionFile != nil)
        lock.unlock()
        guard started else { return nil }
        return beginSessionReport
    }

    /// Set by beginSessionFile: previous-session text if it ended abnormally.
    private var beginSessionReport: String?

    /// Called when the app is expected to keep running (best effort on
    /// scenePhase -> background): marks the session clean so the next launch
    /// does not treat it as terminated.
    func markSessionClean() {
        lock.lock()
        pendingDiskWrites.append("session end: clean\n")
        lock.unlock()
        flushDisk()
    }

    // MARK: - Disk flush

    /// Appends pending lines SYNCHRONOUSLY on the calling thread. Deliberately
    /// not async: the whole point of the session-file channel is to survive a
    /// sudden termination (crash/watchdog/jetsam), and an async utility-queue
    /// write would be lost in exactly the scenario it exists to capture. The
    /// writes are small line appends, so the latency cost is negligible.
    private func flushDisk() {
        lock.lock()
        let file = sessionFile
        let lines = pendingDiskWrites
        pendingDiskWrites = []
        lock.unlock()
        guard let file, !lines.isEmpty else { return }
        if let handle = try? FileHandle(forWritingTo: file) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            let data = Data(lines.joined(separator: "\n").appending("\n").utf8)
            try? handle.write(contentsOf: data)
        }
    }

    // MARK: - Footprint / export

    /// Current app memory footprint in MB via task_vm_info.phys_footprint —
    /// the same counter jetsam uses. Returns nil where mach headers are
    /// unavailable (Linux logic tests).
    static func footprintMB() -> Double? {
        #if canImport(Darwin)
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / (1024 * 1024)
        #else
        return nil
        #endif
    }

    /// Human-readable chronological export (oldest first) for copy/share.
    static func exportText() -> String {
        DiagLog.shared.exportTextLog()
    }

    /// Instance-level export so tests can exercise an isolated buffer.
    func exportTextLog() -> String {
        let (entries, dropped) = snapshot()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        var lines: [String] = []
        lines.append("weather diagnostics — \(entries.count) events\(dropped > 0 ? ", \(dropped) older dropped" : "")")
        if let mb = Self.footprintMB() { lines.append(String(format: "footprint at export: %.1f MB", mb)) }
        for entry in entries {
            let t = Date(timeIntervalSinceReferenceDate: entry.seconds)
            lines.append("\(formatter.string(from: t))  \(entry.message)")
        }
        return lines.joined(separator: "\n")
    }
}

private extension DiagLog.Entry {
    /// Stable single-line disk format ("<unixtime> <message>").
    var diskLine: String { "\(Int(seconds * 1000)) \(message)" }
}
