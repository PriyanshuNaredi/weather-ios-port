# Architecture (verified: source + decompiled official APK)

Single-activity Jetpack Compose Material3 app. **No ViewModel, no DI, no Room, no WorkManager.**

```
MainActivity.kt (all UI, navigation, location, refresh)
  ├─ screen key: "weather" | "map" | "cities" | "settings" | Metric
  ├─ HorizontalPager over saved cities; PullToRefreshBox
  ├─ refresh trigger: fetchedAt ≥ 900s old, or 15-min resume timer
  └─ findLocation: LocationManager (NETWORK+GPS, last-known <10min, getCurrentLocation API≥30), 18s timeout

OpenWeatherRepository (Data.kt)  implements WeatherRepository + MapRepository
  ├─ OkHttp (12/20/30s timeouts, 24MB cache, UA "Weather/1.1.1 …")
  ├─ DataCodec (pure static JSON parsers)
  ├─ SharedPreferences "weather" (imperial, cities JSON)
  └─ filesDir/weather-cache/ (forecast-*.json AtomicFile envelopes,
      radar.json 5-min TTL, temperature-*.json 30-min TTL, max 12)

ForecastProjection.kt (pure) — Weather.atTime(now), interpolation between
adjacent hourly samples only, wind-direction circular blend, daylight fallback

Maps.kt (MapLibre GL 13.6.1) — dark style from OpenFreeMap, own OkHttp for
tiles, RainViewer raster radar frames, Circle/Fill/Symbol layers for temp grid
```

Key iOS porting implications: the repository/codec/projection layers are platform-independent logic (~40% of app code, ports near-verbatim); UI and platform glue (Compose, LocationManager, MapLibre) is a rewrite (~60%).
