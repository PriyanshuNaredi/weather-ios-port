import SwiftUI

// iOS port of `MainActivity.kt:473-497 Sky` — the full-screen animated weather
// backdrop: day/night gradient, sun bloom or star field, falling rain/snow and
// three drifting cloud ovals. Compose uses an infinite transition (40 s cloud
// drift, 6 s precipitation fall); SwiftUI uses TimelineView-driven animation.
// Android also honors ANIMATOR_DURATION_SCALE == 0 (reduce motion); iOS maps
// this to `UIAccessibility.isReduceMotionEnabled` / `accessibilityReduceMotion`.

struct SkyView: View {
    let code: Int?
    let day: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static func color(_ hex: UInt32, alpha: Double = 1) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255,
              opacity: alpha)
    }

    private static let rainyCodes: Set<Int> = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
    private static let snowyCodes: Set<Int> = [71, 73, 75, 77, 85, 86]

    var body: some View {
        // Stability fix: `.animation` ticks at display refresh (60–120 Hz) and
        // this backdrop renders on EVERY pager page. Throttle to 30 fps and
        // pause entirely under Reduce Motion — same visual motion at a fraction
        // of the GPU/CPU load (Kotlin recomposed on a coarse state clock).
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { (timeline: TimelineViewDefaultContext) in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let dayColors = [Self.color(0x326C9F), Self.color(0x204E7B), Self.color(0x102D50)]
                let nightColors = [Self.color(0x101B3F), Self.color(0x0B1734), Self.color(0x060D24)]
                let gradient = Gradient(colors: day ? dayColors : nightColors)
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(day ? Self.color(0x326C9F) : Self.color(0x101B3F)))
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))

                let drift = reduceMotion ? 0 : CGFloat((now.truncatingRemainder(dividingBy: 80)) / 80)
                    .convertedDriftPhase() * size.width * 0.12
                let fall = reduceMotion ? 0.3 : CGFloat((now.truncatingRemainder(dividingBy: 6)) / 6)

                if day && [0, 1, 2].contains(code ?? -1) {
                    let bloomCenter = CGPoint(x: size.width * 0.8, y: size.height * 0.13)
                    let bloomRect = CGRect(x: bloomCenter.x - size.width * 0.5,
                                           y: bloomCenter.y - size.width * 0.5,
                                           width: size.width, height: size.width)
                    context.fill(Path(ellipseIn: bloomRect), with: .radialGradient(
                        Gradient(colors: [Self.color(0xFFE8B0, alpha: 0x44 / 255.0), .clear]),
                        center: bloomCenter, startRadius: 0, endRadius: size.width * 0.5))
                }

                if !day {
                    for i in 0..<32 {
                        let x = (CGFloat((i * 137) % 100) / 100) * size.width
                        let y = (CGFloat((i * 71) % 100) / 100) * size.height * 0.5
                        let radius = i % 3 == 0 ? 1.8 : 1.0
                        let starRect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: starRect), with: .color(WeatherTheme.ink.opacity(0.22)))
                    }
                }

                let rainy = Self.rainyCodes.contains(code ?? -1)
                let snowy = Self.snowyCodes.contains(code ?? -1)
                if rainy || snowy {
                    let count = rainy ? 42 : 28
                    for i in 0..<count {
                        let baseX = (CGFloat((i * 137) % 100) / 100) * size.width
                        let x = (baseX + fall * size.width * 0.08).truncatingRemainder(dividingBy: size.width)
                        let y = (((CGFloat((i * 71) % 100) / 100) + fall).truncatingRemainder(dividingBy: 1)) * size.height
                        if rainy {
                            var drop = Path()
                            drop.move(to: CGPoint(x: x, y: y))
                            drop.addLine(to: CGPoint(x: x - 5, y: y + 24))
                            context.stroke(drop, with: .color(Self.color(0x98CFFF, alpha: 0x22 / 255.0)),
                                           style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        } else {
                            let radius: CGFloat = i % 3 == 0 ? 3 : 2
                            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(WeatherTheme.ink.opacity(0.20)))
                        }
                    }
                }

                if code != 0 {
                    for i in 0..<3 {
                        let ovalRect = CGRect(
                            x: -size.width * 0.4 + drift + CGFloat(i) * size.width * 0.3,
                            y: size.height * (0.06 + CGFloat(i) * 0.11),
                            width: size.width * 1.1, height: size.height * 0.23)
                        let center = CGPoint(x: ovalRect.midX, y: ovalRect.midY)
                        context.fill(Path(ellipseIn: ovalRect), with: .radialGradient(
                            Gradient(colors: [WeatherTheme.ink.opacity(0.06), .clear]),
                            center: center, startRadius: 0,
                            endRadius: min(ovalRect.width, ovalRect.height) / 2))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private extension CGFloat {
    /// Kotlin `tween(40000, RepeatMode.Reverse)` — the drift value oscillates
    /// 0→1→0 over 40 s; expressed here as a triangle wave over 80 s.
    func convertedDriftPhase() -> CGFloat {
        self <= 0.5 ? self * 2 : (1 - self) * 2
    }
}
