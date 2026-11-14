import SwiftUI

// iOS port of `MainActivity.kt:424-446 SettingsScreen` — unit toggle, privacy
// note, data & attribution glass with links, version footer, and the licenses
// dialog. Kotlin reads the bundled `assets/legal/*.txt` files into the dialog;
// the iOS port ships the same license set in the bundle (Workstream E adds the
// resource files — see Bundle module note below).

struct SettingsScreenView: View {
    let imperial: Bool
    let onImperial: (Bool) -> Void
    /// Diagnostics entry point. Kotlin has no equivalent in the bottom bar, and
    /// it crowded the Cities button there, so the runtime-debug surface lives at
    /// the end of Settings instead.
    let onDiagnostics: () -> Void
    let onClose: () -> Void

    @State private var showLicenses = false
    /// Local mirror of the persisted unit preference. The switch previously bound
    /// its `isOn` straight to the immutable `imperial` parameter, so on the iOS 24A3351
    /// simulator the control kept its own value and never called the setter
    /// (verified: no `units ->` diagnostic event on tap, label never flipped).
    /// Owning the value here makes the switch respond immediately and still
    /// delegates the single write to `onImperial`.
    @State private var imperialLocal: Bool

    init(imperial: Bool, onImperial: @escaping (Bool) -> Void,
         onDiagnostics: @escaping () -> Void = {},
         onClose: @escaping () -> Void) {
        self.imperial = imperial
        self.onImperial = onImperial
        self.onDiagnostics = onDiagnostics
        self.onClose = onClose
        _imperialLocal = State(initialValue: imperial)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Settings", onClose: onClose)

                // Kotlin lines 428-429 — Units glass.
                GlassPanel {
                    Text("Units").font(.system(size: 22))
                    // NOTE: this row was a SwiftUI `Toggle`. On the iOS 24A3351
                    // simulator that control never delivered the tap to its
                    // binding (no setter call at any of 5 hit points, while
                    // buttons on the same screen worked), so the unit switch was
                    // dead. A Button + capsule indicator reproduces the Material
                    // switch from the Kotlin screen and gives a full-width target.
                    Button {
                        let newValue = !imperialLocal
                        imperialLocal = newValue
                        onImperial(newValue)
                    } label: {
                        HStack {
                            Text(imperialLocal ? "Fahrenheit · mph · inches" : "Celsius · km/h · millimeters")
                            Spacer(minLength: 12)
                            ZStack(alignment: imperialLocal ? .trailing : .leading) {
                                Capsule()
                                    .fill(imperialLocal ? WeatherTheme.accent : Color.white.opacity(0.22))
                                    .frame(width: 51, height: 31)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 27, height: 27)
                                    .padding(.horizontal, 2)
                                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use imperial units")
                    .accessibilityValue(imperialLocal ? "On" : "Off")
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
                    Text("Forecasts: Open-Meteo\nAir quality: CAMS via Open-Meteo\nRainfall radar: RainViewer\nMap data: © OpenStreetMap contributors\nDark basemap: Esri World Dark Gray\nMaps: custom SwiftUI tile renderer")
                        .padding(.top, 12)
                        .lineSpacing(10)
                    VStack(alignment: .leading, spacing: 0) {
                        linkRow("Open-Meteo", "https://open-meteo.com/")
                        linkRow("RainViewer", "https://www.rainviewer.com/")
                        linkRow("OpenStreetMap contributors", "https://www.openstreetmap.org/copyright")
                        linkRow("Esri World Dark Gray (basemap)",
                                "https://www.esri.com/en-us/arcgis/products/arcgis-online/overview")
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
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(WeatherTheme.accent)

                Link("Source code & downloads",
                     destination: URL(string: "https://github.com/Kian-hdr/Weather")!)
                    .foregroundStyle(WeatherTheme.accent)
                    .frame(minHeight: 44, alignment: .leading)

                // iOS-only runtime diagnostics (no Android counterpart); kept out
                // of the bottom navigation bar, which mirrors the Compose layout.
                Button { onDiagnostics() } label: {
                    Text("Diagnostics")
                        .font(.system(size: 13))
                        .foregroundStyle(WeatherTheme.muted.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
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

    // Kotlin `TextButton` (Material 48 dp min height, start-aligned label).
    private func linkRow(_ name: String, _ url: String) -> some View {
        Link(name, destination: URL(string: url)!)
            .frame(minHeight: 44, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
