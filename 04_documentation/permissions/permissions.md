# Permissions & privacy (official APK, verified via aapt2/apktool)

| Permission | Declared in source manifest | Merged by library | Purpose | iOS equivalent |
|---|---|---|---|---|
| INTERNET | yes | — | all HTTP | none needed (default) |
| ACCESS_COARSE_LOCATION | yes | — | city-level locate | `NSLocationWhenInUseUsageDescription` |
| ACCESS_FINE_LOCATION | yes | — | precise locate | same, fine accuracy |
| ACCESS_NETWORK_STATE | no | yes (MapLibre) | tile connectivity checks | none needed |
| ACCESS_WIFI_STATE | no | yes (MapLibre) | connectivity checks | none needed |
| DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION | no | yes (androidx) | internal receiver protection | n/a |

Privacy posture: no telemetry/analytics/ads (verified in dex dump); location used transiently, only chosen city persisted locally; `allowBackup=false`, `usesCleartextTraffic=false`, data-extraction rules present. Location usage maps to a single iOS key: `NSLocationWhenInUseUsageDescription`.
