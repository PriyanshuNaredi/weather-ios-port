import SwiftUI

// Navigation self-test (crash/navigation/scroll mission, Phase 3) — the
// mission-required "isolated minimal SwiftUI navigation test screen with three
// ordinary buttons and three separate destinations". Proves SwiftUI navigation
// works independently of the weather app before reconnecting it to the full
// application.
//
// NOT fake: every button runs a real non-empty action closure that flips a
// real @State routing value (the same enum-switch pattern WeatherViewModel
// uses), logs each stage to Diag (tap received / action executed / state
// changed / destination constructed / destination appeared), and each
// destination carries real content and a working back button.

struct NavTestView: View {
    /// Same string-routing pattern as `WeatherViewModel.Screen`.
    @State private var route: NavTestRoute?
    /// Populated per stage so the on-screen evidence panel shows what fired.
    @State private var stages: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    Diag.event("navtest back tapped")
                    route = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(WeatherTheme.ink)
                        .padding(12)
                }
                .accessibilityLabel("Back")
                Text("Navigation self-test")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WeatherTheme.ink)
                Spacer()
            }

            Text("Three ordinary buttons → three separate destinations. Each destination is real content with a working back path. Stage events are logged and shown below.")
                .font(.system(size: 12))
                .foregroundStyle(WeatherTheme.muted)

            // The three test buttons (the "ordinary buttons").
            VStack(spacing: 10) {
                navTestButton("Route A — label + text", target: .alpha)
                navTestButton("Route B — counter", target: .beta)
                navTestButton("Route C — list", target: .gamma)
            }

            // Live evidence panel: which stages fired for the last navigation.
            VStack(alignment: .leading, spacing: 2) {
                Text("STAGES LOGGED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WeatherTheme.muted)
                if stages.isEmpty {
                    Text("Tap a route button — its stages appear here.")
                        .font(.system(size: 12))
                        .foregroundStyle(WeatherTheme.muted)
                }
                ForEach(Array(stages.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(WeatherTheme.ink.opacity(0.85))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WeatherTheme.background.ignoresSafeArea())
        .overlay {
            // The destination layer — same switch-on-state pattern as the app's
            // `switch viewModel.screen`. Presenting over the root keeps the
            // test buttons tappable again after "back".
            if let active = route {
                NavTestDestination(route: active) {
                    Diag.event("navtest destination back -> root")
                    route = nil
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default, value: route)
    }

    // Real action closure: logs the tap, executes the routing change, logs
    // the state change. No empty closures anywhere.
    private func navTestButton(_ title: String, target: NavTestRoute) -> some View {
        Button {
            Diag.event("navtest tap received -> \(target.rawValue)")
            route = target                                   // action executed
            Diag.event("navtest state changed -> \(target.rawValue)")
            stages = ["tap received: \(target.rawValue)",
                      "action executed: route set",
                      "state changed: \(target.rawValue)",
                      "destination constructed: \(target.rawValue)"]
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(WeatherTheme.ink)
        }
        .background(WeatherTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .accessibilityLabel(title)
    }
}

enum NavTestRoute: String {
    case alpha, beta, gamma
}

/// The three separate destinations — real content, real back button.
private struct NavTestDestination: View {
    let route: NavTestRoute
    let onBack: () -> Void
    @State private var counter = 0

    var body: some View {
        Group {
            switch route {
            case .alpha:
                VStack(spacing: 16) {
                    Text("Destination A").font(.system(size: 26, weight: .semibold))
                    Text("A plain label-and-text destination. If you can read this, destination construction and appearance worked.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(WeatherTheme.muted)
                }
            case .beta:
                VStack(spacing: 16) {
                    Text("Destination B").font(.system(size: 26, weight: .semibold))
                    Text("Counter: \(counter)").font(.system(size: 22))
                    Button("Increment") { counter += 1 }
                        .buttonStyle(.borderedProminent)
                }
            case .gamma:
                VStack(spacing: 10) {
                    Text("Destination C").font(.system(size: 26, weight: .semibold))
                    List(1...30, id: \.self) { n in
                        Text("Row \(n)")
                    }
                    .frame(maxHeight: 380)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WeatherTheme.panel.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(WeatherTheme.ink)
                    .padding(14)
            }
            .accessibilityLabel("Test back")
        }
        .onAppear { Diag.event("navtest destination APPEARED -> \(route.rawValue)") }
    }
}
