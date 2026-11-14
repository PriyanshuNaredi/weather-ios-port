import Foundation
import Observation

// iOS port of the `MainActivity.kt` `WeatherApp` composable state (lines 89-128)
// and `rememberWeatherTime` (lines 285-295). Kotlin drives UI with Compose state
// + string screen routing; the iOS port uses @Observable MainActor state.
// Location permission flow (Kotlin lines 113-128) lands with Workstream C.
// (`Screen` routing lives in StabilityPolicies.swift so the pure logic-test
// package can pin the bottom-bar destination raw values.)

@MainActor
@Observable
final class WeatherViewModel {
    let repository: WeatherRepository & MapRepository
    /// Kotlin `displayTimeOverride` test seam (WeatherApp parameter, line 93).
    private let displayTimeOverride: Date?

    /// Kotlin `rememberWeatherTime` — display clock advancing every 30 s.
    private(set) var now: Int

    /// Kotlin `MainActivity.kt:94` — cities list drives the pager.
    private(set) var cities: [City] = []
    /// Kotlin line 95 — unit system from the repository (SharedPreferences / UserDefaults).
    private(set) var imperial: Bool
    /// Kotlin line 96 — screen routing string ("weather"/"map"/"cities"/"settings").
    private(set) var screen: Screen = .weather
    /// Kotlin line 97 — active metric detail sheet (Workstream D).
    private(set) var detail: (metric: Metric, date: String?)?
    /// Kotlin line 98 — per-city weather snapshots keyed by city id.
    private(set) var weatherByCity: [String: Weather] = [:]
    /// Kotlin line 99 — pager index. Parity (MainActivity.kt:104): this is a
    /// DERIVED value fed from the pager — `pagerMoved(to:)` is the single
    /// write path (Android: `LaunchedEffect(pager.currentPage)`). Pages are
    /// identified by city id (PagerPagePolicy); the id↔index conversion lives
    /// in the scrollPosition binding (ContentView).
    private(set) var currentIndex: Int = 0
    /// Kotlin line 100 — location status message (Workstream C).
    var locationMessage: String?
    /// Kotlin line 101.
    private(set) var locating = false

    /// Kotlin `lastWeather` (line 102) — snapshot for the currently visible city,
    /// projected to the display clock.
    var lastWeather: Weather? {
        guard let city = cities[safe: currentIndex], let weather = weatherByCity[city.id] else {
            return nil
        }
        return atTime(weather, now: now)
    }

    init(repository: WeatherRepository & MapRepository, displayTimeOverride: Date? = nil) {
        self.repository = repository
        self.displayTimeOverride = displayTimeOverride
        let start = displayTimeOverride.map { Int($0.timeIntervalSince1970) }
            ?? Int(Date().timeIntervalSince1970)
        now = start
        cities = repository.cities()
        imperial = repository.imperial
    }

    /// Kotlin `LaunchedEffect(lifecycle) repeatOnLifecycle(RESUMED) { … delay(30_000) }`
    /// — call from a `.task` on the root view; also run immediately on foreground.
    func startDisplayClock() async {
        while true {
            now = displayTimeOverride.map { Int($0.timeIntervalSince1970) }
                ?? Int(Date().timeIntervalSince1970)
            do { try await Task.sleep(nanoseconds: 30_000_000_000) }
            catch { break }   // task cancelled when the view disappears
        }
    }

    /// Kotlin line 105 — pager page change sync (the ONLY writer of
    /// `currentIndex`; programmatic scrolls after add/remove also go through
    /// here, mirroring Android's `pager.scrollToPage(...)` feeding back through
    /// `LaunchedEffect(pager.currentPage)`). Clamped via PagerIndexPolicy: a
    /// stale `scrollPosition` binding can fire after city removal with an
    /// out-of-range index; clamping keeps `currentIndex` a valid index.
    func pagerMoved(to index: Int) {
        let clamped = PagerIndexPolicy.clamp(index, count: cities.count)
        if clamped != index { Diag.event("pager index clamped \(index) -> \(clamped)") }
        if clamped != currentIndex { Diag.event("pager moved -> \(clamped)") }
        currentIndex = clamped
    }

    func navigate(to target: Screen) {
        Diag.event("navigate -> \(target.rawValue)")
        screen = target
    }

    /// Kotlin BackHandler (line 129): metric detail first, then back to weather.
    func back() {
        if detail != nil {
            Diag.event("back: closing detail")
            detail = nil
        } else if screen != .weather {
            Diag.event("back: \(screen.rawValue) -> weather")
            screen = .weather
        }
    }

    /// Kotlin `add(city)` (lines 106-112) — insert or replace by id, persist,
    /// close the city screen and page to the city.
    func add(city: City) {
        let old = cities.firstIndex { $0.id == city.id }
        if old == nil {
            cities = cities + [city]
        } else {
            let index = old!
            cities = cities.enumerated().map { i, c in i == index ? city : c }
        }
        repository.saveCities(cities)
        screen = .weather
        // Parity fix: route the programmatic page change through pagerMoved —
        // the single write path for currentIndex (Android scrollToPage feeding
        // back through LaunchedEffect(pager.currentPage)); direct assignment
        // here previously made index and pager position competing states.
        pagerMoved(to: old ?? cities.count - 1)
        Diag.event("city added/replaced count=\(cities.count) page=\(currentIndex)")
    }

    /// Kotlin lines 139-141 — remove city and persist. Re-clamping the pager
    /// position afterwards keeps currentIndex valid when the removed city sat
    /// at or before the current page (Android's pager auto-clamps by page key).
    func remove(city: City) {
        cities = cities.filter { $0.id != city.id }
        repository.saveCities(cities)
        pagerMoved(to: currentIndex)
        Diag.event("city removed count=\(cities.count)")
    }

    /// Kotlin line 142 — unit toggle persists through the repository.
    func setImperial(_ value: Bool) {
        Diag.event("units -> \(value ? "imperial" : "metric")")
        imperial = value
        repository.imperial = value
    }

    /// Kotlin `onLocation` permission launcher (lines 122-126): granted → locate,
    /// otherwise the exact denial message.
    func onLocationTapped() async {
        Diag.event("location tapped")
        if await LocationFinder.shared.ensureAuthorized() {
            await locate()
        } else {
            Diag.event("location denied by permission flow")
            locationMessage = "Location access is off. You can still search for any city."
        }
    }

    /// Kotlin `locate()` (lines 113-121) — 18 s timeout via `LocationFinder.locateOnce`,
    /// then insert the fixed `current-location` city or the exact failure message.
    /// Kotlin `locate()` (lines 113-121) — 18 s timeout via `LocationFinder.locateOnce`,
    /// then insert the fixed `current-location` city or the exact failure message.
    func locate() async {
        locating = true
        locationMessage = nil
        let result = await LocationFinder.shared.locateOnce()
        locating = false
        if result != nil {
            Diag.event("location resolved (coordinates not logged)")
        } else {
            Diag.event("location failed (timeout/unavailable)")
        }
        if let (latitude, longitude) = result {
            add(city: City(id: "current-location", name: "My Location", country: "",
                           latitude: latitude, longitude: longitude))
        } else {
            locationMessage = "Location is unavailable. Check location services or search for a city."
        }
    }

    /// Kotlin line 145 `onWeather` — cache the page snapshot for the shared state.
    func storeWeather(_ weather: Weather) {
        let isNew = weatherByCity[weather.city.id] == nil
        weatherByCity[weather.city.id] = weather
        if isNew { Diag.event("snapshot stored total=\(weatherByCity.count)") }
    }

    /// Kotlin lines 133-137 — open metric detail (Workstream D renders the screen).
    func openMetric(_ weather: Weather, _ metric: Metric, date: String? = nil) {
        Diag.event("open metric detail metric=\(metric.rawValue)")
        weatherByCity[weather.city.id] = weather
        detail = (metric, date)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Per-page forecast state (Kotlin `ForecastPage` composable state, lines 166-194)

/// Kotlin keeps per-page state inside `ForecastPage` (`weather`, `refreshing`,
/// `error`, `tick`); SwiftUI needs an observable page model per city.
@MainActor
@Observable
final class ForecastPageModel {
    let city: City
    private let repository: WeatherRepository & MapRepository

    private(set) var weather: Weather?
    private(set) var refreshing = false
    private(set) var error: String?
    /// Kotlin `tick` — bumps force a reload.
    private(set) var tick = 0

    /// Kotlin `onWeather` callback (MainActivity.kt:168) — forwards snapshots to
    /// the shared app state.
    private let onWeather: (Weather) -> Void

    init(city: City, repository: WeatherRepository & MapRepository,
         onWeather: @escaping (Weather) -> Void) {
        self.city = city
        self.repository = repository
        self.onWeather = onWeather
        weather = repository.cached(city: city)
        if let weather { onWeather(weather) }   // Kotlin `old?.let(onWeather)`
    }

    /// Kotlin `LaunchedEffect(city.id, lat, lon, tick)` (lines 180-189):
    ///  - seed with cached snapshot
    ///  - skip fetch when the cache is younger than 900 s on first load
    ///  - fetch fresh; exact error strings per line 187.
    func load(now: Int, isFirstLoad: Bool) async {
        let old = repository.cached(city: city)
        weather = old
        if isFirstLoad, let old, now - old.fetchedAt >= 0, now - old.fetchedAt < 900 {
            Diag.event("forecast cache-fresh skip age=\(now - old.fetchedAt)s")
            return
        }
        refreshing = true
        defer { refreshing = false }
        do {
            let fresh = try await repository.forecast(city: city)
            weather = fresh
            onWeather(fresh)
            error = nil
            Diag.event("forecast loaded days=\(fresh.days.count) hours=\(fresh.hours.count)")
        } catch {
            Diag.event("forecast load FAILED (cached=\(weather != nil))")
            self.error = weather != nil
                ? "Couldn’t refresh. Using saved forecast."
                : "Couldn’t load weather. Check your connection and retry."
        }
    }

    func retry() { tick += 1 }

    /// Kotlin `DisposableEffect` ON_RESUME check (lines 176-179): refresh trigger
    /// when the saved snapshot is 900 s or older.
    func refreshIfStale() {
        if let weather, Int(Date().timeIntervalSince1970) - weather.fetchedAt >= 900 {
            tick += 1
        }
    }
}
