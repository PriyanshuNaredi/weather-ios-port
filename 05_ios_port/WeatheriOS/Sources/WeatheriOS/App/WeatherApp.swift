import SwiftUI
import UIKit

/// Application entry point (iOS port of `MainActivity` as `@main` composition root).
/// Android equivalent: `MainActivity.WeatherApp(repositoryOverride, displayTimeOverride)`
/// — the same test seam is preserved via `AppEnvironment` injection.
@main
struct WeatherApp: App {
    /// Dependency container; `repositoryOverride` mirrors the Kotlin `WeatherApp` parameter
    /// so previews/tests can inject a fake without touching `OpenWeatherRepository`.
    @State private var environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Test seam: `-resetState` runs before the repository is constructed so a
        // UI test always starts from the same empty state (Android equivalent:
        // clearing SharedPreferences + cacheDir before an instrumented test).
        Self.resetStateIfRequested()
        environment = AppEnvironment(repository: OpenWeatherRepository())
        Diag.event("app init (diagnostic build)")
    }

    /// Clears persisted cities/units and the on-disk forecast/tile caches when the
    /// `-resetState` launch argument is present. No effect in normal launches.
    private static func resetStateIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-resetState") else { return }
        UserDefaults(suiteName: "weather")?.removePersistentDomain(forName: "weather")
        UserDefaults.standard.synchronize()
        if let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: base)
        }
    }

    var body: some Scene {
        WindowGroup {
            WeatherRootView()
                .environment(environment)
                // Instrumentation: scene lifecycle + jetsam precursor events.
                // phys_footprint is the counter iOS jetsam uses; a rising trend
                // with a memory warning explains "terminated without a crash".
                .onChange(of: scenePhase) {
                    let footprint = DiagLog.footprintMB().map { String(format: " %.0fMB", $0) } ?? ""
                    Diag.event("scenePhase -> \(scenePhase)\(footprint)")
                    // Crash-evidence channel: when the app leaves the foreground
                    // cleanly we mark the diagnostic session file "clean", so the
                    // NEXT launch only reports a previous session when this one
                    // was terminated abnormally (crash / watchdog / jetsam).
                    // Swift note: `.onChange(of:)` here resolves to the zero-param
                    // closure form (SDK quirk), so the phase is read via
                    // `scenePhase` rather than a closure argument.
                    if scenePhase != .active {
                        DiagLog.shared.markSessionClean()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    let footprint = DiagLog.footprintMB().map { String(format: " %.0fMB", $0) } ?? ""
                    Diag.event("MEMORY WARNING\(footprint)")
                }
        }
    }
}

/// Service construction / dependency injection (equivalent of the repository wiring
/// inside Android `MainActivity` + `OpenWeatherRepository(context)`).
@Observable
final class AppEnvironment {
    let repository: WeatherRepository & MapRepository
    /// Display-clock override for deterministic previews/tests (Kotlin: `displayTimeOverride`).
    let displayTimeOverride: Date?

    init(repository: WeatherRepository & MapRepository,
         displayTimeOverride: Date? = nil) {
        self.repository = repository
        self.displayTimeOverride = displayTimeOverride
    }
}
