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
                    onDiagnostics: { showDiagnostics = true },
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
        // Kotlin lines 159-160 — status-bar and navigation-bar scrims drawn OVER
        // the atmospheric sky so the system chrome stays legible. An overlay, not
        // a safeAreaInset: Kotlin reserves no layout space for them.
        .overlay {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    WeatherTheme.edgeScrim
                        .frame(height: proxy.safeAreaInsets.top)
                    Spacer(minLength: 0)
                    WeatherTheme.edgeScrim
                        .frame(height: proxy.safeAreaInsets.bottom)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
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

    // Kotlin lines 147-152 — bar `Row(background(Color(0xD9122E50)).padding(horizontal = 12.dp),
    // Arrangement.SpaceBetween)` holding three `IconButton`s (48 dp targets, no text
    // labels) with the page dots as the weighted middle. Icon colours come from
    // `onSurfaceVariant` (= Muted) and there is no selected-vs-unselected tint in
    // the Compose source; only the dots indicate the page. The iOS diagnostics
    // entry that used to sit here (crowding the Cities button) now lives in
    // Settings — it has no Android counterpart.
    private var bottomBar: some View {
        HStack(spacing: 0) {
            barButton("map", icon: "map", label: "Map")
            pageDots
            barButton("settings", icon: "slider.horizontal.3", label: "Settings")
            barButton("cities", icon: "list.bullet", label: "Cities")
        }
        .padding(.horizontal, 12)
        .background(WeatherTheme.bottomBar.ignoresSafeArea(edges: .bottom))
    }

    // Kotlin line 149: `Row(spacedBy(6.dp), weight(1f)) { Spacer(weight(1f)); dots; Spacer(weight(1f)) }`
    // 8 dp dots, Ink / Ink.copy(alpha=.35f), keyed by city id so they track the
    // same identity as the pager pages.
    private var pageDots: some View {
        HStack(spacing: 6) {
            Spacer(minLength: 0)
            ForEach(Array(viewModel.cities.enumerated()), id: \.element.id) { _, city in
                Circle()
                    .fill(city.id == viewModel.cities[safe: viewModel.currentIndex]?.id
                        ? WeatherTheme.ink : WeatherTheme.ink.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func barButton(_ screen: String, icon: String, label: String) -> some View {
        Button {
            Diag.event("nav bottom-bar tap -> \(screen)")
            if let target = Screen(rawValue: screen) {
                viewModel.navigate(to: target)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(WeatherTheme.muted)
                .frame(width: 48, height: 48)
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
