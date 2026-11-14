import SwiftUI

// iOS port of `MainActivity.kt:350-376 MetricScreen` — the per-metric detail
// screen: big current value + summary, a date chip row, the hourly Chart,
// the hourly value list, and the Sun / Air-quality variants with attribution.
// Kotlin resets `Metric.selectedDate` on dispose; here the selected date is
// plain view state seeded from the opened detail tuple.

struct MetricScreenView: View {
    let metric: Metric
    let weather: Weather
    let imperial: Bool
    let initialDate: String?
    let onClose: () -> Void

    @State private var date: String?

    var body: some View {
        MetricScreenBody(metric: metric, weather: weather, imperial: imperial,
                         initialDate: initialDate, onClose: onClose,
                         date: $date)
    }
}

private struct MetricScreenBody: View {
    let metric: Metric
    let weather: Weather
    let imperial: Bool
    let initialDate: String?
    let onClose: () -> Void
    @Binding var date: String?

    // Kotlin `var date by remember(metric)` (line 353): seeded from the opened
    // detail date or the first forecast day; re-seeded per metric identity.
    var body: some View {
        MetricScreenContent(metric: metric, weather: weather, imperial: imperial,
                            selectedDate: dateBinding, onClose: onClose)
            .task(id: metric.rawValue) {
                date = initialDate ?? weather.days.first?.date
            }
    }

    private var dateBinding: Binding<String?> {
        Binding(
            get: {
                // Kotlin `displayedDate` (line 354): the selection only counts
                // when it exists among the forecast days.
                if let date, weather.days.contains(where: { $0.date == date }) { return date }
                return weather.days.first?.date
            },
            set: { date = $0 })
    }
}

private struct MetricScreenContent: View {
    let metric: Metric
    let weather: Weather
    let imperial: Bool
    let selectedDate: Binding<String?>
    let onClose: () -> Void

    // Kotlin `hours` filter (line 355) — hours whose local calendar date equals
    // the displayed date.
    private var displayedDate: String? { selectedDate.wrappedValue }

    private var hours: [Hour] {
        guard let displayedDate else { return [] }
        return weather.hours.filter {
            LocalDateKeys.dateKey(epoch: $0.time, zone: weather.timezone) == displayedDate
        }
    }

    // Kotlin `value(h)` (line 356) — raw hourly metric, with the visibility
    // unit division applied inside value() exactly as Kotlin does.
    private func rawValue(_ h: Hour) -> Double? {
        switch metric {
        case .temperature: return h.temperature
        case .feels: return h.feelsLike
        case .rain: return h.precipitation
        case .wind: return h.wind
        case .humidity: return h.humidity
        case .dew: return h.dewPoint
        case .uv: return h.uv
        case .visibility: return h.visibility.map { $0 / (imperial ? 1609.344 : 1000.0) }
        case .pressure: return h.pressure
        case .sun, .air: return nil
        }
    }

    // Kotlin chart-point conversion (lines 363-364).
    private func chartPoint(_ h: Hour) -> Double? {
        guard let v = rawValue(h) else { return nil }
        switch metric {
        case .temperature, .feels, .dew: return imperial ? v * 9 / 5 + 32 : v
        case .wind: return imperial ? v / 1.609344 : v
        case .rain: return imperial ? v / 25.4 : v
        case .pressure: return imperial ? v * 0.029529983 : v
        default: return v
        }
    }

    // Kotlin list-row right-hand text (lines 368-370).
    private func rowValue(_ h: Hour) -> String {
        switch metric {
        case .temperature, .feels, .dew: return temp(rawValue(h), imperial: imperial)
        case .wind: return speed(rawValue(h), imperial: imperial)
        case .rain:
            guard let v = rawValue(h) else { return "—" }
            return imperial ? "\((v / 25.4).display(decimals: 2)) in" : "\(v.display(decimals: 1)) mm"
        case .humidity:
            guard let v = rawValue(h) else { return "—" }
            return "\(v.display())%"
        case .pressure:
            guard let v = rawValue(h) else { return "—" }
            return imperial ? "\((v * 0.029529983).display(decimals: 2)) inHg" : "\(v.display()) hPa"
        case .visibility:
            return "\(rawValue(h).display(decimals: 1)) \(imperial ? "mi" : "km")"
        default:
            return rawValue(h).display(decimals: 1)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: metric.rawValue, onClose: onClose)
                GlassPanel {
                    Text(metricValue(metric, weather, imperial))
                        .font(.system(size: 44))
                    Text(metricSummary(metric, weather, imperial))
                        .font(.system(size: 16))
                        .lineSpacing(6)
                }
                if metric != .sun && metric != .air {
                    chartSection
                } else if metric == .sun {
                    sunSection
                } else {
                    airSection
                }
                attribution
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(WeatherTheme.background.ignoresSafeArea())
    }

    // Kotlin lines 358-367 — date chips, chart glass, hourly list glass.
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(weather.days, id: \.date) { day in
                        chip(for: day)
                    }
                }
            }
            GlassPanel {
                Text("\(displayedDate ?? "Today") · \(weather.city.name)")
                    .font(.system(size: 18))
                Text("\(metric.rawValue) · \(weather.timezone)")
                    .font(.system(size: 13))
                    .foregroundStyle(WeatherTheme.muted)
                let points = hours.map { chartPoint($0) }
                ChartView(values: points, height: 180)
                    .padding(.top, 22)
                    .padding(.bottom, 12)
                HStack {
                    if !hours.isEmpty {
                        // Kotlin lines 366: 0, size/3, 2*size/3, lastIndex — distinct.
                        ForEach([0, hours.count / 3, hours.count * 2 / 3, hours.count - 1].distinct, id: \.self) { i in
                            Text(localTime(hours[i].time, zone: weather.timezone))
                                .font(.system(size: 12))
                                .foregroundStyle(WeatherTheme.muted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if points.allSatisfy({ $0 == nil }) {
                    Text("No forecast values available for this day.")
                        .padding(.top, 16)
                }
            }
            GlassPanel {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hours, id: \.time) { h in
                        HStack {
                            Text(localTime(h.time, zone: weather.timezone))
                                .foregroundStyle(WeatherTheme.muted)
                            Spacer()
                            Text(rowValue(h))
                        }
                        .padding(.vertical, 7)
                    }
                }
            }
        }
    }

    // Kotlin FilterChip (line 359).
    private func chip(for day: Day) -> some View {
        let isSelected = displayedDate == day.date
        return Button {
            selectedDate.wrappedValue = day.date
        } label: {
            Text(String(day.date.suffix(5)))
                .font(.system(size: 14))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? WeatherTheme.onAccent : WeatherTheme.ink.opacity(0.8))
                .background(isSelected ? WeatherTheme.accent : WeatherTheme.ink.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.date)
    }

    // Kotlin lines 371-373 — the sunrise/sunset variant.
    private var sunSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(weather.days, id: \.date) { d in
                    Text("\(d.date)\nSunrise \(d.sunrise.map { localTime($0, zone: weather.timezone) } ?? "Unavailable")   ·   Sunset \(d.sunset.map { localTime($0, zone: weather.timezone) } ?? "Unavailable")")
                        .lineSpacing(8)
                        .padding(.vertical, 10)
                }
            }
        }
    }

    // Kotlin lines 374-375 — the air-quality variant.
    private var airSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("European AQI: \((weather.air?.europeanAqi).display())\nUS AQI: \((weather.air?.usAqi).display())\nPM2.5: \((weather.air?.pm25).display(decimals: 1)) µg/m³\nPM10: \((weather.air?.pm10).display(decimals: 1)) µg/m³")
                    .lineSpacing(10)
                Text(weather.air.map { "Model valid time \(localTime($0.time, zone: weather.timezone))" }
                     ?? "Air quality is currently unavailable.")
                    .foregroundStyle(WeatherTheme.muted)
            }
        }
    }

    // Kotlin lines 376 — attribution link, URL depends on the metric.
    private var attribution: some View {
        Link(metric == .air ? "CAMS air quality via Open-Meteo" : "Weather data by Open-Meteo",
             destination: URL(string: metric == .air
                 ? "https://open-meteo.com/en/docs/air-quality-api"
                 : "https://open-meteo.com/")!)
            .font(.system(size: 14))
            .foregroundStyle(WeatherTheme.muted)
    }
}

private extension Array where Element == Int {
    /// Kotlin `distinct()` on the four chart tick indices.
    var distinct: [Int] {
        var seen = Set<Int>()
        return filter { seen.insert($0).inserted }
    }
}
