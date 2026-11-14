import SwiftUI

// iOS port of `MainActivity.kt:387-397 Chart` — the hourly metric line chart:
// Min/Max labels, four horizontal gridlines (Ink alpha 0.12) and an Accent
// polyline (4 pt, round caps) over the hourly values; null values break the
// line, matching the Kotlin `previous = null` reset.

struct ChartView: View {
    let values: [Double?]
    /// Kotlin passes `height(180.dp)` in MetricScreen; the default matches the
    /// parameterless Chart call sites.
    var height: CGFloat = 120

    private var low: Double? { values.compactMap { $0 }.min() }
    private var high: Double? { values.compactMap { $0 }.max() }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(low.map { "Min \($0.display(decimals: 1))" } ?? "Min —")
                    .font(.system(size: 12))
                    .foregroundStyle(WeatherTheme.muted)
                Spacer()
                Text(high.map { "Max \($0.display(decimals: 1))" } ?? "Max —")
                    .font(.system(size: 12))
                    .foregroundStyle(WeatherTheme.muted)
            }
            Canvas { context, size in
                let count = max(values.count - 1, 1)
                let range = max((high ?? 1.0) - (low ?? 0.0), 1.0)
                // Kotlin semantics: empty/one-sided data still normalizes with
                // low=0/high=1 defaults carried from the valid values.
                let lowValue = low ?? 0.0
                for i in 0..<4 {
                    let y = size.height * CGFloat(i) / 3
                    var grid = Path()
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(grid, with: .color(WeatherTheme.ink.opacity(0.12)), lineWidth: 1)
                }
                var previous: CGPoint?
                for (i, value) in values.enumerated() {
                    guard let value else { previous = nil; continue }
                    let point = CGPoint(x: size.width * CGFloat(i) / CGFloat(count),
                                        y: size.height * (1 - CGFloat((value - lowValue) / range)))
                    if let from = previous {
                        var line = Path()
                        line.move(to: from)
                        line.addLine(to: point)
                        context.stroke(line, with: .color(WeatherTheme.accent),
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                    previous = point
                }
            }
            .frame(height: height)
            .accessibilityLabel(chartDescription)
        }
    }

    /// Kotlin `contentDescription` (line 390) — exact wording.
    private var chartDescription: String {
        guard let low, let high else { return "No data" }
        return "Forecast chart. Minimum \(low.display(decimals: 1)), maximum \(high.display(decimals: 1)). Hourly values below."
    }
}
