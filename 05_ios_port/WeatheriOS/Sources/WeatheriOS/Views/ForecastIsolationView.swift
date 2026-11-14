import SwiftUI

#if DEBUG

// Forecast-scroll self-test (crash/navigation/scroll mission, Phase 4) — the
// mission-required isolated forecast-scrolling screen, tested independently of
// the full application. Reproduces the exact layout combination the forecast
// page uses: a vertical ScrollView per page, nested in the horizontal paging
// ScrollView over cities, with tall content that must scroll vertically AND
// page horizontally without either gesture blocking the other.
//
// Structure mirrors ContentView.weatherPager + ForecastPageView:
//   horizontal ScrollView(.horizontal) + LazyHStack + scrollTargetLayout +
//   .scrollTargetBehavior(.paging) + .scrollPosition(id: Int)   →  pages
//     each page: ScrollView(.vertical) with 60 rows             →  content
// plus the same single-identity ForEach (indices, id: \.self) the fix
// introduced. Evidence events log vertical drags, page changes and row taps.

struct ForecastIsolationView: View {
    @State private var pageIndex = 0
    @State private var lastEvent = "—"
    @State private var rowsTapped = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    Diag.event("scrolltest back tapped")
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(WeatherTheme.ink)
                        .padding(12)
                }
                .accessibilityLabel("Back")
                Text("Scroll self-test")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WeatherTheme.ink)
                Spacer()
            }
            .padding(.horizontal, 4)

            Text("Page \(pageIndex + 1) of 3 · rows tapped: \(rowsTapped) · last: \(lastEvent)")
                .font(.system(size: 12))
                .foregroundStyle(WeatherTheme.muted)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Horizontal city pager — identical structure to weatherPager.
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        TestPage(index: index) {
                            lastEvent = "row tapped"
                            rowsTapped += 1
                            Diag.event("scrolltest row tapped page=\(index)")
                        }
                        .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding(
                get: { pageIndex },
                set: { next in
                    if let next, next != pageIndex {
                        pageIndex = next
                        lastEvent = "paged to \(next + 1)"
                        Diag.event("scrolltest paged -> \(next)")
                    }
                }))
            .ignoresSafeArea(edges: .bottom)
        }
        .padding(.top, 8)
        .background(WeatherTheme.background.ignoresSafeArea())
        .onAppear { Diag.event("scrolltest screen appear") }
    }
}

/// One pager page: a vertical ScrollView with 60 real, tappable rows —
/// tall enough that reaching the last row requires genuine touch scrolling.
private struct TestPage: View {
    let index: Int
    let onRowTap: () -> Void

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                Text("Page \(index + 1) — swipe vertically to row 60, horizontally to another page")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WeatherTheme.muted)
                    .padding(.top, 12)
                ForEach(1...60, id: \.self) { n in
                    Button {
                        onRowTap()
                    } label: {
                        HStack {
                            Text("Row \(n)")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundStyle(WeatherTheme.muted)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(WeatherTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}
#endif
