# API contracts (verified from OpenWeatherRepository, no keys required)

| Provider | Endpoint | Purpose | Key params |
|---|---|---|---|
| Open-Meteo | `GET https://api.open-meteo.com/v1/forecast` | Current + hourly + daily weather; also 7×7 temperature grids | `current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m,wind_gusts_10m,wind_direction_10m,pressure_msl`; 13 hourly vars; 8 daily vars; `forecast_days=10&timezone=auto&timeformat=unixtime`; grid: `cell_selection=nearest` |
| Open-Meteo | `GET https://air-quality-api.open-meteo.com/v1/air-quality` | AQI | `current=european_aqi,us_aqi,pm2_5,pm10` |
| Open-Meteo | `GET https://geocoding-api.open-meteo.com/v1/search` | City search | `name=<q>&count=12&language=en` |
| RainViewer | `GET https://api.rainviewer.com/public/weather-maps.json` | Radar frame timeline | frames under `/v2/radar/<path>` (PNG tiles) |
| OpenFreeMap | `https://tiles.openfreemap.org/styles/dark` | Map style + vector tiles | consumed by MapLibre GL; OSM/OpenMapTiles attribution |

Common headers: `User-Agent: Weather/1.1.1 (https://github.com/Kian-hdr/Weather; dev.kiankonrad.weather)`.
HTTP cache: 24 MB OkHttp cache in cacheDir `provider-http`. Timeouts: connect 12s / read 20s / call 30s. Rate-limit (HTTP 429) gets a distinct user-facing message.
iOS note: all endpoints are plain JSON over HTTPS with no auth — directly reusable with URLSession.
