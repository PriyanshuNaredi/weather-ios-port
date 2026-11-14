// TEMPLATE FILE OVERWRITTEN — the Workstream B root view (documented per
// project rule 7). This is the iOS port of `MainActivity.kt:89-162 WeatherApp`:
// full-screen sky backdrop, screen routing, the HorizontalPager over saved
// cities (TabView .page), the bottom navigation bar with page dots, edge scrims
// and the metric-detail / sub-screen switching.
//
// Placeholder stubs below (map / cities / settings screens) are replaced by
// Workstreams C / E / F; the metric detail screen is Workstream D.

import SwiftUI

struct WeatherRootView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var viewModel: WeatherViewModel?

    var body: some View {
        Group {
            if let viewModel {
                WeatherAppView(viewModel: viewModel)
            } else {
                // Kotlin builds cities in composition (line 90); iOS needs one
                // MainActor pass before the view model exists.
                WeatherTheme.background
                    .ignoresSafeArea()
                    .task {
                        if viewModel == nil { viewModel = WeatherViewModel(repository: app.repository) }
                    }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct WeatherAppView: View {
    @State var viewModel: WeatherViewModel

    var body: some View {
        WeatherMainView(viewModel: viewModel)
            .task { await viewModel.startDisplayClock() }   // rememberWeatherTime
    }
}

// MARK: - WeatherApp body (Kotlin MainActivity.kt:130-162)

private struct WeatherMainView: View {
    @State var viewModel: WeatherViewModel
    /// TEMPORARY diagnostics overlay (runtime-debugging mission) — full-screen
    /// cover so it can never affect the app's own hit-testing or layout.
    @State private var showDiagnostics = false

    var body: some View {
        ZStack {
            // Kotlin lines 151-153: sky behind the current snapshot.
            if let w = viewModel.lastWeather {
                SkyView(code: w.current.code, day: w.current.isDay)
            } else {
                WeatherTheme.background.ignoresSafeArea()
            }

            switch viewModel.screen {
            case .weather:
                // Kotlin line 138: `screen=="cities" || cities.isEmpty()` → CityScreen.
                if viewModel.cities.isEmpty {
                    cityScreen
                } else {
                    weatherPager
                }
            case .map:
                // Kotlin line 137: `WeatherMap(resolved?.city?.copy(timezone =
                // resolved.timezone) ?: selected, repository as? MapRepository
                // ?: remember { OpenWeatherRepository() }, imperial) { screen="weather" }`.
                // The iOS repository is always a MapRepository (OpenWeatherRepository),
                // so the Kotlin fallback branch is unreachable here; the current
                // city's timezone is overridden by the loaded weather's zone.
                if let city = viewModel.cities[safe: viewModel.currentIndex] {
                    let resolved = viewModel.lastWeather
                    let mapCity = resolved.map { City(id: city.id, name: city.name, country: city.country,
                                                      latitude: city.latitude, longitude: city.longitude,
                                                      timezone: $0.timezone) } ?? city
                    WeatherMapView(
                        city: mapCity,
                        repository: viewModel.repository,
                        imperial: viewModel.imperial,
                        onClose: { viewModel.back() })
                } else {
                    PlaceholderScreen(title: "Radar", viewModel: viewModel)
                }
            case .cities:
                cityScreen
            case .settings:
                // Kotlin line 142: SettingsScreen(imperial, onImperial) { screen="weather" }.
                SettingsScreenView(
                    imperial: viewModel.imperial,
                    onImperial: { viewModel.setImperial($0) },
                    onClose: { viewModel.back() })
            }

            // Kotlin metric detail gate (lines 134-137): `detail != null &&
            // lastWeather != null` renders the detail screen OVER the current
            // city's snapshot. Stability fix: this was previously attached as
            // `.background(detailGate)` — behind the ZStack, so the metric
            // detail never appeared and looked like a dead button.
            if let detail = viewModel.detail, let weather = viewModel.lastWeather {
                    MetricScreenView(
                        metric: detail.metric,
                        weather: weather,
                        imperial: viewModel.imperial,
                        initialDate: detail.date,
                        onClose: { viewModel.back() })
            }
        }
        .preferredColorScheme(.dark)
        // Runtime-debugging instrumentation (Phase 1): lifecycle + navigation
        // transitions. No coordinates or city names — screen names only.
        .onAppear { Diag.event("main view appear") }
        .onDisappear { Diag.event("main view disappear") }
        .onChange(of: viewModel.screen) { _, new in
            Diag.event("nav screen -> \(new.rawValue)")
        }
        .onChange(of: viewModel.cities.count) { _, count in
            Diag.event("cities count -> \(count)")
        }
        .onChange(of: viewModel.currentIndex) { _, index in
            Diag.event("pager index -> \(index)")
        }
        .fullScreenCover(isPresented: $showDiagnostics) {
            DiagnosticsScreenView { showDiagnostics = false }
        }
    }

    // Kotlin lines 138-141 — the city screen (Workstream C) with the exact
    // WeatherApp wiring: onLocation → permission flow, onAdd/onRemove/onClose.
    private var cityScreen: some View {
        CityScreenView(
            cities: viewModel.cities,
            repository: viewModel.repository,
            message: viewModel.locationMessage,
            locating: viewModel.locating,
            onLocation: { await viewModel.onLocationTapped() },
            onAdd: { viewModel.add(city: $0) },
            onRemove: { viewModel.remove(city: $0) },
            onClose: { viewModel.back() })
    }

    // Kotlin lines 142-150 — the pager over saved cities. Stability fix: the
    // previous TabView(.page) nesting inside the vertical forecast ScrollViews
    // made vertical scrolling fight the pager on device; the iOS 17 paging
    // ScrollView below is a single horizontal axis with per-page paging
    // behavior, so each page's vertical ScrollView is the only vertical
    // scroller (clear scrolling hierarchy, no nested vertical ScrollViews).
    //
    // Parity fix (REA mission, ANDROID_IOS_PARITY.md §6.1–6.2):
    //  - Page identity is the stable CITY ID (`ForEach(cities, id: \.id)`),
    //    exactly like Android `HorizontalPager(key={cities[it].id})` — adding,
    //    removing or reordering cities never rebinds another page's state.
    //  - The pager's actual position is the single source of truth. The
    //    `scrollPosition` binding speaks city ids: the set side converts the
    //    pager-reported id to the derived index through
    //    `WeatherViewModel.pagerMoved` (the ONLY writer of `currentIndex`,
    //    mirroring `LaunchedEffect(pager.currentPage)`); the get side converts
    //    back for programmatic scrolls. No mirrored index state.
    //
    // Parity fix (§6.3, bottom bar): Android renders the bar as a Row sibling
    // AFTER the pager inside the same Column — it can never be occluded. The
    // bar is therefore attached as `.safeAreaInset(edge: .bottom)`: a layout
    // sibling whose area page content always avoids, not an overlay.
    private var weatherPager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.cities, id: \.id) { city in
                    ForecastPageHost(city: city, viewModel: viewModel)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { PagerPagePolicy.pageID(at: viewModel.currentIndex, in: viewModel.cities) },
            set: { id in
                guard let id,
                      let index = PagerPagePolicy.index(for: id, in: viewModel.cities) else { return }
                viewModel.pagerMoved(to: index)
            }))
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    // Kotlin lines 155-161 — bottom bar buttons and page dots (Kotlin order:
    // map | page dots | settings | cities).
    private var bottomBar: some View {
        HStack(spacing: 8) {
            barButton("map", icon: "map", label: "Map", active: viewModel.screen == .map)
            Spacer()
            // Kotlin page indicator dots (line 148). Parity: Android highlights
            // `pager.currentPage`, not app state — the accent dot is derived
            // from the pager-fed `currentIndex`. Dots are keyed by city id so
            // they track the same identity as the pager pages themselves.
            if viewModel.cities.count > 1 {
                HStack(spacing: 6) {
                    ForEach(Array(viewModel.cities.enumerated()), id: \.element.id) { i, city in
                        Circle()
                            .fill(city.id == viewModel.cities[safe: viewModel.currentIndex]?.id
                                ? WeatherTheme.accent : WeatherTheme.ink.opacity(0.30))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            Spacer()
            barButton("settings", icon: "gearshape", label: "Settings", active: viewModel.screen == .settings)
            barButton("cities", icon: "location", label: "Cities", active: viewModel.screen == .cities)
            // TEMPORARY diagnostics entry point (runtime-debugging mission).
            Button {
                Diag.event("diag screen opened")
                showDiagnostics = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(WeatherTheme.ink.opacity(0.45))
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Diagnostics")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(WeatherTheme.bottomBar.ignoresSafeArea(edges: .bottom))
    }

    private func barButton(_ screen: String, icon: String, label: String, active: Bool) -> some View {
        Button {
            Diag.event("nav bottom-bar tap -> \(screen)")
            if let target = Screen(rawValue: screen) {
                viewModel.navigate(to: target)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                Text(label).font(.system(size: 10))
            }
            .foregroundStyle(active ? WeatherTheme.accent : WeatherTheme.ink.opacity(0.7))
            .padding(6)
            // Navigation fix: an explicit content shape guarantees the whole
            // padded area is tappable (a label-only hit area can miss taps on
            // device when the glyph view reports a near-zero hit region).
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Forecast page host

/// One pager page. `@State` keeps a `ForecastPageModel` per city; recreated when
/// the city changes (Kotlin `remember(city.id)`).
private struct ForecastPageHost: View {
    let city: City
    @State var viewModel: WeatherViewModel

    var body: some View {
        // Phase-4 diagnostic configuration: `diag.mapPreviews` (Diagnostics
        // screen, presets A/B) disables the map preview card on the forecast
        // page without removing the feature from the codebase.
        ForecastPageView(
            city: city,
            repository: viewModel.repository,
            imperial: viewModel.imperial,
            now: viewModel.now,
            onWeather: { viewModel.storeWeather($0) },
            onMetric: { weather, metric in
                viewModel.openMetric(weather, metric)
            },
            onMap: { viewModel.navigate(to: .map) },
            showMapPreview: DebugConfig.mapPreviews)
    }
}

// MARK: - Workstream placeholders (replaced by C / D / E / F)

struct PlaceholderScreen: View {
    let title: String
    @State var viewModel: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenHeader(title: title) { viewModel.back() }
            Spacer()
            Text("Ported in a later workstream.")
                .foregroundStyle(WeatherTheme.muted)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WeatherTheme.background.ignoresSafeArea())
    }
}

struct MetricDetailPlaceholder: View {
    @State var viewModel: WeatherViewModel
    let metric: Metric
    let date: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenHeader(title: metric.rawValue) { viewModel.back() }
            Spacer()
            Text("Metric detail ported in Workstream D.")
                .foregroundStyle(WeatherTheme.muted)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WeatherTheme.background.ignoresSafeArea())
    }
}
