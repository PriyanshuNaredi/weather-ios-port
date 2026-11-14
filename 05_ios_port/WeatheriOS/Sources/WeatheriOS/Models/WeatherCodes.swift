// iOS port of the WMO weather-code map in `Models.kt` (`condition(code)`).
// Exact same table and fallback string.

func condition(_ code: Int?) -> String {
    switch code {
    case 0: "Clear sky"
    case 1: "Mostly clear"
    case 2: "Partly cloudy"
    case 3: "Cloudy"
    case 45, 48: "Fog"
    case 51, 53, 55: "Drizzle"
    case 56, 57: "Freezing drizzle"
    case 61, 63, 65: "Rain"
    case 66, 67: "Freezing rain"
    case 71, 73, 75, 77: "Snow"
    case 80, 81, 82: "Rain showers"
    case 85, 86: "Snow showers"
    case 95, 96, 99: "Thunderstorms"
    default: "Conditions unavailable"
    }
}
