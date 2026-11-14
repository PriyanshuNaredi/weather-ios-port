# Android Weather APK Reverse Engineering → Native iOS Port

Phase 1: full reverse engineering of the Android weather app (repo: https://github.com/Kian-hdr/Weather).
Phase 2 (native iOS port) is **blocked** until Phase 1 is complete and the user explicitly approves.

## Layout

| Directory | Purpose |
|---|---|
| `00_original/` | Pristine inputs: cloned source (`source/`), APKs (`apk/` self-built, `apk/official/` release), checksums |
| `01_android_build/` | Build logs and reports (tests, lint) |
| `02_apk_analysis/` | Reverse-engineering outputs: manifest, jadx, apktool, resources, native, dependencies |
| `03_runtime_baseline/` | Emulator/device screenshots, recordings, test cases |
| `04_documentation/` | Architecture, findings, API inventory, permissions |
| `05_ios_port/` | (Phase 2 only — empty until approved) |
| `06_build_artifacts/` | apk/ipa artifacts |
| `07_logs/` | Working logs, probe scripts |

Tracking: `PORT_GRAPH.md`, `PROJECT_STATUS.md`, `CHANGELOG.md`, `REPRODUCE.md`.

## Key facts (verified)
- Repo: public, MIT, Kotlin, single module `:app`, branch `main` @ `6267da88`, tag `v1.1.1`
- Gradle 9.3.1 wrapper, AGP 9.1.1, Kotlin 2.2.20, Compose (Material3), OkHttp 4.12.0, MapLibre GL 13.6.1
- App: `dev.kiankonrad.weather`, versionName 1.1.1, versionCode 6, minSdk 28, targetSdk 36, compileSdk 37

## Status
See `PROJECT_STATUS.md`. Phase 1 in progress; build blocked on missing Android SDK (user approval required).
