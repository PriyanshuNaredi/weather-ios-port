# APK Reverse-Engineering Findings (Step 5)

All findings verified against the **official v1.1.1 APK** (integrity-verified) and cross-checked against source at `6267da88fc33d9b8e21ec5d77851f7a33bdf97ea` (`main`). Decompiled output: `02_apk_analysis/jadx` (jadx 1.5.6), `02_apk_analysis/apktool` (apktool 2.12.1).

## 1. Identity & integrity

| Item | Official APK | Self-built debug APK |
|---|---|---|
| Package | `dev.kiankonrad.weather` | `dev.kiankonrad.weather.qa` (debug suffix from build.gradle.kts) |
| versionCode / versionName | 6 / 1.1.1 | 6 / 1.1.1 |
| compileSdk / targetSdk | 37 / 36 | 37 / 36 |
| Size | 97,175,284 B (92.7 MB) | 114,030,975 B (108.8 MB, debug + unstripped) |
| SHA-256 (file) | `49a502b2b2747c6cd6bf10e2d8ace1dad832d1e645e31b935e014ef8417199c1` — matches release SHA256SUMS.txt | `ed25fb6926ee4bffa06f4493820fa406cda54a831383d4ed1bece3cd8c7cc20e` |
| Signing cert SHA-256 | `d3370a7978ab64640b64af5be1ceca607eebc683cb0c3d47dd02dd0e7e23f5c3` (V2, CN=Weather Personal, O=Personal, C=DE) — **matches README's published cert hash** | `723369aa2bbfb5b2463c008a788bda63093a0600188ecece42bc5ff481c6a9e2` (Android Debug) |

## 2. Manifest (official, from apktool)

- Permissions in official APK: `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` (declared in source) **plus** `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, and `dev.kiankonrad.weather.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` — **verified merged in from library manifests** (MapLibre / androidx), not hand-added.
- Single activity `MainActivity`, `exported="true"`, launcher. `allowBackup=false`, `usesCleartextTraffic=false`, `extractNativeLibs=false`, `supportsRtl=true`, `dataExtractionRules=@xml/data_extraction_rules`.
- No services, receivers, providers, or deep links in the manifest.

## 3. Code architecture (verified from decompiled code, not assumed)

- **Single-activity Compose app.** No ViewModel, no DI framework, no Room/SQLite, no WorkManager.
- App classes in `dev.kiankonrad.weather` (43 classes in jadx output): `MainActivity`, `MainActivityKt`, `MapsKt`, `OpenWeatherRepository`, `DataCodec`, `ForecastProjectionKt`, `ModelsKt`, data classes (City/Hour/Day/Conditions/AirQuality/Weather/RadarFrame/RadarTimeline/TemperaturePoint/TemperatureGrid), interfaces `WeatherRepository`/`MapRepository`, enum `ConditionSource`.
- Decompilation confirms source claims: repository pattern + pure codec parsers + projection logic; UI state held in Compose `remember`/`mutableStateOf` (string screen key "weather"/"map"/"cities"/"settings" + Metric detail).
- 3 dex files (smali, smali_classes2, smali_classes3) — 17,197 classes total, overwhelmingly library code (Compose, MapLibre).

## 4. Networking (verified from `OpenWeatherRepository` + decompiled `DataKt`)

Endpoints (all HTTPS, cleartext disabled):
- `https://api.open-meteo.com/v1/forecast` — current (9 vars), hourly (13 vars), daily (8 vars), `forecast_days=10`, `timezone=auto`, `timeformat=unixtime`; also used for 7×7 temperature grids with `cell_selection=nearest`
- `https://air-quality-api.open-meteo.com/v1/air-quality` — european_aqi, us_aqi, pm2_5, pm10
- `https://geocoding-api.open-meteo.com/v1/search` — name, count=12, language=en
- `https://api.rainviewer.com/public/weather-maps.json` — radar frame list (frames under `/v2/radar/`)
- Tiles: `https://tiles.openfreemap.org/styles/dark` (MapLibre style), raster/vector tiles per that style; OpenStreetMap/OpenMapTiles attribution data

HTTP: OkHttp 4.12, timeouts 12/20/30s, 24MB cache in cacheDir `provider-http`, User-Agent `Weather/1.1.1 (https://github.com/Kian-hdr/Weather; dev.kiankonrad.weather)`, dedicated 429 message, separate OkHttp instance for map tiles. No API keys — all free/open endpoints. Attribution: in-app licenses dialog + map links below the map (`isAttributionEnabled=false` on MapLibre because the app renders attribution itself).

## 5. Storage (verified)

- `SharedPreferences` file `weather`: `imperial` (units flag), `cities` (JSON list of saved cities).
- `filesDir/weather-cache/`: `forecast-<latBits>_<lonBits>.json` (AtomicFile envelopes: city/forecast/air/fetchedAt), `radar.json` (5-min TTL, 2h stale fallback), `temperature-<...>.json` (30-min TTL, max 12 files kept). Writes only on successful parse.
- No account, no sync, no sensitive personal data beyond saved city coordinates (user-entered).

## 6. Native code

- `lib/arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64` — 4 ABIs.
- Only two `.so`: `libmaplibre.so` (12.8 MB arm64 — the dominant APK weight, ~2/3 of the APK) and `libandroidx.graphics.path.so` (10 KB). **No app-authored native code** — all Kotlin/Java.

## 7. Resources & assets

- Assets: `assets/legal/` (Apache-2.0.txt, MIT.txt, MapLibre notice, Bundled_Dependency_Notices.txt, NOTICE.txt) and `assets/dexopt/baseline.prof` (Baseline Profiles).
- res: standard Compose app resources (icons, themes, animator), localized app name only ("Weather" in ~90 locales).

## 8. Security / privacy posture

- No telemetry, no trackers, no ads SDKs (verified: no such packages in the 17k-class dex dump).
- Cleartext disabled; backup disabled; only location + internet permissions.
- Location is used transiently (LocationManager query) and only the chosen city is persisted locally.
- No obfuscation/minification of app code (R8 not enabled in debug; official release ships readable class structure).
- JDK 25 note: apksigner emits `Restricted method` warnings under JDK 25 (conscrypt) — tool-side only, no impact on APK.

## 9. jadx caveat

jadx reported 257 decompile errors across 19,271 Java files — all in third-party library code (MapLibre JNI boundaries); the 43 app-domain classes decompiled cleanly.
