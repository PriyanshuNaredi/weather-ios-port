import SwiftUI

// iOS port of `MainActivity.kt:166-282 ForecastPage` — the main weather screen:
// city header with current conditions, the "now" glass card with hourly strip,
// the 10-day forecast with gradient range bars, the 11 metric tiles, footer
// attribution, pull-to-refresh and the loading / error / empty states.
// Kotlin per-page state lives in `ForecastPageModel` (WeatherViewModel.swift).

struct ForecastPageView: View {
    @State private var model: ForecastPageModel
    let imperial: Bool
    let now: Int
    let onMetric: (Weather, Metric) -> Void
    let onMap: () -> Void
    /// Opens the saved-cities screen, whose search field adds a city. The Compose
    /// app has no add control on the forecast page, so this is an iOS addition —
    /// the bar's Cities button is the only other way in.
    let onAddCity: () -> Void
    /// Kotlin `showMapPreview` parameter — true when no repository override is
    /// provided (Kotlin line 166 default), which is every call site here.
    var showMapPreview: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var hasLoadedOnce = false
    /// Runtime-debugging instrumentation state (temporary).
    @State private var renderedRowsLogged = false
    /// Measured width for the metric tile grid (stability fix — a GeometryReader
    /// inside a ScrollView collapsed to ~10 pt under `.fixedSize(vertical:)`,
    /// corrupting layout and hit-testing; a PreferenceKey keeps the natural
    /// vertical sizing).
    @State private var gridWidth: CGFloat = 0

    init(city: City, repository: WeatherRepository & MapRepository, imperial: Bool,
         now: Int, onWeather: @escaping (Weather) -> Void,
         onMetric: @escaping (Weather, Metric) -> Void, onMap: @escaping () -> Void,
         onAddCity: @escaping () -> Void = {},
         showMapPreview: Bool = true) {
        _model = State(initialValue: ForecastPageModel(city: city, repository: repository, onWeather: onWeather))
        self.imperial = imperial
        self.now = now
        self.onMetric = onMetric
        self.onMap = onMap
        self.onAddCity = onAddCity
        self.showMapPreview = showMapPreview
    }

    private var snapshot: Weather? { model.weather }

    var body: some View {
        // Kotlin PullToRefreshBox (line 191) → SwiftUI .refreshable.
        Group {
            if snapshot == nil {
                unavailableView
            } else {
                content
            }
        }
        .refreshable { model.retry() }
        // Instrumentation: page lifecycle + scroll-gesture activity. The
        // simultaneous drag monitor reports whether drag gestures REACH this
        // page at all (distinguishes "gesture intercepted above" from
        // "gesture works but scroll doesn't move").
        .onAppear { Diag.event("forecast page appear") }
        // One-shot forward of the cached snapshot to the shared app state
        // (Kotlin `LaunchedEffect(city.id) { old?.let(onWeather) }`). Must not
        // live in ForecastPageModel.init — see the note there.
        .task { model.forwardInitialWeather() }
        .onDisappear { Diag.event("forecast page disappear") }
        // Stability fix: the previous `.simultaneousGesture(DragGesture)` diagnostic
        // monitor sat on the page alongside the pager's drag handling; even an
        // observing-only simultaneous drag competes with the paging ScrollView's
        // gesture recognition on device. It is instrumentation, not behavior —
        // removed so the vertical ScrollView and the horizontal pager are the only
        // gesture recognizers here.
        .task(id: "\(model.city.id)|\(model.tick)|\(hasLoadedOnce)") {
            await model.load(now: now, isFirstLoad: !hasLoadedOnce)
            hasLoadedOnce = true
        }
        // Kotlin 15-minute repeatOnLifecycle timer (lines 203-206).
        // Stability fix: `try?` swallowed CancellationError, so this loop never
        // exited when the page's task was cancelled (page swiped away / screen
        // switched) — a leaked per-page timer per city. Exit on cancellation.
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000) }
                catch { break }   // cancelled with the view
                model.retry()
            }
        }
        // Kotlin ON_RESUME stale check (lines 175-179).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshIfStale() }
        }
    }

    // Kotlin lines 192-201 — empty/loading/error state.
    private var unavailableView: some View {
        VStack(spacing: 20) {
            WeatherGlyph(code: 2, day: true, size: 88)
            Text(model.city.name).font(.system(size: 32))
            if model.refreshing {
                ProgressView().tint(WeatherTheme.ink)
                Text("Loading your forecast…").padding(16)
            } else {
                Text(model.error ?? "Weather is unavailable")
                    .multilineTextAlignment(.center)
                Button("Retry") { model.retry() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var content: some View {
        let snapshot = self.snapshot!
        let source = conditionSourceAt(snapshot, now: now)
        let w = atTime(snapshot, now: now)
        let today = w.days.first
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header(w)
                    // iOS-only add control, top-right of the header block. Inside
                    // the scrolling content so it never floats over rows.
                    .overlay(alignment: .topTrailing) {
                        Button(action: onAddCity) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(WeatherTheme.muted)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add city")
                        .padding(.trailing, 4)
                    }
                if let error = model.error { Notice(message: error) { model.retry() } }
                switch source {
                case .forecast:
                    GlassPanel {
                        Text("Estimated now · \(localTime(now, zone: w.timezone))")
                            .font(.system(size: 16, weight: .medium))
                        Text("From saved hourly forecast · Downloaded \(localTime(w.fetchedAt, zone: w.timezone, pattern: "MMM d, " + DisplayClock.pattern))")
                            .font(.system(size: 13))
                            .foregroundStyle(WeatherTheme.muted)
                            .padding(.top, 4)
                    }
                case .unavailable:
                    Notice(message: "Saved forecast doesn’t cover this time. Connect to update weather.") { model.retry() }
                case .current:
                    EmptyView()
                }
                nowCard(w)
                tenDay(w)
                metricTiles(w)
                // Instrumentation: log rendered day-row count once per data load
                // (Phase 1 "forecast item rendering" evidence).
                .onAppear {
                    if !renderedRowsLogged {
                        renderedRowsLogged = true
                        Diag.event("forecast content rendered days=\(w.days.count) tiles=\(Metric.allCases.count)")
                    }
                }
                // Kotlin line 263: `if(showMapPreview) WeatherMapPreview(...)`.
                if showMapPreview {
                    WeatherMapPreviewView(city: w.city, onOpen: onMap)
                }
                footer(w)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // Kotlin lines 210-220 — city name, country, giant temperature, condition, H/L.
    private func header(_ w: Weather) -> some View {
        let today = w.days.first
        return VStack(spacing: 2) {
            Text(w.city.name)
                .font(.system(size: 32, weight: .regular))
                .multilineTextAlignment(.center)
            if !w.city.country.isEmpty {
                Text(w.city.country)
                    .font(.system(size: 14))
                    .foregroundStyle(WeatherTheme.muted)
            }
            Text(temp(w.current.temperature, imperial: imperial))
                .font(.system(size: 100, weight: .ultraLight))
                // Kotlin pins lineHeight=112sp on the 100sp glyph; SwiftUI's default
                // line box is ~119, which pushed the condition/H-L block down. The
                // glyph is ~72pt tall, so a 112pt box crops nothing.
                .frame(height: 112)
                .accessibilityLabel("\(temp(w.current.temperature, imperial: imperial)) \(imperial ? "Fahrenheit" : "Celsius")")
            Text(condition(w.current.code))
                .font(.system(size: 22))
                .foregroundStyle(WeatherTheme.muted)
            Text("H:\(temp(today?.high, imperial: imperial))   L:\(temp(today?.low, imperial: imperial))")
                .font(.system(size: 20))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 22)
    }

    // Kotlin lines 222-244 — "today" summary, divider, hourly strip (≤48 entries).
    private func nowCard(_ w: Weather) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 0) {
                Text(todayLine(w))
                    .font(.system(size: 16))
                    .lineSpacing(6)
                Divider()
                    .overlay(WeatherTheme.ink.opacity(0.15))
                    .padding(.vertical, 12)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        let currentHour = forecastHourAt(w, now: now)?.copy(
                            time: now, temperature: w.current.temperature, code: w.current.code)
                        let hours = ([currentHour].compactMap { $0 } + w.hours.filter { $0.time > now }).prefix(48)
                        // Stability fix: id by enumeration offset — the "Now" pseudo-hour
                        // is synthesized with `time: now`, and a real forecast hour could
                        // carry the same timestamp, colliding under `id: \.time` and
                        // corrupting SwiftUI's identity for the strip.
                        ForEach(Array(hours.enumerated()), id: \.offset) { _, h in
                            VStack(spacing: 4) {
                                Text(hourLabel(h.time, zone: w.timezone))
                                    .font(.system(size: 15))
                                WeatherGlyph(code: h.code, day: isDayAt(time: h.time, w: w), size: 30)
                                if (h.precipitationProbability ?? 0) > 0 {
                                    Text("\((h.precipitationProbability).display())%")
                                        .font(.system(size: 12))
                                        .foregroundStyle(WeatherTheme.accent)
                                } else {
                                    Spacer().frame(height: 15)
                                }
                                Text(temp(h.temperature, imperial: imperial))
                                    .font(.system(size: 20))
                            }
                            .frame(minWidth: 42)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                            // Stability fix: no force unwrap — the tap closure may run
                            // after a refresh; nil simply ignores the tap.
                            .onTapGesture { if let s = snapshot { onMetric(s, .temperature) } }
                        }
                    }
                }
            }
        }
    }

    /// Kotlin `buildString` block (lines 225-229) — exact wording.
    private func todayLine(_ w: Weather) -> String {
        var line = "\(condition(w.current.code)) today."
        if let chance = w.days.first?.precipitationProbability {
            line += " Rain chance \(chance.display())%."
        }
        if let wind = w.current.wind {
            line += " Wind \(speed(wind, imperial: imperial))."
        }
        return line
    }

    /// Kotlin hourly label (line 237): "Now", else "HH" (24 h) or "ha" (12 h).
    private func hourLabel(_ epoch: Int, zone: String) -> String {
        if epoch == now { return "Now" }
        let pattern = DisplayClock.uses24Hour ? "HH" : "ha"
        return localTime(epoch, zone: zone, pattern: pattern)
    }

    // Kotlin lines 245-263 — 10-day list with gradient range bars.
    private func tenDay(_ w: Weather) -> some View {
        let min = w.days.compactMap { $0.low }.min() ?? 0.0
        let max = w.days.compactMap { $0.high }.max() ?? 1.0
        let todayKey = LocalDateKeys.dateKey(epoch: now, zone: w.timezone)
        return GlassPanel {
            VStack(alignment: .leading, spacing: 0) {
                PanelTitle(icon: "calendar", title: "10-DAY FORECAST")
                ForEach(Array(w.days.enumerated()), id: \.offset) { i, d in
                    if i > 0 {
                        Divider().overlay(WeatherTheme.ink.opacity(0.10))
                    }
                    HStack(spacing: 10) {
                        Text(d.date == todayKey ? "Today" : LocalDateKeys.weekdayLabel(d.date))
                            .font(.system(size: 18))
                            .frame(width: 54, alignment: .leading)
                        VStack(spacing: 1) {
                            WeatherGlyph(code: d.code, day: true, size: 26)
                            if (d.precipitationProbability ?? 0) > 0 {
                                Text("\((d.precipitationProbability).display())%")
                                    .font(.system(size: 11))
                                    .foregroundStyle(WeatherTheme.accent)
                            }
                        }
                        Text(temp(d.low, imperial: imperial))
                            .font(.system(size: 17))
                            .foregroundStyle(WeatherTheme.muted)
                            .frame(minWidth: 32, alignment: .trailing)
                        RangeBar(low: d.low, high: d.high, min: min, max: max)
                            .frame(height: 8)
                            .accessibilityLabel("Low \(temp(d.low, imperial: imperial)), high \(temp(d.high, imperial: imperial))")
                        Text(temp(d.high, imperial: imperial))
                            .font(.system(size: 17))
                            .frame(minWidth: 32, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    // Stability fix: no force unwrap (tap may land after a refresh).
                    .onTapGesture {
                        if let s = snapshot {
                            onMetric(s, Metric.temperature.copyForDate(d.date).0)
                        }
                    }
                }
            }
        }
    }

    // Kotlin lines 264-279 — metric tile grid; column count by width + type size.
    // Stability fix: width comes from a PreferenceKey measurement instead of a
    // GeometryReader (which collapsed to ~10 pt tall inside the vertical
    // ScrollView and pushed everything below it out of reach — the "cannot
    // scroll to later days / tiles" symptom).
    private func metricTiles(_ w: Weather) -> some View {
        let columns = gridWidth > 600 ? 3
            : (gridWidth > 330 && !typeSize.isAccessibilitySize ? 2 : 1)
        let chunks = stride(from: 0, to: Metric.allCases.count, by: columns)
            .map { Array(Metric.allCases[$0..<min($0 + columns, Metric.allCases.count)]) }
        return VStack(alignment: .leading, spacing: 12) {
            // `Grid` equalises each row to its tallest cell and lets cells fill that
            // height, so the cards line up without reserving (and truncating) summary
            // text — Kotlin's Row leaves the cards ragged instead.
            Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { _, row in
                    GridRow(alignment: .top) {
                        ForEach(row) { m in
                            // `maxHeight` is what makes the cards equal: `Grid`
                            // proposes the row's tallest height to every cell, and a
                            // frame that ignores the vertical proposal (maxWidth only)
                            // keeps each card at its own content height.
                            tile(m, w)
                                .frame(maxWidth: .infinity, maxHeight: .infinity,
                                       alignment: .topLeading)
                        }
                        if row.count < columns {
                            Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                        }
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: MetricGridWidthKey.self,
                    value: geo.size.width)
            }
        )
        .onPreferenceChange(MetricGridWidthKey.self) { newWidth in
            // Layout-loop guard. `columns` is derived from this measured width,
            // so a sub-point change across the 330 pt threshold re-lays out the
            // grid, which re-measures, which flips the column count again — an
            // infinite SwiftUI invalidation loop (observed on the iOS 24A3351
            // simulator: main thread pinned at 100% in
            // ViewGraphDelegate.updateGraph, XCTest accessibility snapshots
            // timing out, and the forecast unusable after scrolling to the grid).
            // Quantising to 10 pt plus a 10 pt dead band makes the measurement
            // settle: tiny rounding differences can no longer change the result.
            let quantised = (newWidth / 10).rounded() * 10
            if abs(quantised - gridWidth) >= 10 { gridWidth = quantised }
        }
    }

    /// Width of the metric-tile grid, measured without stealing vertical space.
    private struct MetricGridWidthKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    private func tile(_ m: Metric, _ w: Weather) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 0) {
                PanelTitle(icon: m.iconName, title: m.rawValue.uppercased())
                Text(metricValue(m, w, imperial))
                    .font(.system(size: 30, weight: .regular))
                    .padding(.top, 6)
                Text(metricSummary(m, w, imperial))
                    .font(.system(size: 14))
                    .lineSpacing(5)
                    .foregroundStyle(WeatherTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            // `maxHeight` lets the card fill the Grid row's height; a minHeight-only
            // frame returns the content's own height and ignores the taller proposal,
            // which is why the cards stayed ragged. Bounded here: the Grid row is the
            // source of the proposal.
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 136, maxHeight: .infinity,
                   alignment: .topLeading)
        }
        .contentShape(Rectangle())
        // Stability fix: no force unwrap (tap may land after a refresh).
        .onTapGesture { if let s = snapshot { onMetric(s, m) } }
    }

    // Kotlin lines 280-282 — attribution footer + source link.
    private func footer(_ w: Weather) -> some View {
        VStack(spacing: 4) {
            Text("Downloaded \(localTime(w.fetchedAt, zone: w.timezone, pattern: "MMM d, " + DisplayClock.pattern)) · \(w.timezone.replacingOccurrences(of: "_", with: " "))\nForecast & air quality: Open-Meteo / CAMS\nCurrent conditions and air quality are model estimates.")
                .font(.system(size: 12))
                .lineSpacing(5)
                .foregroundStyle(WeatherTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            Link(destination: URL(string: "https://open-meteo.com/")!) {
                Text("Weather data sources")
                    .foregroundStyle(WeatherTheme.muted)
            }
        }
    }
}

// MARK: - Day range bar (Kotlin inline Canvas, lines 256-261)

/// Track (Ink 0.12, round cap) plus a teal→amber gradient segment for the
/// low..high band; `right` never sits below `left + 0.02` of the width.
struct RangeBar: View {
    let low: Double?
    let high: Double?
    let min: Double
    let max: Double

    private let teal = Color(red: 0x7B / 255, green: 0xD9 / 255, blue: 0xCF / 255)
    private let amber = Color(red: 0xFF / 255, green: 0xD1 / 255, blue: 0x7B / 255)

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            // Round caps are half a stroke wide, so drawing them flush to the
            // Canvas edges clipped the cap flat — visible on the day whose range
            // reaches the scale maximum (Thursday). Inset every endpoint by the
            // cap radius so both ends stay round.
            let radius = size.height / 2
            let x0 = radius
            let x1 = Swift.max(size.width - radius, x0)
            var track = Path()
            track.move(to: CGPoint(x: x0, y: midY))
            track.addLine(to: CGPoint(x: x1, y: midY))
            context.stroke(track, with: .color(WeatherTheme.ink.opacity(0.12)),
                           style: StrokeStyle(lineWidth: size.height, lineCap: .round))
            guard let low, let high,
                  let (left, right) = RangeSpan.band(low: Double(low), high: Double(high),
                                                     min: Double(min), max: Double(max)) else { return }
            var band = Path()
            band.move(to: CGPoint(x: x0 + (x1 - x0) * CGFloat(left), y: midY))
            band.addLine(to: CGPoint(x: x0 + (x1 - x0) * CGFloat(right), y: midY))
            context.stroke(band, with: .linearGradient(
                Gradient(colors: [teal, amber]),
                startPoint: CGPoint(x: 0, y: midY), endPoint: CGPoint(x: size.width, y: midY)),
                style: StrokeStyle(lineWidth: size.height, lineCap: .round))
        }
    }
}
