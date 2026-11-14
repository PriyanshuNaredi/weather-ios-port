import SwiftUI

// iOS port of `MainActivity.kt:400-422 CityScreen` — the saved-city list and the
// debounced GeoNames search. Kotlin uses a LaunchedEffect(query) with a 350 ms
// delay and repository.search; SwiftUI uses .task(id: query) which also cancels
// the previous search when the query changes (matching the coroutine semantics).

struct CityScreenView: View {
    let cities: [City]
    let repository: WeatherRepository & MapRepository
    let message: String?
    let locating: Bool
    let onLocation: () async -> Void
    let onAdd: (City) -> Void
    let onRemove: (City) -> Void
    let onClose: () -> Void

    @State private var query = ""
    @State private var results: [City] = []
    @State private var searching = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField
            locateButton
            if let message {
                Text(message).foregroundStyle(WeatherTheme.muted)
            }
            if searching {
                ProgressView().frame(maxWidth: .infinity, alignment: .leading)
            }
            if let error {
                Text(error)
            }
            resultList
            link
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WeatherTheme.background.ignoresSafeArea())
        .task(id: query) {
            // Kotlin LaunchedEffect(query), lines 404-406.
            results = []
            error = nil
            searching = false
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 2 else { return }
            searching = true
            defer { searching = false }
            do {
                try await Task.sleep(nanoseconds: 350_000_000)   // Kotlin delay(350)
                results = try await repository.search(query: trimmed)
            } catch is CancellationError {
                // Kotlin rethrows CancellationException without setting error.
            } catch {
                self.error = "Search unavailable. Check your connection."
            }
        }
    }

    // Kotlin lines 406-407: header vs the empty-state branding block.
    @ViewBuilder
    private var header: some View {
        if !cities.isEmpty {
            ScreenHeader(title: "Weather", onClose: onClose)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Spacer().frame(height: 28)
                WeatherGlyph(code: 2, day: true, size: 72)
                Text("Weather").font(.system(size: 44, weight: .light))
                Text("Your day, at a glance.")
                    .font(.system(size: 20))
                    .foregroundStyle(WeatherTheme.muted)
            }
        }
    }

    // Kotlin OutlinedTextField, lines 408-411: rounded 16, label, search icon,
    // clear button when non-empty.
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(WeatherTheme.muted)
            // Material `OutlinedTextField` renders its label in `onSurfaceVariant`
            // (= Muted), not the platform's dimmed placeholder grey.
            TextField("", text: $query, prompt: Text("Search city or postal code")
                .foregroundStyle(WeatherTheme.muted.opacity(0.75)))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WeatherTheme.ink.opacity(0.4), lineWidth: 1)
                .background(WeatherTheme.ink.opacity(0.04)))
    }

    // Kotlin Button lines 412-415 — full-width, min height 50, disabled while locating.
    private var locateButton: some View {
        Button {
            Task { await onLocation() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                Text(locating ? "Finding your location…" : "Use my location")
            }
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(WeatherTheme.onAccent)
        .background(WeatherTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(locating)
        .opacity(locating ? 0.6 : 1)
    }

    // Kotlin LazyColumn, lines 417-421 — cards spaced 12 dp, each row a Glass
    // panel. Was a SwiftUI `List`, whose insets/separators/row chrome have no
    // Android counterpart and made the saved-city rows read as a stock table.
    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if query.trimmingCharacters(in: .whitespaces).count >= 2 {
                    if !searching && results.isEmpty && error == nil {
                        Text("No cities found. Try a nearby city.")
                            .foregroundStyle(WeatherTheme.muted)
                    }
                    ForEach(results) { city in
                        Button { onAdd(city) } label: {
                            GlassPanel {
                                Text(city.name).font(.system(size: 24))
                                Text(city.country).foregroundStyle(WeatherTheme.muted)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    if cities.isEmpty {
                        Text("Search for a city or choose your current location. Location access is optional.")
                            .foregroundStyle(WeatherTheme.muted)
                            .lineSpacing(6)
                            .padding(.top, 12)
                    }
                    ForEach(cities) { city in
                        GlassPanel {
                            HStack(spacing: 8) {
                                Button { onAdd(city) } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(city.name).font(.system(size: 26))
                                        Text(city.country.isEmpty ? "Current location" : city.country)
                                            .foregroundStyle(WeatherTheme.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Button { onRemove(city) } label: {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 22))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove \(city.name)")
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // Kotlin TextButton, line 422 — GeoNames attribution link.
    private var link: some View {
        Link("City search: GeoNames via Open-Meteo",
             destination: URL(string: "https://open-meteo.com/en/docs/geocoding-api")!)
            .font(.system(size: 12))
            .foregroundStyle(WeatherTheme.muted)
    }
}
