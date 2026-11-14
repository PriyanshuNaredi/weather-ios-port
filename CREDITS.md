# Credits and upstream projects

Weather for iOS is a native SwiftUI port of **Weather for Android** by Kian Konrad
(`Kian-hdr/Weather`, MIT). Everything below is somebody else's work; this file exists so
the debt is written down in one place rather than buried in code comments.

Port status: the Android app (APK, Kotlin + Jetpack Compose + MapLibre GL) now runs as a
native iOS app (IPA, Swift + SwiftUI, custom tile renderer, no MapLibre dependency).
Screens, wording, colour stops, cache budgets and API calls were ported from
`00_original/source/Weather/.../*.kt`, not re-invented.

## Data and imagery

| Project | What it provides here | Terms | Link |
|---|---|---|---|
| **Weather for Android** (Kian Konrad) | The original app: UI, flow, wording, colour stops, cache policy, API usage — the reference this port is measured against | MIT | <https://github.com/Kian-hdr/Weather> |
| **Open-Meteo** | Forecast, current conditions, hourly/daily series, air quality | Service under AGPL-3.0; data CC BY 4.0 — attribution required | <https://open-meteo.com/> |
| **CAMS** (Copernicus Atmosphere Monitoring Service, via Open-Meteo) | AQI, PM2.5 and the pollutant read-outs | Copernicus licence; attribution required | <https://open-meteo.com/en/docs/air-quality-api> |
| **GeoNames** (via Open-Meteo geocoding) | City search and city metadata (country, admin area, time zone) | CC BY 4.0 | <https://open-meteo.com/en/docs/geocoding-api> |
| **RainViewer** | Rainfall radar tiles — the animated radar loop on the map | Free public API; attribution required | <https://www.rainviewer.com/> |
| **OpenStreetMap contributors** | All map data underneath the basemap and the weather overlays | ODbL 1.0 — "© OpenStreetMap contributors" | <https://www.openstreetmap.org/copyright> |
| **Esri — World Dark Gray Canvas** | The dark basemap the iOS port draws (the APK used OpenFreeMap; CARTO was tried and dropped) | Esri terms; attribution required | <https://www.esri.com/en-us/arcgis/products/arcgis-online/overview> |
| **OpenFreeMap** | Basemap used by the original app; still credited in Settings | MIT (service), OSM data | <https://openfreemap.org/> |
| **OpenMapTiles — dark-matter style** | The dark cartography the original style is derived from | OpenMapTiles style licence | <https://github.com/openmaptiles/dark-matter-gl-style> |

Attribution is shown in the app (Settings → Data & attribution) and the required notices
ship in the bundle as `legal/NOTICE.txt` and `legal/Bundled_Dependency_Notices.txt`.

## Software

| Project | What it does here | Licence | Link |
|---|---|---|---|
| **SwiftUI / Foundation / CoreLocation / MapKit-free renderer** | The whole UI, animation, gestures and tile compositing on iOS | Apple SDK terms | <https://developer.apple.com/xcode/swiftui/> |
| **MapLibre Native 13.6.1** | Map engine of the *Android* original (not linked on iOS); its notices ship with the app because the port carries the original's attribution | BSD-2-Clause | <https://github.com/maplibre/maplibre-native> |
| **Kotlin / Jetpack Compose / OkHttp** | Stack of the Android original | Apache-2.0 | <https://kotlinlang.org/>, <https://developer.android.com/jetpack/compose> |
| **XcodeGen** | Generates `WeatheriOS.xcodeproj` from `project.yml`, so no Xcode state is committed | MIT | <https://github.com/yonaskolb/XcodeGen> |
| **ponytail** (Dietrich Gebert) | The audit skill used for the repo-wide code audit in `CODE_AUDIT.md` | MIT | <https://github.com/DietrichGebert/ponytail> |
| **pi** (free-pi CLI) | The agent harness the port was built and tested in | see project | <https://github.com/earendil-works/pi> |

## Shout-outs

- **Kian Konrad** — for publishing Weather for Android under MIT with clear structure and
  readable naming. Porting it was tractable because `Maps.kt` says what it means; the
  comments here reference its line numbers by design.
- **Open-Meteo** — a keyless, well-documented API that made building a real weather app
  possible without a sign-up wall or a billing account. The per-point multi-latitude query
  that paints the temperature grid is a nice piece of API design.
- **RainViewer** — public radar tiles with no key, which is why the radar loop animates at
  all in a hobby project.
- **OpenStreetMap contributors** and **Esri** — the map under everything else. Surveying
  and maintaining that data is volunteer and commercial work taken for granted by everyone
  who ships a map.
- **The OpenMapTiles / OpenFreeMap / MapLibre communities** — for an open cartography stack
  that a single developer can actually use.
- **XcodeGen** — turned an afternoon of `.xcodeproj` merge conflicts into a 60-line spec.
- **Dietrich Gebert (ponytail)** — its audit method is what found the two `LocationFinder`
  hangs and the GeoNames id bug documented in `CODE_AUDIT.md`.

## What is not claimed

- This is an **unsigned development build**. No App Store, no TestFlight, no Apple ID, no
  provisioning profile is involved; `05_ios_port/MACOS_VERIFICATION.md` records what has
  and has not been executed on real hardware.
- The maps-style names, icons and copy come from the original app; the SwiftUI
  implementation and the tile renderer are new code written for this port.
