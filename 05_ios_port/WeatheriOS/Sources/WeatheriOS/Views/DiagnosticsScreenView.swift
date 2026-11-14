import SwiftUI
import UIKit

// TEMPORARY diagnostics screen (runtime-debugging mission, Phases 1 & 4).
// Shows the DiagLog event trail, the current memory footprint, and the
// controlled diagnostic configurations A–E used to isolate the crash:
//   A — forecast only, map previews disabled      (diagMapPreviews = false)
//   B — forecast with map previews                 (diagMapPreviews = true)
//   C — map screen without radar animation         (diagRadarEnabled = false)
//   D — map screen with radar animation            (diagRadarEnabled = true)
//   E — full application (all defaults on)
// The toggles persist in UserDefaults; neither map nor radar is permanently
// removed — defaults restore the full app (E). No coordinates or city names
// are shown: only counts, screen names and timings.

/// Diagnostic switches, persisted via UserDefaults (UserDefaults-backed so
/// they survive relaunch — the user flips a preset, then exercises the app).
@MainActor
enum DebugConfig {
    static let mapPreviewsKey = "diag.mapPreviews"
    static let radarEnabledKey = "diag.radarEnabled"

    static var mapPreviews: Bool {
        get { UserDefaults.standard.object(forKey: mapPreviewsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: mapPreviewsKey) }
    }

    static var radarEnabled: Bool {
        get { UserDefaults.standard.object(forKey: radarEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: radarEnabledKey) }
    }

    static func preset(_ name: String) {
        switch name {
        case "A": mapPreviews = false; radarEnabled = true
        case "B": mapPreviews = true; radarEnabled = true
        case "C": mapPreviews = true; radarEnabled = false
        case "D": mapPreviews = true; radarEnabled = true
        default: mapPreviews = true; radarEnabled = true   // E — full app
        }
        Diag.event("diag preset \(name) applied (mapPreviews=\(mapPreviews), radar=\(radarEnabled))")
    }
}

struct DiagnosticsScreenView: View {
    let onClose: () -> Void

    @State private var refreshTick = 0
    @State private var mapPreviews = DebugConfig.mapPreviews
    @State private var radarEnabled = DebugConfig.radarEnabled
    @State private var copied = false
    /// Previous session's log when that session ended abnormally (crash,
    /// watchdog or jetsam termination) — loaded once when the screen appears.
    @State private var previousSession: String?
    /// Isolated self-test screens (navigation / forecast-scroll missions).
    @State private var showNavTest = false
    @State private var showScrollTest = false

    // Show at most the newest 80 events; the full trail goes to export.
    private var visibleEntries: [DiagLog.Entry] {
        let (entries, _) = DiagLog.shared.snapshot()
        return Array(entries.suffix(80))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(WeatherTheme.ink)
                        .padding(12)
                }
                .accessibilityLabel("Back")
                Text("Diagnostics")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WeatherTheme.ink)
                Spacer()
            }

            Text("Temporary debug instrumentation. Share the exported log after reproducing a problem — it contains no location data.")
                .font(.system(size: 12))
                .foregroundStyle(WeatherTheme.muted)

            // Previous session (crash-surviving disk log): shown when the last
            // session ended without a clean-exit marker — i.e. the app was
            // terminated. This is the evidence channel when the UI hangs.
            if let previousSession {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PREVIOUS SESSION — ABNORMAL END (terminated/crashed)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WeatherTheme.accent)
                    ScrollView {
                        Text(previousSession)
                            .font(.system(size: 9, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                    Button("Copy previous session") {
                        UIPasteboard.general.string = previousSession
                        Diag.event("diag previous session copied")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .padding(12)
                .background(WeatherTheme.panel.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Isolated self-tests (navigation + forecast scroll missions).
            HStack(spacing: 12) {
                Button {
                    Diag.event("diag nav self-test opened")
                    showNavTest = true
                } label: {
                    Text("Nav self-test")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(WeatherTheme.ink)
                }
                .background(WeatherTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Button {
                    Diag.event("diag scroll self-test opened")
                    showScrollTest = true
                } label: {
                    Text("Scroll self-test")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(WeatherTheme.ink)
                }
                .background(WeatherTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }

            // Controlled configurations A–E (mission Phase 4).
            VStack(alignment: .leading, spacing: 8) {
                Text("DIAGNOSTIC CONFIGURATION")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WeatherTheme.muted)
                HStack(spacing: 8) {
                    ForEach(["A", "B", "C", "D", "E"], id: \.self) { name in
                        Button {
                            DebugConfig.preset(name)
                            mapPreviews = DebugConfig.mapPreviews
                            radarEnabled = DebugConfig.radarEnabled
                            refreshTick += 1
                        } label: {
                            VStack(spacing: 2) {
                                Text(name).font(.system(size: 15, weight: .semibold))
                                Text(presetLabel(name))
                                    .font(.system(size: 8))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(WeatherTheme.ink)
                        }
                        .background(WeatherTheme.panel.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                Toggle("Forecast map previews (B/E on · A off)", isOn: Binding(
                    get: { mapPreviews },
                    set: { DebugConfig.mapPreviews = $0; mapPreviews = $0; refreshTick += 1 }))
                    .font(.system(size: 13))
                Toggle("Radar animation layer (D/E on · C off)", isOn: Binding(
                    get: { radarEnabled },
                    set: { DebugConfig.radarEnabled = $0; radarEnabled = $0; refreshTick += 1 }))
                    .font(.system(size: 13))
            }
            .padding(12)
            .background(WeatherTheme.panel.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .id(refreshTick)

            // Memory footprint + actions.
            HStack(spacing: 12) {
                if let mb = DiagLog.footprintMB() {
                    Text(String(format: "Footprint %.1f MB", mb))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WeatherTheme.ink)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = DiagLog.exportText()
                    copied = true
                    Diag.event("diag log copied to clipboard")
                } label: {
                    Text(copied ? "Copied ✓" : "Copy log")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(WeatherTheme.ink)
                }
                .background(WeatherTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                ShareLink(item: DiagLog.exportText(), message: Text("weather diagnostics log")) {
                    Text("Share")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(WeatherTheme.ink)
                }
                .background(WeatherTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Live event trail (newest last, auto-refreshing every second so
            // the user can watch events arrive while reproducing the issue).
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if visibleEntries.isEmpty {
                        Text("No events recorded yet.")
                            .font(.system(size: 12))
                            .foregroundStyle(WeatherTheme.muted)
                    }
                    ForEach(Array(visibleEntries.enumerated()), id: \.offset) { _, entry in
                        Text("\(Self.stamp(entry.seconds))  \(entry.message)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(WeatherTheme.ink.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .bottomTrailing) {
                Button("Clear") {
                    DiagLog.shared.clear()
                    refreshTick += 1
                }
                .font(.system(size: 11))
                .foregroundStyle(WeatherTheme.muted)
                .padding(8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WeatherTheme.background.ignoresSafeArea())
        .task {
            previousSession = DiagLog.previousSessionText()
            // Refresh the trail once per second while the screen is visible.
            // Stability fix: `try?` swallowed CancellationError, so the loop
            // kept mutating @State forever after the cover was dismissed.
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 1_000_000_000) }
                catch { break }   // cancelled when the cover is dismissed
                refreshTick += 1
            }
        }
        .fullScreenCover(isPresented: $showNavTest) { NavTestView() }
        .fullScreenCover(isPresented: $showScrollTest) { ForecastIsolationView() }
    }

    private static func stamp(_ seconds: Double) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date(timeIntervalSinceReferenceDate: seconds))
    }

    private func presetLabel(_ name: String) -> String {
        switch name {
        case "A": return "forecast\nno previews"
        case "B": return "forecast\npreviews"
        case "C": return "map\nno radar"
        case "D": return "map\nradar"
        default: return "full\napp"
        }
    }
}
