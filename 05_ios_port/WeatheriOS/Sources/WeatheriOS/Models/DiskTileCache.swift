import Foundation

// Persistent, byte-bounded disk tile cache for the map renderer — the iOS
// counterpart of the Android map HTTP cache (Maps.kt:81): an LRU cache of
// encoded tile responses at `cacheDir/map-http` capped at 48 MiB that survives
// relaunch. Eviction policy lives in TileCachePolicy.evictDisk (tested on
// Linux); request deduplication mirrors the in-flight guard of the in-memory
// TileLayer (one Task per URL, late awaiters share the same fetch).
//
// Keys are derived from tile URLs; no coordinates or city names ever reach the
// log (DiagLog privacy rule) — tile keys are opaque cache names.

actor DiskTileCache {
    static let shared = DiskTileCache()

    private let directory: URL
    /// key → (file size in bytes, monotonically increasing last-use stamp).
    private var index: [String: (size: Int, stamp: UInt64)] = [:]
    /// Running total of `index` sizes. Eviction is O(n log n) over the whole index,
    /// and `store` used to run it after every tile write — a full copy and sort of
    /// the index per tile while panning the map. The pass now runs only once the
    /// budget is actually exceeded.
    private var totalBytes = 0
    private var nextStamp: UInt64 = 1
    /// In-flight fetch dedupe: one Task per URL; awaiters share its result.
    private var inFlight: [String: Task<Data, Error>] = [:]

    init(directory: URL? = nil) {
        let base = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let dir = base?.appendingPathComponent("map-tiles", isDirectory: true)
        self.directory = dir ?? URL(fileURLWithPath: "/tmp/weather-map-tiles")
        // Inline index load (a nonisolated init cannot call isolated methods);
        // oldest modified file gets the smallest stamp so a pre-existing
        // oversized cache is brought under budget by the first eviction pass.
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        let contents: [URL] = (try? FileManager.default.contentsOfDirectory(
            at: self.directory, includingPropertiesForKeys: nil)) ?? []
        let files: [(url: URL, mtime: Date)] = contents
            .filter { $0.pathExtension == "png" }
            .map { file in
                let mtime = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return (file, mtime)
            }
        let sorted = files.sorted(by: { a, b in a.mtime < b.mtime })
        for file in sorted {
            let size = (try? file.url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            index[file.url.lastPathComponent] = (size, nextStamp)
            totalBytes += size
            nextStamp += 1
        }
    }

    /// Opaque, filesystem-safe cache key for a tile URL. Cache-namespace and
    /// path segments are preserved so distinct tile sources never collide.
    static func key(for url: URL) -> String {
        let raw = url.pathComponents.joined(separator: "_") + "_" + (url.query ?? "")
        let sanitized = raw.map { "/:?&=% ".contains($0) ? "_" : $0 }
        return String(sanitized.suffix(120)) + ".png"
    }

    private func fileURL(for key: String) -> URL {
        directory.appendingPathComponent(key)
    }

    // MARK: - Index

    /// Serialized index snapshot for eviction decisions.
    private var entries: [(key: String, size: Int, stamp: UInt64)] {
        index.map { key, value in (key, value.size, value.stamp) }
    }

    private func evictIfNeeded(protecting protected: Set<String>) {
        let toDrop = TileCachePolicy.evictDisk(
            entries: entries, protected: protected, budgetBytes: TileCachePolicy.maxDiskBytes)
        for key in toDrop {
            try? FileManager.default.removeItem(at: fileURL(for: key))
            totalBytes -= index[key]?.size ?? 0
            index[key] = nil
        }
        if !toDrop.isEmpty {
            Diag.event("tile disk cache evicted count=\(toDrop.count)")
        }
    }

    private func bump(_ key: String) {
        index[key]?.stamp = nextStamp
        nextStamp += 1
    }

    // MARK: - Read path

    /// Returns cached bytes for `url` (bumping its LRU stamp) or nil.
    func cachedData(for url: URL) -> Data? {
        let key = Self.key(for: url)
        guard index[key] != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: key)), !data.isEmpty else {
            // Self-heal: the index and the file disagree — drop the stale entry.
            try? FileManager.default.removeItem(at: fileURL(for: key))
            totalBytes -= index[key]?.size ?? 0
            index[key] = nil
            return nil
        }
        bump(key)
        return data
    }

    // MARK: - Fetch path (with dedupe)

    /// Cached bytes, else `fetch(url)` — with only one network Task per URL
    /// (late awaiters of the same tile share the running fetch). Fetch errors
    /// are rethrown unchanged so callers keep the exact URLError identity the
    /// previous direct-URLSession path produced (tile error mapping depends on
    /// it). Empty responses yield an error and are NOT cached.
    func data(for url: URL, fetch: @escaping @Sendable (URL) async throws -> Data) async throws -> Data {
        let key = Self.key(for: url)
        if let cached = cachedData(for: url) { return cached }

        if let running = inFlight[key] {
            return try await running.value
        }
        let task = Task<Data, Error> {
            let data = try await fetch(url)
            guard !data.isEmpty else { throw URLError(.badServerResponse) }
            return data
        }
        inFlight[key] = task
        let data: Data
        do {
            data = try await task.value
            inFlight[key] = nil
        } catch {
            inFlight[key] = nil
            throw error
        }

        store(data: data, for: key)
        return data
    }

    /// Atomic write (parity with Android AtomicFile) + eviction pass that
    /// protects the tile just written.
    private func store(data: Data, for key: String) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: key), options: .atomic)
            totalBytes += data.count - (index[key]?.size ?? 0)
            index[key] = (data.count, nextStamp)
            nextStamp += 1
            if totalBytes > TileCachePolicy.maxDiskBytes {
                evictIfNeeded(protecting: [key])
            }
        } catch {
            Diag.event("tile disk cache write failed")
        }
    }

    /// Total cached bytes (diagnostics only).
    func cachedBytes() -> Int { totalBytes }
}
