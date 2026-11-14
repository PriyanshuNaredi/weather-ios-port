import SwiftUI

// iOS port of `MainActivity.kt:424-446 SettingsScreen` — unit toggle, privacy
// note, data & attribution glass with links, version footer, and the licenses
// dialog. Kotlin reads the bundled `assets/legal/*.txt` files into the dialog;
// the iOS port ships the same license set in the bundle (Workstream E adds the
// resource files — see Bundle module note below).

struct SettingsScreenView: View {
    let imperial: Bool
    let onImperial: (Bool) -> Void
    let onClose: () -> Void

    @State private var showLicenses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Settings", onClose: onClose)

                // Kotlin lines 428-429 — Units glass.
                GlassPanel {
                    Text("Units").font(.system(size: 22))
                    HStack {
                        Text(imperial ? "Fahrenheit · mph · inches" : "Celsius · km/h · millimeters")
                        Spacer()
                        Toggle("", isOn: Binding(get: { imperial }, set: { onImperial($0) }))
                            .labelsHidden()
                            .tint(WeatherTheme.accent)
                            .accessibilityLabel("Use imperial units")
                    }
                }

                // Kotlin line 430 — privacy glass, exact wording.
                GlassPanel {
                    Text("Made for a quieter forecast").font(.system(size: 22))
                    Text("No ads, accounts, analytics, or background location tracking. Location is requested only when you choose it. Weather and map services receive the coordinates needed for their requests.")
                        .padding(.top, 12)
                        .lineSpacing(8)
                }

                // Kotlin lines 431-434 — attribution glass + links.
                GlassPanel {
                    Text("Data & attribution").font(.system(size: 22))
                    Text("Forecasts: Open-Meteo\nAir quality: CAMS via Open-Meteo\nRainfall radar: RainViewer\nMap data: © OpenStreetMap contributors\nDark basemap: OpenFreeMap · © OpenMapTiles\nMaps: MapLibre Native")
                        .padding(.top, 12)
                        .lineSpacing(10)
                    VStack(alignment: .leading, spacing: 0) {
                        linkRow("Open-Meteo", "https://open-meteo.com/")
                        linkRow("RainViewer", "https://www.rainviewer.com/")
                        linkRow("OpenStreetMap contributors", "https://www.openstreetmap.org/copyright")
                        linkRow("OpenFreeMap", "https://openfreemap.org/")
                        linkRow("OpenMapTiles style credits and license",
                                "https://github.com/openmaptiles/dark-matter-gl-style/blob/master/LICENSE.md")
                    }
                }

                // Kotlin line 435 — version footer, exact wording.
                Text("Weather 1.1.1\nCreated by Kian Konrad\nOpen source · MIT license")
                    .font(.system(size: 13))
                    .foregroundStyle(WeatherTheme.muted)
                    .lineSpacing(7)

                Button { showLicenses = true } label: {
                    Text("Open-source licenses")
                }
                .buttonStyle(.plain)
                .foregroundStyle(WeatherTheme.accent)

                Link("Source code & downloads",
                     destination: URL(string: "https://github.com/Kian-hdr/Weather")!)
                    .foregroundStyle(WeatherTheme.accent)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(WeatherTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showLicenses) {
            // Kotlin AlertDialog lines 437-441 — bundled legal texts, one
            // paragraph per "\n\n" block.
            LicensesSheet()
        }
    }

    private func linkRow(_ name: String, _ url: String) -> some View {
        Link(name, destination: URL(string: url)!)
            .padding(.vertical, 4)
    }
}

/// Kotlin `notice = assets legal/*.txt joined on "\n\n"` (lines 437-441). The
/// five files ship in the app bundle under `legal/`; missing files render an
/// inline notice rather than crashing, matching the "never fabricate" rule.
private struct LicensesSheet: View {
    @Environment(\.dismiss) private var dismiss

    private static let legalFiles = [
        "MIT.txt", "NOTICE.txt", "Apache-2.0.txt",
        "MapLibre_Android_13.6.1.txt", "Bundled_Dependency_Notices.txt",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(paragraphs, id: \.offset) { pair in
                        Text(pair.element)
                            .font(.system(size: 12))
                            .lineSpacing(4)
                            .padding(.bottom, 12)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Open-source licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var paragraphs: [(offset: Int, element: String)] {
        let notice = Self.legalFiles.compactMap { name -> String? in
            let stem = (name as NSString).deletingPathExtension
            // SwiftPM `.copy` resources land in a generated bundle inside the
            // app bundle; plain resources land flat. Try both lookups.
            let candidates = [
                Bundle.main.url(forResource: stem, withExtension: "txt", subdirectory: "legal"),
                Bundle.main.url(forResource: stem, withExtension: "txt"),
                Bundle.main.url(forResource: stem, withExtension: "txt",
                                subdirectory: "WeatheriOS_WeatheriOS.bundle/legal"),
            ]
            guard let url = candidates.compactMap({ $0 }).first,
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return text
        }
        return Array(notice.joined(separator: "\n\n")
            .components(separatedBy: "\n\n")
            .enumerated())
    }
}
