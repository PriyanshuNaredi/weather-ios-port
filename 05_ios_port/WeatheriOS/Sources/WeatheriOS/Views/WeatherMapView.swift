import SwiftUI
import CoreGraphics
import Foundation

// iOS port of `Maps.kt` (Workstream F) — WeatherMapPreview, WeatherMap, the
// radar timeline (RainViewer), the temperature grid overlay, and attribution.
//
// Implementation mapping (documented per project rule 6/7 — no behavior invented):
//   MapLibre Native + OpenFreeMap dark vector style  -> custom SwiftUI tile
//     renderer over CARTO dark-matter raster tiles
//     (https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png). OpenFreeMap
//     serves the dark-matter style as vector tiles; a raster endpoint for that
//     style is not available, so the port renders the same CARTO dark-matter
//     cartography. Attribution strings are preserved verbatim (MapAttribution).
//   MapView gestures/camera                          -> MapCamera (Web Mercator,
//     zoom clamped 2...12 like `setMinZoomPreference` / `setMaxZoomPreference`,
//     drag + pinch, initial zoom 5 interactive / 6 preview, recenter zoom 5).
//   RasterSource("radar-coverage") opacity .32       -> TileLayer over the
//     `${host}/v2/coverage/0/256/{z}/{x}/{y}/0/0_0.png` pattern, maxTileZoom 7
//     (Kotlin `TileSet maxZoom=7f` — tiles above zoom 7 are overscaled).
//   RasterSource("radar") opacity .8, fade 0         -> TileLayer over
//     `${host}${frame.path}/256/{z}/{x}/{y}/2/1_1.png`, maxTileZoom 7.
//   GeoJsonSource("temperature") + FillLayer .42     -> Canvas polygons drawn
//     from `temperatureFeatures(_:)` (ported verbatim below) at fillOpacity .42.
//   Bitmap marker labels                             -> SwiftUI text chips at the
//     same n/7%2==0 && n%7%2==0 sample positions.
//   Lifecycle active gating                          -> \.scenePhase.
//   Tile load failure                                -> "Some map tiles are
//     unavailable. Check your connection or try again." (Kotlin tile-action
//     listener, Maps.kt:106-110).

// Kotlin Maps.kt:70-71.
private let MapPanel = Color(red: 0x1B / 255, green: 0x30 / 255, blue: 0x4D / 255, opacity: 0xF0 / 255)
private let MapInk = Color(red: 0xE1 / 255, green: 0xEC / 255, blue: 0xFA / 255)

/// Kotlin Maps.kt:90 — the dark basemap identity. The Android app loads the
/// OpenFreeMap `dark` style (a MapLibre port of CARTO dark-matter); the iOS
/// port fetches the same dark-matter cartography as raster tiles.
private func darkBasemapTile(_ z: Int, _ x: Int, _ y: Int) -> URL {
    URL(string: "https://basemaps.cartocdn.com/dark_all/\(z)/\(x)/\(y).png")!
}

/// Kotlin Maps.kt:74-88 `prepareMap` User-Agent — the map HTTP client carries a
/// real application identity.
private let mapUserAgent = "Weather/1.1.1 (https://github.com/Kian-hdr/Weather; dev.kiankonrad.weather)"

private func mapTileHTTPRequest(_ url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.setValue(mapUserAgent, forHTTPHeaderField: "User-Agent")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return data
}

/// Parity fix (Maps.kt:81): tile bytes are served through a bounded persistent
/// disk cache (48 MiB, LRU, `Caches/map-tiles`) with in-flight request
/// dedupe — the counterpart of Android's map HTTP disk cache. The previous
/// direct `URLSession` fetch refetched every tile on relaunch and after
/// leaving/re-entering the map. Failures are not cached; the error path is
/// unchanged. Radar and temperature tiles flow through the same cache
/// transparently (same helper), so those layers are untouched functionally.
private func mapTileData(from url: URL) async throws -> Data {
    try await DiskTileCache.shared.data(for: url, fetch: mapTileHTTPRequest)
}

// MARK: - Web Mercator camera (MapLibre map state)

/// @MainActor @Observable: the map camera is view state (Kotlin keeps it inside
/// the MapView and reads it back via projections).
@MainActor
@Observable
final class MapCamera {
    var zoom: Double
    var centerLat: Double
    var centerLon: Double
    /// Bumped on every camera change — the SwiftUI equivalent of the Kotlin
    /// `addOnCameraIdleListener { dirty = true }` signal.
    var version = 0
    /// Current viewport size, set by the hosting GeometryReader (tile fetches
    /// and bounds queries need it).
    var lastSize: CGSize = .zero

    init(city: City, zoom: Double) {
        self.zoom = zoom
        self.centerLat = city.latitude
        self.centerLon = city.longitude
    }

    private func touch() { version += 1 }

    // Static Web Mercator helpers (tile units, fractional zoom).
    static func tileX(_ lon: Double, zoom: Double) -> Double {
        (lon + 180) / 360 * pow(2, zoom)
    }
    static func tileY(_ lat: Double, zoom: Double) -> Double {
        let s = sin(lat * .pi / 180)
        return (0.5 - log((1 + s) / (1 - s)) / (4 * .pi)) * pow(2, zoom)
    }
    static func lonFromTileX(_ x: Double, zoom: Double) -> Double {
        x / pow(2, zoom) * 360 - 180
    }
    static func latFromTileY(_ y: Double, zoom: Double) -> Double {
        let n = .pi - 2 * .pi * y / pow(2, zoom)
        return 180 / .pi * atan(sinh(n))
    }

    func moveTo(lat: Double, lon: Double, zoom newZoom: Double? = nil) {
        zoom = min(max(newZoom ?? zoom, 2.0), 12.0)  // Kotlin min/max zoom preferences
        centerLat = min(max(lat, -85.0), 85.0)
        centerLon = lon
        touch()
    }

    /// Drag translation in screen points → new center.
    func panBy(dx: Double, dy: Double) {
        let z = zoom
        let n = pow(2, z)
        var cx = Self.tileX(centerLon, zoom: z) - dx / 256
        let cy = Self.tileY(centerLat, zoom: z) - dy / 256
        cx = (cx.truncatingRemainder(dividingBy: n) + n)
            .truncatingRemainder(dividingBy: n)
        centerLat = Self.latFromTileY(min(max(cy, 0), n), zoom: z)
        centerLon = Self.lonFromTileX(cx, zoom: z)
        touch()
    }

    func zoomBy(_ deltaLog2: Double, anchor: CGPoint, size: CGSize) {
        let before = geoPoint(at: anchor, size: size)
        zoom = min(max(zoom + deltaLog2, 2.0), 12.0)
        touch()
        if let before {
            let after = screenPoint(lat: before.lat, lon: before.lon, size: size)
            panBy(dx: after.x - anchor.x, dy: after.y - anchor.y)
        }
    }

    /// Geographic coordinate under a screen point.
    func geoPoint(at point: CGPoint, size: CGSize) -> (lat: Double, lon: Double)? {
        guard size.width > 0, size.height > 0 else { return nil }
        let cx = Self.tileX(centerLon, zoom: zoom)
        let cy = Self.tileY(centerLat, zoom: zoom)
        let tx = cx + (point.x - size.width / 2) / 256
        let ty = cy + (point.y - size.height / 2) / 256
        return (Self.latFromTileY(ty, zoom: zoom), Self.lonFromTileX(tx, zoom: zoom))
    }

    /// Screen point for a geographic coordinate (Canvas coordinates).
    func screenPoint(lat: Double, lon: Double, size: CGSize) -> CGPoint {
        let cx = Self.tileX(centerLon, zoom: zoom)
        let cy = Self.tileY(centerLat, zoom: zoom)
        return CGPoint(
            x: size.width / 2 + (Self.tileX(lon, zoom: zoom) - cx) * 256,
            y: size.height / 2 + (Self.tileY(lat, zoom: zoom) - cy) * 256)
    }

    /// Kotlin `map.projection.visibleRegion.latLngBounds` (Maps.kt:259).
    func visibleBounds(size: CGSize) -> (west: Double, south: Double, east: Double, north: Double) {
        let cx = Self.tileX(centerLon, zoom: zoom)
        let cy = Self.tileY(centerLat, zoom: zoom)
        let westX = cx - size.width / 2 / 256
        let eastX = cx + size.width / 2 / 256
        let northY = cy - size.height / 2 / 256
        let southY = cy + size.height / 2 / 256
        let n = pow(2, zoom)
        let wrap = { (x: Double) in (x.truncatingRemainder(dividingBy: n) + n).truncatingRemainder(dividingBy: n) }
        let south = Self.latFromTileY(min(max(southY, 0), n), zoom: zoom)
        let north = Self.latFromTileY(min(max(northY, 0), n), zoom: zoom)
        // Report unwrapped east/west so an antimeridian viewport keeps its span.
        let west = Self.lonFromTileX(westX, zoom: zoom)
        let east = Self.lonFromTileX(eastX, zoom: zoom)
        return (west, south, east, north)
    }
}

/// Tiles covering the viewport at a layer's tile zoom, in (z, x, y, key) form.
@MainActor
private func neededTiles(camera: MapCamera, maxTileZoom: Int, size: CGSize)
    -> [(z: Int, x: Int, y: Int, key: String)] {
    guard size.width > 0, size.height > 0 else { return [] }
    let z = camera.zoom
    let zI = min(max(Int(z.rounded(.down)), 0), 20)
    let zT = min(zI, maxTileZoom)
    let sT = pow(2, z - Double(zT))
    let nT = Int(pow(2, Double(zT)))
    let cxT = MapCamera.tileX(camera.centerLon, zoom: Double(zT))
    let cyT = MapCamera.tileY(camera.centerLat, zoom: Double(zT))
    let pixelsPerTile = 256 * sT
    let xMin = Int(floor(cxT - size.width / 2 / pixelsPerTile))
    let xMax = Int(floor(cxT + size.width / 2 / pixelsPerTile))
    let yMin = Int(floor(cyT - size.height / 2 / pixelsPerTile))
    let yMax = Int(floor(cyT + size.height / 2 / pixelsPerTile))
    var tiles: [(Int, Int, Int, String)] = []
    for y in yMin...yMax {
        guard y >= 0, y < nT else { continue }
        for x in xMin...xMax {
            let wrapped = ((x % nT) + nT) % nT
            tiles.append((zT, wrapped, y, "\(zT)/\(wrapped)/\(y)"))
        }
    }
    return tiles
}

// MARK: - Tile layer

/// Sendable box for a decoded tile bitmap (CGImage is immutable once decoded;
/// Swift 6 cannot prove it from `CGImageSource`).
final class TileBox: @unchecked Sendable {
    let image: CGImage
    init(_ image: CGImage) { self.image = image }
}

private func decodeTile(_ data: Data) -> CGImage? {
    let source = CGImageSourceCreateWithData(data as CFData, nil)
    return source.flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
}

/// One raster tile layer, drawn in Web Mercator. Mirrors a MapLibre
/// `RasterSource` + `RasterLayer`: tiles are fetched at `maxTileZoom` and
/// overscaled above it (Kotlin `TileSet maxZoom=7f` semantics).
struct TileLayer: View {
    let camera: MapCamera
    let urlFor: (Int, Int, Int) -> URL?
    let maxTileZoom: Int
    var opacity: Double = 1
    /// Cache namespace — the radar frame layer passes `frame.path` so
    /// successive radar frames never collide in the cache (each frame's tiles
    /// stay cached during animation, and old frames are evicted by the LRU
    /// bound instead of overwriting each other).
    var cacheNamespace: String = ""
    /// Called when a tile fails to load (Kotlin tile-action error listener).
    var onTileError: ((String) -> Void)? = nil

    // Stability fix (memory pressure): the previous version had `.id(cacheTick)`
    // on the Canvas — bumping it every fetch completion reset the view identity,
    // which wiped `@State`, restarted the `.task`, and looped forever, decoding
    // tiles on the main thread. Identity is now stable; redraws come from
    // ordinary @State mutations.
    @State private var cache: [String: TileBox] = [:]
    @State private var lastUse: [String: UInt64] = [:]
    @State private var inFlight: Set<String> = []
    @State private var failures: [String: Date] = [:]
    @State private var useClock: UInt64 = 0

    private func key(_ tileKey: String) -> String {
        cacheNamespace.isEmpty ? tileKey : "\(cacheNamespace)|\(tileKey)"
    }

    var body: some View {
        Canvas { context, size in
            let z = camera.zoom
            let zI = min(max(Int(z.rounded(.down)), 0), 20)
            let zT = min(zI, maxTileZoom)
            let sT = pow(2, z - Double(zT))
            let nT = pow(2, Double(zT))
            let cxT = MapCamera.tileX(camera.centerLon, zoom: Double(zT))
            let cyT = MapCamera.tileY(camera.centerLat, zoom: Double(zT))
            let pixelsPerTile = 256 * sT
            let xMin = Int(floor(cxT - size.width / 2 / pixelsPerTile))
            let xMax = Int(floor(cxT + size.width / 2 / pixelsPerTile))
            let yMin = Int(floor(cyT - size.height / 2 / pixelsPerTile))
            let yMax = Int(floor(cyT + size.height / 2 / pixelsPerTile))
            for y in yMin...yMax {
                guard y >= 0, y < Int(nT) else { continue }
                for x in xMin...xMax {
                    let wrapped = ((x % Int(nT)) + Int(nT)) % Int(nT)
                    let cacheKey = key("\(zT)/\(wrapped)/\(y)")
                    guard let box = cache[cacheKey] else { continue }
                    let screenX = size.width / 2 + (Double(x) - cxT) * pixelsPerTile
                    let screenY = size.height / 2 + (Double(y) - cyT) * pixelsPerTile
                    context.draw(
                        Image(box.image, scale: 1, label: Text(cacheKey)),
                        in: CGRect(x: screenX, y: screenY,
                                   width: pixelsPerTile, height: pixelsPerTile))
                }
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .task(id: camera.version) {
            // Fetch the tiles visible at the current camera. `.task(id:)`
            // cancels superseded runs when the camera moves; each result is
            // applied on the MainActor (cache is view state). Kotlin fetches
            // through OkHttp with modest parallelism — bounded at 8 here via
            // TileCachePolicy.
            let tiles = neededTiles(camera: camera, maxTileZoom: maxTileZoom, size: camera.lastSize)
            let now = Date()
            useClock &+= 1
            let viewportKeys = Set(tiles.map { key($0.key) })
            for cacheKey in viewportKeys { lastUse[cacheKey] = useClock }
            let pending = tiles.filter {
                TileCachePolicy.shouldFetch(
                    key: $0.key, cached: cache[key($0.key)] != nil,
                    inFlight: inFlight.contains(key($0.key)),
                    lastFailure: failures[key($0.key)], now: now)
            }
            guard !pending.isEmpty else {
                evictIfNeeded(currentKeys: viewportKeys)
                return
            }
            Diag.event("tiles fetch namespace=\(cacheNamespace.isEmpty ? "base" : "radar-frame") count=\(pending.count) cached=\(cache.count)")
            var failed = false
            await withTaskGroup(of: (String, TileBox?, Bool).self) { group in
                var iterator = pending.makeIterator()
                var inFlightCount = 0
                // Watchdog fix: explicit iterator-exhaustion flag. Previously
                // addNext() silently no-opped once `pending` was drained, so
                // this priming loop spun forever on the main actor whenever
                // fewer pending tiles existed than maxConcurrentTileFetches
                // (e.g. the second camera move, when most tiles are already
                // cached) — freezing the UI until the OS watchdog killed the
                // app. Semantics pinned by TileSchedulerTests via
                // TileCachePolicy.simulateTileScheduler.
                var iteratorExhausted = false
                func addNext() {
                    guard let tile = iterator.next() else {
                        iteratorExhausted = true
                        return
                    }
                    let url = urlFor(tile.z, tile.x, tile.y)
                    let cacheKey = key(tile.key)
                    inFlight.insert(cacheKey)
                    group.addTask {
                        guard let url else { return (cacheKey, nil, true) }
                        do {
                            let data = try await mapTileData(from: url)
                            // Decode off the main thread: task-group child
                            // tasks inherit MainActor isolation (SE-0431), and
                            // PNG decode on the main actor starved the UI.
                            let image = await Task.detached(priority: .utility) {
                                decodeTile(data)
                            }.value
                            return (cacheKey, image.map(TileBox.init), false)
                        } catch is CancellationError {
                            return (cacheKey, nil, false)
                        } catch {
                            return (cacheKey, nil, true)
                        }
                    }
                    inFlightCount += 1
                }
                while !iteratorExhausted && inFlightCount < TileCachePolicy.maxConcurrentTileFetches { addNext() }
                while let result = await group.next() {
                    inFlightCount -= 1
                    addNext()
                    let (cacheKey, box, failedTile) = result
                    inFlight.remove(cacheKey)
                    if failedTile {
                        failed = true
                        failures[cacheKey] = Date()   // negative cache: retry after TileCachePolicy.failureRetryDelay
                    }
                    if let box, cache[cacheKey] == nil { cache[cacheKey] = box }
                }
            }
            evictIfNeeded(currentKeys: Set(tiles.map { key($0.key) }))
            if failed { onTileError?(tileErrorMessage) }
        }
    }

    /// Bounded LRU eviction via TileCachePolicy — an explicit memory ceiling
    /// (TileCachePolicy.maxTiles per layer) instead of the previous
    /// keep-only-current-viewport thrash.
    private func evictIfNeeded(currentKeys: Set<String>) {
        let dropped = TileCachePolicy.evict(entries: lastUse, currentKeys: currentKeys,
                                            limit: TileCachePolicy.maxTiles)
        guard !dropped.isEmpty else { return }
        for cacheKey in dropped {
            cache[cacheKey] = nil
            lastUse[cacheKey] = nil
            failures[cacheKey] = nil
        }
        Diag.event("tiles evicted count=\(dropped.count) remaining=\(cache.count)")
    }
}

/// Kotlin Maps.kt:106-110 tile-action error listener message.
let tileErrorMessage = "Some map tiles are unavailable. Check your connection or try again."

// MARK: - Temperature overlay math (ported verbatim from Maps.kt:364-394)

/// Kotlin `Maps.kt:364 temperatureFeatures` builds a GeoJSON FeatureCollection
/// string for MapLibre; the iOS port returns the same polygons as structs and
/// draws them directly. Bilinear colors within cells whose four samples exist.
/// Never bridges missing data.
public struct MapLonLat: Equatable, Sendable {
    public var lon: Double
    public var lat: Double
    public init(lon: Double, lat: Double) { self.lon = lon; self.lat = lat }
}

public struct TemperatureCell: Equatable, Sendable {
    public var ring: [MapLonLat]
    public var color: String
    public init(ring: [MapLonLat], color: String) { self.ring = ring; self.color = color }
}

func temperatureFeatures(_ grid: TemperatureGrid) -> [TemperatureCell] {
    var features: [TemperatureCell] = []
    guard grid.points.count == 49 else { return features }
    for row in 0..<6 {
        for col in 0..<6 {
            let a = grid.points[row * 7 + col]
            let b = grid.points[row * 7 + col + 1]
            let c = grid.points[(row + 1) * 7 + col]
            let d = grid.points[(row + 1) * 7 + col + 1]
            if [a, b, c, d].contains(where: { $0.temperature == nil }) { continue }
            // Keep longitude unwrapped per cell so an antimeridian viewport
            // never paints across the planet.
            func near(_ lon: Double, _ ref: Double) -> Double {
                var n = lon
                while n - ref > 180 { n -= 360 }
                while n - ref < -180 { n += 360 }
                return n
            }
            let left = a.longitude
            let right = near(b.longitude, left)
            if abs(right - left) > 180 { continue }
            guard let ta = a.temperature, let tb = b.temperature,
                  let tc = c.temperature, let td = d.temperature else { continue }
            for y in 0..<4 {
                for x in 0..<4 {
                    let u = (Double(x) + 0.5) / 4
                    let v = (Double(y) + 0.5) / 4
                    let t = (ta * (1 - u) + tb * u) * (1 - v) + (tc * (1 - u) + td * u) * v
                    let west = left + (right - left) * Double(x) / 4
                    let east = left + (right - left) * Double(x + 1) / 4
                    let south = a.latitude + (c.latitude - a.latitude) * Double(y) / 4
                    let north = a.latitude + (c.latitude - a.latitude) * Double(y + 1) / 4
                    let ring = [MapLonLat(lon: west, lat: south), MapLonLat(lon: east, lat: south),
                                MapLonLat(lon: east, lat: north), MapLonLat(lon: west, lat: north),
                                MapLonLat(lon: west, lat: south)]
                    features.append(TemperatureCell(ring: ring, color: temperatureColor(t)))
                }
            }
        }
    }
    return features
}

/// Kotlin Maps.kt:387-394 `temperatureColor` — exact stop table and channels.
func temperatureColor(_ c: Double) -> String {
    let stops: [(Double, Int)] = [
        (-20.0, 0x765BD5), (0.0, 0x3A9BDC), (10.0, 0x53C4AC),
        (20.0, 0xF1CE55), (30.0, 0xF07A50), (40.0, 0xCC427D),
    ]
    let upper = stops.firstIndex { c <= $0.0 } ?? stops.count - 1
    if upper == 0 { return "#765BD5" }
    let (lo, lc) = stops[upper - 1]
    let (hi, hc) = stops[upper]
    let f = min(max((c - lo) / (hi - lo), 0.0), 1.0)
    func channel(_ shift: Int) -> Int {
        let lo8 = Double((lc >> shift) & 255)
        let hi8 = Double((hc >> shift) & 255)
        return Int((lo8 * (1 - f) + hi8 * f).rounded())
    }
    return String(format: "#%02x%02x%02x", channel(16), channel(8), channel(0))
}

// MARK: - Preview card (Kotlin Maps.kt:167-177)

struct WeatherMapPreviewView: View {
    let city: City
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("WEATHER MAP")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MapInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            ZStack {
                StaticMapSnapshot(city: city, zoom: 6)
                VStack {
                    Spacer()
                    Button(action: onOpen) {
                        Text("Open rainfall & temperature map")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .background(MapPanel)
                    .clipShape(RoundedRectangle(cornerRadius: 999))
                    .padding(8)
                }
            }
            .frame(height: 174)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            MapAttribution(radar: false, temperature: false, compact: true)
                .padding(.top, 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .background(Color.white.opacity(0.11))
    }
}

/// Non-interactive map snapshot: fixed camera (zoom 6, Kotlin preview default),
/// no gestures, basemap + city dot only — the WeatherMapPreview card content.
private struct StaticMapSnapshot: View {
    let city: City
    @State private var camera: MapCamera

    init(city: City, zoom: Double) {
        self.city = city
        _camera = State(initialValue: MapCamera(city: city, zoom: zoom))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TileLayer(camera: camera, urlFor: { darkBasemapTile($0, $1, $2) },
                          maxTileZoom: 20)
                CityDotLayer(camera: camera, city: city, size: geo.size)
            }
            .onAppear { camera.lastSize = geo.size }
            .onChange(of: geo.size) { _, new in camera.lastSize = new }
        }
        .clipped()
    }
}

// MARK: - City dot (Kotlin Maps.kt:135-137)

struct CityDotLayer: View {
    let camera: MapCamera
    let city: City
    let size: CGSize

    var body: some View {
        Canvas { context, _ in
            let p = camera.screenPoint(lat: city.latitude, lon: city.longitude, size: size)
            let dot = CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: dot), with: .color(Color(red: 0x16 / 255, green: 0x79 / 255, blue: 0xF2 / 255)))
            context.stroke(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)),
                           with: .color(.white), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Full map screen (Kotlin Maps.kt:179-343)

struct WeatherMapView: View {
    let city: City
    let repository: MapRepository
    let imperial: Bool
    let onClose: () -> Void

    // Kotlin Maps.kt:182-202 — exact state shape.
    @State private var layer = "Rainfall"
    @State private var timeline: RadarTimeline?
    @State private var index = -1
    @State private var playing = false
    @State private var grid: TemperatureGrid?
    @State private var dirty = false
    @State private var radarLoading = false
    @State private var temperatureLoading = false
    @State private var radarError: String?
    @State private var temperatureError: String?
    /// Structured handle for the temperature grid load — cancelled when the
    /// map screen disappears (no unbounded unstructured Task left behind).
    @State private var temperatureTask: Task<Void, Never>?
    @State private var mapError: String?
    @State private var radarLoad = 0
    @State private var mapGeneration = 0
    @State private var lastScale: CGFloat?

    @State private var camera: MapCamera
    @Environment(\.scenePhase) private var scenePhase

    init(city: City, repository: MapRepository, imperial: Bool, onClose: @escaping () -> Void) {
        self.city = city
        self.repository = repository
        self.imperial = imperial
        self.onClose = onClose
        _camera = State(initialValue: MapCamera(city: city, zoom: 5))  // Kotlin interactive zoom 5.0
    }

    private var loading: Bool { layer == "Rainfall" ? radarLoading : temperatureLoading }
    private var error: String? { mapError ?? (layer == "Rainfall" ? radarError : temperatureError) }
    private var active: Bool { scenePhase == .active }  // Kotlin lifecycle RESUMED gating

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 600 && geo.size.width > geo.size.height
            let showMapSubtitle = geo.size.height > 420
            let overlayWidth: CGFloat = wide ? min(340, (geo.size.width - 24) / 2) : geo.size.width

            ZStack {
                Color(red: 0x14 / 255, green: 0x24 / 255, blue: 0x3B / 255)  // Kotlin BoxWithConstraints background
                    .ignoresSafeArea()

                mapContent(size: geo.size)

                // Kotlin wide-screen split (top overlay top-start / bottom card
                // bottom-end on wide, centered otherwise), 12dp outer padding.
                VStack {
                    HStack(alignment: .top, spacing: 0) {
                        if wide { Spacer(minLength: 0) }
                        topOverlay(width: overlayWidth)
                            .frame(maxWidth: overlayWidth, alignment: wide ? .leading : .center)
                    }
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: 0) {
                        bottomCard
                            .frame(maxWidth: overlayWidth, alignment: .center)
                        if wide { Spacer(minLength: 0) }
                    }
                }
                .padding(12)
            }
            .onAppear {
                camera.lastSize = geo.size
                Diag.event("map screen appear (radar=\(DebugConfig.radarEnabled ? "on" : "off"))")
                if !DebugConfig.radarEnabled { Diag.event("radar layers suppressed by diag config C") }
            }
            .onDisappear { Diag.event("map screen disappear") }
            .onChange(of: geo.size) { _, new in camera.lastSize = new }
            .onChange(of: camera.version) { _, _ in dirty = true }  // Kotlin camera-idle listener
            .onChange(of: layer) { _, _ in
                // Kotlin LaunchedEffect(layer, map) line 270 — first entry into
                // Temperature loads the grid.
                playing = false
                mapError = nil
                if layer == "Temperature", grid == nil {
                    updateTemperatures(size: geo.size)
                }
            }
        }
        .task(id: radarLoad) { await loadRadar() }  // Kotlin LaunchedEffect(radarLoad)
        .task(id: refreshKey) {
            // Kotlin LaunchedEffect(active, layer) lines 220-222 — 5-minute
            // radar refresh while visible on the Rainfall layer.
            guard active, layer == "Rainfall" else { return }
            while active && layer == "Rainfall" {
                try? await Task.sleep(nanoseconds: 300_000_000_000)
                guard !Task.isCancelled else { return }
                radarLoad += 1
                return  // radarLoad bump re-runs this task via its id
            }
        }
        .task(id: animationKey) {
            // Kotlin LaunchedEffect(playing, active, layer, timeline) lines 223-228.
            guard playing, active, layer == "Rainfall",
                  let frames = timeline?.frames, !frames.isEmpty else { return }
            while playing && active && layer == "Rainfall" && !frames.isEmpty {
                let delay: UInt64 = index == frames.count - 1 ? 1_300_000_000 : 700_000_000
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return }
                index = (index + 1) % frames.count
                Diag.event("radar frame \(index + 1)/\(frames.count)")
            }
        }
        .onDisappear {
            // Stability fix: stop the temperature load when the map leaves the
            // hierarchy; nothing else here retains long-lived work.
            temperatureTask?.cancel()
            temperatureTask = nil
        }
        .preferredColorScheme(.dark)
    }

    private var refreshKey: String { "\(active)|\(layer)|\(radarLoad)" }
    private var animationKey: String {
        "\(playing)|\(active)|\(layer)|\(timeline?.fetchedAt ?? 0)|\(timeline?.frames.count ?? 0)"
    }

    // Kotlin NativeWeatherMap composition — basemap, overlays, city dot.
    @ViewBuilder
    private func mapContent(size: CGSize) -> some View {
        ZStack {
            // Basemap; a failed tile maps to the Kotlin basemap-load failure
            // message (Maps.kt:105 style-load listener — the renderer has no
            // separate style step, so a basemap tile failure is its analog).
            // Radar tile failures below use the Kotlin tile-action message
            // (Maps.kt:106-110). `.id(mapGeneration)` recreates the tile caches
            // exactly like Kotlin recreates the MapView on "Try again".
            TileLayer(camera: camera, urlFor: { darkBasemapTile($0, $1, $2) },
                      maxTileZoom: 20,
                      onTileError: { _ in
                          if mapError == nil {
                              mapError = "Map could not load. Check your connection."
                          }
                      })
            if layer == "Rainfall" {
                if let radar = timeline {
                    // Phase-4 diagnostic configuration C (`diag.radarEnabled =
                    // false`) suppresses ONLY the radar tile layers — the
                    // basemap, gestures and the Temperature layer stay intact,
                    // so nothing is permanently removed (config D/E restores
                    // the radar via the Diagnostics screen toggle).
                    if DebugConfig.radarEnabled {
                        TileLayer(camera: camera,
                                  urlFor: { z, x, y in
                                      URL(string: "\(radar.host)/v2/coverage/0/256/\(z)/\(x)/\(y)/0/0_0.png")
                                  },
                                  maxTileZoom: 7, opacity: 0.32)  // Kotlin coverage opacity .32
                        if let frame = radar.frames[safe: index] {
                            TileLayer(camera: camera,
                                      urlFor: { z, x, y in
                                          URL(string: "\(radar.host)\(frame.path)/256/\(z)/\(x)/\(y)/2/1_1.png")
                                      },
                                      maxTileZoom: 7, opacity: 0.8,   // Kotlin radar opacity .8, fade 0
                                      cacheNamespace: frame.path)     // frames must not collide in the cache
                        }
                    } else {
                        // Suppression notice is logged once from onAppear, not
                        // here — body may be evaluated many times per second.
                    }
                }
            } else if let grid {
                TemperatureOverlay(camera: camera, grid: grid, size: size)
                temperatureLabels(grid)
            }
            CityDotLayer(camera: camera, city: city, size: size)
        }
        .id(mapGeneration)
        .contentShape(Rectangle())
        // Kotlin Maps.kt:104 contentDescription.
        .accessibilityLabel("Weather map centered on \(city.name)")
        .gesture(dragGesture)
        .simultaneousGesture(pinchGesture(size: size))
    }

    // DragGesture.translation is cumulative across the gesture, so the pan
    // delta is measured against the previous frame's translation.
    @State private var lastDrag: CGSize?

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if lastDrag == nil {
                    Diag.event("map drag detected")   // instrumentation: gesture reached the map
                }
                if let last = lastDrag {
                    camera.panBy(dx: -(value.translation.width - last.width),
                                 dy: -(value.translation.height - last.height))
                }
                lastDrag = value.translation
            }
            .onEnded { _ in lastDrag = nil }
    }

    private func pinchGesture(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if let last = lastScale {
                    camera.zoomBy(log2(Double(value.magnification / last)),
                                  anchor: value.startLocation, size: size)
                }
                lastScale = value.magnification
            }
            .onEnded { _ in lastScale = nil }
    }

    // Kotlin marker loop (Maps.kt:249-254) — every other row/column sample
    // gets a numeric label.
    @ViewBuilder
    private func temperatureLabels(_ grid: TemperatureGrid) -> some View {
        GeometryReader { geo in
            ForEach(Array(grid.points.enumerated()), id: \.offset) { n, p in
                if p.temperature != nil, n / 7 % 2 == 0, n % 7 % 2 == 0 {
                    let point = camera.screenPoint(lat: p.latitude, lon: p.longitude, size: geo.size)
                    Text(temp(p.temperature, imperial: imperial))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(red: 22 / 255, green: 43 / 255, blue: 67 / 255)
                            .opacity(210.0 / 255.0))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .position(point)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // Kotlin top overlay column (Maps.kt:285-307).
    private func topOverlay(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .accessibilityLabel("Back")
                VStack(alignment: .leading) {
                    Text(city.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("Weather maps")
                        .font(.system(size: 13))
                        .foregroundStyle(MapInk)
                }
                Spacer(minLength: 8)
                Button {
                    // Kotlin animateCamera back to the city at zoom 5.
                    camera.moveTo(lat: city.latitude, lon: city.longitude, zoom: 5)
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .accessibilityLabel("Center on \(city.name)")
            }
            .background(MapPanel)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack(spacing: 8) {
                ForEach(["Rainfall", "Temperature"], id: \.self) { name in
                    Button {
                        Diag.event("map layer tap -> \(name)")
                        layer = name
                        playing = false
                        mapError = nil
                    } label: {
                        Text(name)
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(layer == name ? Color(red: 0x18 / 255, green: 0x3D / 255, blue: 0x68 / 255) : .white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .background(layer == name ? Color.white : MapPanel)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            if let error {
                VStack(alignment: .leading, spacing: 4) {
                    ScrollView {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(maxHeight: 140)
                    Button {
                        // Kotlin "Try again" (Maps.kt:303) — exact reset shape.
                        mapError = nil
                        radarError = nil
                        temperatureError = nil
                        grid = nil
                        mapGeneration += 1
                        if layer == "Rainfall" { radarLoad += 1 }
                    } label: {
                        Text("Try again")
                            .foregroundStyle(Color(red: 0xB4 / 255, green: 0xDB / 255, blue: 0xFF / 255))
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }
                    .buttonStyle(.plain)
                }
                .background(MapPanel)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if loading {
                ProgressView()
                    .tint(Color(red: 0xB4 / 255, green: 0xDB / 255, blue: 0xFF / 255))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
    }

    // Kotlin bottom control card (Maps.kt:308-341).
    private var bottomCard: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                if layer == "Temperature", dirty {
                    Button {
                        updateTemperatures(size: camera.lastSize)
                    } label: {
                        // Kotlin filled button: white container, dark label.
                        Text("Update this area")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 0x18 / 255, green: 0x3D / 255, blue: 0x68 / 255))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(loading)
                }
                if layer == "Rainfall" {
                    radarControls
                } else {
                    temperatureControls
                }
                MapAttribution(radar: layer == "Rainfall", temperature: layer == "Temperature")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(MapPanel)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(12)
    }

    // Kotlin lines 316-326 — the Rainfall controls block, exact wording.
    private var radarControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    Diag.event("radar play tap -> \(playing ? "pause" : "play")")
                    playing.toggle()
                } label: {
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                }
                .disabled(timeline?.frames.isEmpty != false)  // Kotlin enabled=!frames.isNullOrEmpty
                .accessibilityLabel(playing ? "Pause radar" : "Play recent radar")
                VStack(alignment: .leading) {
                    Text("Recent precipitation radar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(timeline?.frames[safe: index].map {
                            "Frame \(localTime($0.time, zone: city.timezone)) · \(city.timezone)"
                        } ?? "Waiting for radar")
                        .font(.system(size: 12))
                        .foregroundStyle(MapInk)
                }
            }
            if let frames = timeline?.frames, frames.count > 1 {
                Slider(
                    value: Binding(
                        get: { Double(max(index, 0)) },
                        set: { playing = false; index = Int($0.rounded()) }),
                    in: 0...Double(frames.count - 1),
                    step: 1)
                    .accessibilityLabel("Radar timeline")
            }
            LinearGradient(colors: [
                Color(red: 0x5B / 255, green: 0xBB / 255, blue: 0xE8 / 255),
                Color(red: 0x63 / 255, green: 0xCA / 255, blue: 0x73 / 255),
                Color(red: 0xF5 / 255, green: 0xD4 / 255, blue: 0x4B / 255),
                Color(red: 0xEB / 255, green: 0x53 / 255, blue: 0x6D / 255),
                Color(red: 0xAE / 255, green: 0x6C / 255, blue: 0xD4 / 255),
            ], startPoint: .leading, endPoint: .trailing)
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack {
                Text("Light"); Spacer(); Text("Heavy")
            }
            .font(.system(size: 12))
            .foregroundStyle(MapInk)
            Text("Shaded areas lack radar coverage. Frame times combine radar observations; blank areas do not prove dry weather. Detail is limited above zoom 7.")
                .font(.system(size: 11))
                .lineSpacing(3)
                .foregroundStyle(MapInk)
        }
    }

    // Kotlin lines 327-335 — the Temperature controls block, exact wording.
    private var temperatureControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interpolated model temperature")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Text(grid?.points.first { $0.temperature != nil }.map {
                    "Valid \(localTime($0.time, zone: city.timezone)) · \(city.timezone)"
                } ?? "Load temperatures for this area")
                .font(.system(size: 12))
                .foregroundStyle(MapInk)
            let readings = (grid?.points.compactMap { $0.temperature }) ?? []
            if let lo = readings.min(), let hi = readings.max(), !readings.isEmpty {
                Text("Area range: \(temp(lo, imperial: imperial)) to \(temp(hi, imperial: imperial)) \(imperial ? "F" : "C") · \(readings.count) of 49 samples")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Temperature map sample range, \(temp(lo, imperial: imperial)) to \(temp(hi, imperial: imperial)) degrees \(imperial ? "Fahrenheit" : "Celsius"). \(readings.count) of 49 regional samples available.")
            }
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0x76 / 255, green: 0x5B / 255, blue: 0xD5 / 255), location: 0),
                    .init(color: Color(red: 0x3A / 255, green: 0x9B / 255, blue: 0xDC / 255), location: 1.0 / 3),
                    .init(color: Color(red: 0x53 / 255, green: 0xC4 / 255, blue: 0xAC / 255), location: 0.5),
                    .init(color: Color(red: 0xF1 / 255, green: 0xCE / 255, blue: 0x55 / 255), location: 2.0 / 3),
                    .init(color: Color(red: 0xF0 / 255, green: 0x7A / 255, blue: 0x50 / 255), location: 5.0 / 6),
                    .init(color: Color(red: 0xCC / 255, green: 0x42 / 255, blue: 0x7D / 255), location: 1),
                ],
                startPoint: .leading, endPoint: .trailing)
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack {
                ForEach([-20.0, 0.0, 20.0, 40.0], id: \.self) { value in
                    Text(temp(value, imperial: imperial))
                }
                Spacer(minLength: 0)
            }
            .font(.system(size: 12))
            .foregroundStyle(MapInk)
            Text("Regional 7 × 7 samples, interpolated between valid points. Transparent gaps have no data. Not street-level measurements.")
                .font(.system(size: 11))
                .lineSpacing(3)
                .foregroundStyle(MapInk)
        }
    }

    // Kotlin `loadRadar` LaunchedEffect (Maps.kt:209-219) — followLatest
    // semantics preserved exactly.
    private func loadRadar() async {
        radarLoading = true
        radarError = nil
        defer { radarLoading = false }
        do {
            let followLatest = index < 0 || index == (timeline?.frames.count ?? 0) - 1 && (timeline?.frames.isEmpty == false)
            let newTimeline = try await repository.radar()
            timeline = newTimeline
            Diag.event("radar timeline loaded frames=\(newTimeline.frames.count)")
            let last = max(newTimeline.frames.count - 1, 0)
            if followLatest {
                index = last
            } else {
                index = min(max(index, 0), last)
            }
            if newTimeline.frames.isEmpty {
                radarError = "No recent radar frames are available."
            }
        } catch is CancellationError {
        } catch {
            Diag.event("radar timeline FAILED")
            radarError = "Radar unavailable. Check your connection and try again."
        }
    }

    // Kotlin `updateTemperatures` (Maps.kt:258-269). Stability fix: the load
    // runs in one structured, tracked Task — duplicate calls are guarded out,
    // and it is cancelled when the map disappears (previous version spawned a
    // fresh unstructured Task per tap with no dedupe or teardown).
    private func updateTemperatures(size: CGSize) {
        guard temperatureTask == nil else {
            Diag.event("temperature load already in flight — skipped duplicate")
            return
        }
        let bounds = camera.visibleBounds(size: size)
        temperatureLoading = true
        temperatureError = nil
        temperatureTask = Task {
            defer { temperatureTask = nil }
            do {
                let newGrid = try await repository.temperatures(
                    west: bounds.west, south: bounds.south, east: bounds.east, north: bounds.north)
                grid = newGrid
                dirty = false
                if newGrid.points.allSatisfy({ $0.temperature == nil }) {
                    temperatureError = "Temperature data unavailable in this area."
                }
            } catch is CancellationError {
            } catch {
                temperatureError = "Temperature map unavailable. Try updating this area again."
            }
            temperatureLoading = false
        }
        Diag.event("temperature grid load started")
    }
}

// MARK: - Temperature fill overlay (Kotlin FillLayer .42, Maps.kt:245-247)

struct TemperatureOverlay: View {
    let camera: MapCamera
    let grid: TemperatureGrid
    let size: CGSize

    var body: some View {
        Canvas { context, _ in
            for cell in temperatureFeatures(grid) where cell.ring.count == 5 {
                var path = Path()
                for (i, point) in cell.ring.enumerated() {
                    let screen = camera.screenPoint(lat: point.lat, lon: point.lon, size: size)
                    if i == 0 { path.move(to: screen) } else { path.addLine(to: screen) }
                }
                path.closeSubpath()
                context.fill(path, with: .color(color(fromHex: cell.color).opacity(0.42)))
            }
        }
        .allowsHitTesting(false)
    }

    private func color(fromHex hex: String) -> Color {
        var value: UInt64 = 0
        Scanner(string: String(hex.dropFirst())).scanHexInt64(&value)
        return Color(red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255,
                     blue: Double(value & 255) / 255)
    }
}

// MARK: - Attribution (Kotlin Maps.kt:345-357, exact strings)

struct MapAttribution: View {
    let radar: Bool
    let temperature: Bool
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Link("© OpenStreetMap", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    .font(.system(size: compact ? 11 : 12))
                    .foregroundStyle(MapInk)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                if radar || temperature {
                    Link(radar ? "RainViewer" : "Open-Meteo",
                         destination: URL(string: radar ? "https://www.rainviewer.com" : "https://open-meteo.com")!)
                        .font(.system(size: 12))
                        .foregroundStyle(MapInk)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                }
            }
            Link("Dark map: OpenFreeMap · © OpenMapTiles",
                 destination: URL(string: "https://openmaptiles.org/")!)
                .font(.system(size: 11))
                .foregroundStyle(MapInk)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        }
    }
}
