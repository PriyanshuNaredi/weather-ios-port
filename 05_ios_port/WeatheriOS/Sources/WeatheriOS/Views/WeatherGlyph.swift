import SwiftUI

// iOS port of `MainActivity.kt:449-472 WeatherGlyph` — the hand-drawn Compose
// Canvas weather glyphs (sun rays / moon, cloud blobs, rain streaks, lightning
// bolt, snow dots, fog lines, unknown ring) redrawn with SwiftUI Canvas.
// Geometry, colors, and code classification follow the Kotlin source exactly.

struct WeatherGlyph: View {
    let code: Int?
    let day: Bool
    var size: CGFloat = 32

    private static let rainyCodes: Set<Int> = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
    private static let snowyCodes: Set<Int> = [71, 73, 75, 77, 85, 86]

    private static func color(_ hex: UInt32, alpha: Double = 1) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255,
              opacity: alpha)
    }

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let ink = WeatherTheme.ink
            let muted = WeatherTheme.muted
            let cloudy = code != 0 && code != 1
            let rainy = Self.rainyCodes.contains(code ?? -1)
            let snowy = Self.snowyCodes.contains(code ?? -1)
            let center = CGPoint(x: s * 0.55, y: s * 0.38)

            func drawSun(_ c: CGPoint, radius: CGFloat, color: Color) {
                let rect = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }

            if code == 0 || code == 1 || code == 2 {
                if day {
                    drawSun(center, radius: s * 0.21, color: Self.color(0xFFD781))
                    for i in 0..<8 {
                        let a = Double(i) * .pi / 4
                        let inner = CGPoint(x: center.x + CGFloat(cos(a)) * s * 0.27,
                                            y: center.y + CGFloat(sin(a)) * s * 0.27)
                        let outer = CGPoint(x: center.x + CGFloat(cos(a)) * s * 0.33,
                                            y: center.y + CGFloat(sin(a)) * s * 0.33)
                        var line = Path()
                        line.move(to: inner)
                        line.addLine(to: outer)
                        context.stroke(line, with: .color(Self.color(0xFFD781)),
                                       style: StrokeStyle(lineWidth: s * 0.035, lineCap: .round))
                    }
                } else {
                    // Moon = full circle minus an offset cut circle (Compose Path.combine Difference).
                    let moonRect = CGRect(x: center.x - s * 0.25, y: center.y - s * 0.25,
                                          width: s * 0.5, height: s * 0.5)
                    let cutCenter = CGPoint(x: center.x + s * 0.13, y: center.y - s * 0.09)
                    let cutRect = CGRect(x: cutCenter.x - s * 0.23, y: cutCenter.y - s * 0.23,
                                         width: s * 0.46, height: s * 0.46)
                    let moon = Path(ellipseIn: moonRect)
                    let cut = Path(ellipseIn: cutRect)
                    let crescent = moon.subtracting(cut)  // even-odd equivalent of PathOperation.Difference
                    context.fill(crescent, with: .color(Self.color(0xFFE9B7)))
                }
            }

            if cloudy || code == 1 {
                let c = Self.color(0xF0F6FF)
                drawSun(CGPoint(x: s * 0.28, y: s * 0.53), radius: s * 0.17, color: c)
                drawSun(CGPoint(x: s * 0.48, y: s * 0.43), radius: s * 0.22, color: c)
                drawSun(CGPoint(x: s * 0.68, y: s * 0.54), radius: s * 0.17, color: c)
                let base = CGRect(x: s * 0.25, y: s * 0.48, width: s * 0.48, height: s * 0.23)
                context.fill(Path(roundedRect: base, cornerRadius: s * 0.1), with: .color(c))
            }

            if rainy && ![95, 96, 99].contains(code ?? -1) {
                for i in 0..<3 {
                    var drop = Path()
                    drop.move(to: CGPoint(x: s * (0.33 + CGFloat(i) * 0.16), y: s * 0.77))
                    drop.addLine(to: CGPoint(x: s * (0.28 + CGFloat(i) * 0.16), y: s * 0.9))
                    context.stroke(drop, with: .color(Self.color(0x9AD8FF)),
                                   style: StrokeStyle(lineWidth: s * 0.04, lineCap: .round))
                }
            }

            if [95, 96, 99].contains(code ?? -1) {
                var bolt = Path()
                bolt.move(to: CGPoint(x: s * 0.52, y: s * 0.64))
                bolt.addLine(to: CGPoint(x: s * 0.35, y: s * 0.84))
                bolt.addLine(to: CGPoint(x: s * 0.49, y: s * 0.84))
                bolt.addLine(to: CGPoint(x: s * 0.42, y: s * 0.99))
                bolt.addLine(to: CGPoint(x: s * 0.68, y: s * 0.74))
                bolt.addLine(to: CGPoint(x: s * 0.54, y: s * 0.74))
                bolt.closeSubpath()
                context.fill(bolt, with: .color(Self.color(0xFFD781)))
            }

            if snowy {
                for i in 0..<3 {
                    drawSun(CGPoint(x: s * (0.3 + CGFloat(i) * 0.18), y: s * 0.83),
                            radius: s * 0.035, color: ink)
                }
            }

            if code == 45 || code == 48 {
                for i in 0..<2 {
                    var fog = Path()
                    fog.move(to: CGPoint(x: s * 0.2, y: s * (0.78 + CGFloat(i) * 0.12)))
                    fog.addLine(to: CGPoint(x: s * 0.8, y: s * (0.78 + CGFloat(i) * 0.12)))
                    context.stroke(fog, with: .color(muted),
                                   style: StrokeStyle(lineWidth: s * 0.04, lineCap: .round))
                }
            }

            if code == nil {
                context.stroke(Path(ellipseIn: CGRect(x: s / 2 - s * 0.2, y: s / 2 - s * 0.2,
                                                      width: s * 0.4, height: s * 0.4)),
                               with: .color(ink.opacity(0.5)), lineWidth: s * 0.04)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(condition(code))
    }
}
