#!/usr/bin/env bash
# Append the port-foundation milestone record to the four project docs.
set -u
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
D="$(date +%Y-%m-%d)"

append() { printf '%s\n' "$2" >> "$P/$1"; }

append PORT_GRAPH.md "## 2026-11-13 — Native iOS Port Foundation (WeatheriOS) — BUILDS UNSIGNED
- Step 1 audit (27-feature mapping, statuses Required/Optional/Needs further investigation) and Step 2 architecture presented and reviewed in session.
- New project: \`05_ios_port/WeatheriOS/\` via \`xtool new WeatheriOS --skip-setup\`; bundle ID set to **dev.kiankonrad.weather** in \`xtool.yml\` (distinct from HelloWorld's dev.kiankonrad.weather.hello).
- Foundation sources ported from Kotlin (all traced to source, none invented):
  - Models.kt -> Models/Models.swift (City/Hour/Day/Conditions/AirQuality/Weather/RadarFrame/RadarTimeline/TemperaturePoint/TemperatureGrid; WeatherRepository+MapRepository protocols, async replaces suspend, protocols marked Sendable)
  - Models.kt helpers -> Models/Units.swift (display/temp/speed/localTime, exact conversion constants), Models/WeatherCodes.swift (exact WMO table)
  - ForecastProjection.kt -> Repositories/ForecastProjection.swift (verbatim logic: 900 s current window, 1...3600 s interpolation span, circular wind-direction blend, 6..<18 daylight fallback, air freshness 3600 s)
  - Data.kt -> Services/OpenMeteoClient.swift (5 endpoint constants, exact hourly/daily param lists, User-Agent \"Weather/1.1.1 (https://github.com/Kian-hdr/Weather; dev.kiankonrad.weather)\", URLCache 24 MB disk mirroring OkHttp cache; RepositoryError enum) + Repositories/OpenWeatherRepository.swift skeleton (UserDefaults suite \"weather\", Double.bitPattern cache key, cities JSON storage; fetch methods throw .notImplemented for next milestone)
  - MainActivity.kt -> App/WeatherApp.swift (@main, AppEnvironment DI mirroring WeatherApp(repositoryOverride, displayTimeOverride) test seam) + ViewModels/WeatherViewModel.swift (@MainActor @Observable, Screen enum weather/map/cities/settings) + ContentView.swift (WeatherRootView scaffold: weather screen + 3 placeholders)
- Template overwrites (documented per rule 7, files retained per rule 3): WeatheriOSApp.swift (template @main removed — duplicate @main would not compile), ContentView.swift (template 'Hello, world!' replaced).
- Build fixes (Swift 6 strict concurrency, toolchain 6.4.2): OpenMeteoClient marked Sendable; WeatherViewModel marked @MainActor; repository protocols marked Sendable; OpenWeatherRepository @unchecked Sendable with NSLock guarding the in-memory cache.
- Build: mirror to ext4 ~/weather-ios-src, \`xtool dev build\` (NO --sign, NO --ipa) -> **exit 0**. Output: WeatheriOS.app/WeatheriOS, Mach-O 64-bit arm64 (NOUNDEFS|DYLDLINK|TWOLEVEL|PIE), **LC_CODE_SIGNATURE count 0**, no _CodeSignature/, no embedded.mobileprovision. Info.plist: CFBundleIdentifier dev.kiankonrad.weather, CFBundleExecutable WeatheriOS, MinimumOSVersion 17.0. SHA-256 of executable: 4f80335c5e6c9e7258c1e5febdf5392de7d4a06dc1d29f2661d460d65359dd7c.
- No Apple Developer Services, no authentication, no device operations performed.
- Immutability verified: 0 files under 00_original and 0 under 05_ios_port/HelloWorld modified today.
- Known limitation: \`xtool dev\` has no test subcommand on Linux — unit tests cannot run for the iOS target in this environment (Android repo has 7 test files: DataTest, ForecastProjectionTest, MapGeometryTest, WeatherArtworkTest, WeatherFlowTest, OfflineForecastTest, PublicationTest); pure-logic ports are structured for future XCTest run on macOS.
- Artifacts copied (cp -n, no overwrite): 06_build_artifacts/unsigned-binaries/WeatheriOS-foundation-20261113.bin and 05_ios_port/WeatheriOS/build-output/WeatheriOS.app; logs in 06_build_artifacts/logs/port-foundation-*.log.
- STOPPED per execution discipline: awaiting user approval before full feature implementation."

append PROJECT_STATUS.md "## $D — Port foundation milestone (Step 3+4 of port kickoff)
- WeatheriOS created (bundle dev.kiankonrad.weather); 9 foundation Swift files + 2 documented template overwrites.
- \`xtool dev build\` unsigned: SUCCESS (exit 0), arm64 Mach-O, LC_CODE_SIGNATURE=0, no provisioning, no Apple services contacted.
- Executable SHA-256: 4f80335c5e6c9e7258c1e5febdf5392de7d4a06dc1d29f2661d460d65359dd7c.
- Unit tests: not runnable on Linux for iOS target (no \`xtool dev test\`); limitation documented.
- Next: user approval required before full feature implementation (provider decode, screens, MapKit layer)."

append REPRODUCE.md "## 4. Reproduce the WeatheriOS foundation build (Phase 2, unsigned)
\`\`\`bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash \"<project>/07_tools/port-build1.sh\"   # mirror to ~/weather-ios-src + xtool dev build
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash \"<project>/07_tools/port-verify1.sh\"  # verify + copy artifacts back
\`\`\`
Observed 2026-11-13: \`xtool dev build\` exit 0; WeatheriOS.app/WeatheriOS Mach-O 64-bit arm64; LC_CODE_SIGNATURE count 0; no _CodeSignature/, no embedded.mobileprovision; CFBundleIdentifier dev.kiankonrad.weather; MinimumOSVersion 17.0; SHA-256 4f80335c5e6c9e7258c1e5febdf5392de7d4a06dc1d29f2661d460d65359dd7c. No Apple services touched. Packaging only — not installed on any device."

append CHANGELOG.md "## $D — WeatheriOS foundation (port Steps 3–4)
- Added: 05_ios_port/WeatheriOS (xtool project, bundle dev.kiankonrad.weather) with App/Models/Services/Repositories/ViewModels/Views foundation ports traced to Kotlin source.
- Changed: template WeatheriOSApp.swift + ContentView.swift overwritten (documented; retained per rule 3).
- Build: unsigned \`xtool dev build\` succeeds on Swift 6.4.2 / Darwin SDK 27.2; arm64, LC_CODE_SIGNATURE=0; artifacts copied without overwrite.
- Known limitation: unit tests not runnable for iOS target on Linux (no \`xtool dev test\`)."
echo "docs updated"
