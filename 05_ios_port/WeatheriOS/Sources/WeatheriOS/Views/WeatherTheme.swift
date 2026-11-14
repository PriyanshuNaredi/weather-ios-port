import SwiftUI

// iOS port of the Compose theme constants in `MainActivity.kt` (lines 70-84):
// Ink/Muted/Panel/Accent palette, the dark color scheme and the glass-panel
// styling. The Kotlin `Glass` composable (lines 299-308) layers a vertical dark
// gradient, a subtle white sheen and a border stroke on one rounded column.

enum WeatherTheme {
    /// Kotlin `Ink = Color.White`
    static let ink = Color.white
    /// Kotlin `Muted = Color(0xFFE0EBFA)`
    static let muted = Color(red: 0xE0 / 255, green: 0xEB / 255, blue: 0xFA / 255)
    /// Kotlin `Panel = Color(0xEE193B60)`
    static let panel = Color(red: 0x19 / 255, green: 0x3B / 255, blue: 0x60 / 255)
        .opacity(0xEE / 255.0)
    /// Kotlin `Accent = Color(0xFFB6DEFF)`
    static let accent = Color(red: 0xB6 / 255, green: 0xDE / 255, blue: 0xFF / 255)
    /// Kotlin background `Color(0xFF102D50)` (MainActivity Surface + WeatherApp Box)
    static let background = Color(red: 0x10 / 255, green: 0x2D / 255, blue: 0x50 / 255)
    /// Kotlin bottom bar `Color(0xD9122E50)` (MainActivity.kt:147)
    static let bottomBar = Color(red: 0x12 / 255, green: 0x2E / 255, blue: 0x50 / 255)
        .opacity(0xD9 / 255.0)
    /// Kotlin status/navigation scrim `Color(0x99112340)` (MainActivity.kt:159-160)
    static let edgeScrim = Color(red: 0x11 / 255, green: 0x23 / 255, blue: 0x40 / 255)
        .opacity(0x99 / 255.0)
    /// Kotlin onPrimary `Color(0xFF062642)` (darkColorScheme, unused by Compose UI but kept)
    static let onAccent = Color(red: 0x06 / 255, green: 0x26 / 255, blue: 0x42 / 255)
}

// MARK: - Glass panel (Kotlin MainActivity.kt:299-308 `Glass`)

/// Transparent layers keep the atmospheric sky visible; the dark tint protects
/// text contrast (comment preserved from Kotlin).
struct GlassPanel<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // Kotlin `Glass` is a `Column` (MainActivity.kt:299-308), so its
        // children stack vertically with no gaps. SwiftUI needs that stack
        // explicitly: applying the card modifiers to a bare view-builder tuple
        // makes every child render as its own card (that is why the Settings
        // "Units" title and its value row appeared as two separate panels).
        let dark = LinearGradient(colors: [
            Color(red: 0x13 / 255, green: 0x29 / 255, blue: 0x45 / 255).opacity(0x66 / 255.0),
            Color(red: 0x10 / 255, green: 0x22 / 255, blue: 0x3C / 255).opacity(0x88 / 255.0),
        ], startPoint: .top, endPoint: .bottom)
        let sheen = LinearGradient(colors: [
            .white.opacity(0.09), .clear, .white.opacity(0.025),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        let border = LinearGradient(colors: [
            .white.opacity(0.25), .white.opacity(0.045), .white.opacity(0.11),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        return VStack(alignment: .leading, spacing: 0) { content }
            .padding(16)
            .background(dark)
            .background(sheen)
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Panel title (Kotlin MainActivity.kt:310 `PanelTitle`)

struct PanelTitle: View {
    let icon: String   // SF Symbol name (Compose uses a material ImageVector)
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(WeatherTheme.muted)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .kerning(0.5)
                .foregroundStyle(WeatherTheme.muted)
        }
    }
}

// MARK: - Notice (Kotlin MainActivity.kt:312 `Notice`)

struct Notice: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        GlassPanel {
            Text(message).font(.system(size: 14))
            Button(action: onRetry) {
                Text("Retry").foregroundStyle(WeatherTheme.accent)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Screen header (Kotlin MainActivity.kt:446 `ScreenHeader`)

struct ScreenHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            // Kotlin `IconButton` (48 dp target, 24 dp arrow) — not a bare glyph.
            Button(action: onClose) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 22))
                    .foregroundStyle(WeatherTheme.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Text(title)
                .font(.system(size: 28, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        // Kotlin has no extra padding: the IconButton's own 48 dp box is the gap.
        .padding(.leading, -6)
    }
}

// MARK: - Display clock (Kotlin `DisplayClock.pattern`, MainActivity.kt:91)

/// Kotlin `android.text.format.DateFormat.is24HourFormat(context)` decides the
/// pattern; iOS equivalent reads the locale's "j" template for an AM/PM marker.
enum DisplayClock {
    /// Cached because it allocates a `DateFormatter` for the locale template and
    /// is read per hourly label on every layout pass (see `localTime`).
    private static let cachedUses24Hour: Bool = {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0,
                                                locale: Locale.current) ?? "HH:mm"
        return !template.contains("a")
    }()

    static var uses24Hour: Bool { cachedUses24Hour }

    /// Kotlin `DisplayClock.pattern` — "HH:mm" (24 h) or "h:mm a" (12 h).
    static var pattern: String { uses24Hour ? "HH:mm" : "h:mm a" }
}

// MARK: - Local-date helpers (Kotlin `Instant.atZone(zone).toLocalDate().toString()`)

enum LocalDateKeys {
    /// "yyyy-MM-dd" bucket for an epoch second in the given IANA zone.
    static func dateKey(epoch: Int, zone: String) -> String {
        DataCodec.isoDate(epoch: epoch, zone: zone)
    }

    /// Kotlin MainActivity.kt:250 — weekday name of a parsed "yyyy-MM-dd" date,
    /// first three letters capitalized ("MONDAY" → "Mon"); unparsable falls back
    /// to the raw string.
    static func weekdayLabel(_ date: String) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let parsed = formatter.date(from: date) else { return date }
        let weekday = calendar.component(.weekday, from: parsed)
        let name = calendar.weekdaySymbols[(weekday - 1 + 7) % 7]  // "Monday"…
        let short = String(name.prefix(3))                          // "Mon" (already capitalized)
        return short.prefix(1).uppercased() + short.dropFirst()
    }
}
