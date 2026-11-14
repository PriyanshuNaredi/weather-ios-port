# REA_SETUP_REPORT.md — REA integration assessment (2026-11-13)

Mission §2–§3: investigate REA before installing, install in isolation, verify it works on
the original APK, and never change agent/global configuration. **Status: complete.**

## 1. What REA is

- Package `rea-agents@6.9.0` (npm), MIT. CLI (`scripts/rea.mjs`) + optional MCP server.
- Official repo docs (github.com/morluto/rea) reviewed before install. Tarball downloaded
  to `review/rea-agents-6.9.0.tgz` and **inspected before install**: clean entry script,
  hard Node runtime admission, Android modules under `dist/android` / `dist/apktool` /
  `dist/apkSignature`; the jadx provider wraps the unmodified upstream jar
  `jadx-headless-mcp` 0.7.1 (bridge `bridge/android/ReaJadxBridge.java` only launches it).
- What `npx rea-agents setup` would do (deliberately **NOT run**): register an MCP server
  entry into agent config files (`.claude.json`, `.codex/config.toml`, `.zcode/cli/config.json`,
  VS Code / Gemini / Claude Desktop configs) and install a skill. No approval was given,
  so no config was touched; REA is used as a plain CLI.

## 2. Installation (fully project-local)

- System Node is 25.1.0 — rejected by REA's engines gate (`^22.23.4 || ^24.22.1 || >=26.12.1`,
  enforced with exit before any command). **No system package was modified.** Instead
  portable Node v24.22.1 win-x64 was extracted to `07_tools/node-v24.22.1-win-x64/`.
- `npm install --prefix 07_tools/rea-analysis/rea rea-agents@6.9.0` — node_modules only
  inside the project. npm warned that optional native dep `frida`'s install script was
  not run (install-scripts blocked); dynamic instrumentation is not needed for APK static
  analysis, so it was left unbuilt (per "do not blindly install optional dependencies").
- jadx-headless-mcp jar placed at `07_tools/rea-analysis/jadx-headless-mcp-0.7.1-all.jar`
  (42,619,858 bytes, SHA-256 `6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75`),
  wired via env `REA_JADX_MCP_JAR`. Healthy per `rea doctor` (heap 5984 MiB, timeout 120 s).
- apktool wired via env `REA_APKTOOL_COMMAND` pointing at project-local
  `apktool-launcher.cmd` (single launcher path required). **Windows caveat:** the project
  path contains `→` (U+2192) which cmd.exe's codepage corrupts — both literals and `%~dp0`;
  the wrapper therefore uses 8.3 short paths. Verified working: REA reports apktool 2.12.1.
- `rea doctor` registration checks show the expected safe state (no agent config drift).
- All REA invocations: `"$NODE" "$REA" <command> <apk> --json`, NODE = the portable node.exe.
  No PATH changes, no agent registration, nothing outside the project root.

## 3. REA commands actually exercised (all with Evidence IDs, `fell_back: false`)

| Command | Output | Key result |
|---|---|---|
| `inspect-apk-signature` | out-signature.json | APK v2 signed only; cert SHA-256 `d3370a79…f5c3` (matches README); subject C=DE/O=Personal/CN=Weather Personal |
| `inspect-android-package` | out-package.json | dev.kiankonrad.weather 1.1.1 (versionCode 6), minSdk 28 / targetSdk 36, 19,287 classes, 202 resources, single exported LAUNCHER `MainActivity`; permissions INTERNET + coarse/fine location + network states; Vulkan required (MapLibre) |
| `search-android-classes` | out-classes.json | 43 app classes (23 non-lambda) — the entire app surface |
| `inspect-android-class` ×8 | out-class-*.json | full method inventories for MainActivityKt, MapsKt, DataKt, models + 4 repositories/projections |
| `inspect-android-method` ×17 | out-m-*.json | full decompiled bodies: WeatherApp, ForecastPage, CityScreen, MetricScreen, SettingsScreen, WeatherApp$add/$locate, findLocation; OWR cached/write/read/saveCities/get/radar/temperatures; MapsKt prepareMap/clearWeatherLayers |
| `inspect-apktool-client` | out-apktool-client.json | apktool 2.12.1 recognized via wrapper (fixed launcher verified) |
| `decode-android-resources` | out-resources.json | 105 string files × 80 locales; manifest re-decoded |

Structural markers were counted programmatically from the decompiled bodies
(`extract-markers.cjs`, `extract-repo-markers.cjs`) — bytecode is compiler-transformed,
so counts of Compose primitives (not invented readings) are the evidence.

## 4. REA capabilities judged useful / not useful for this project

**Useful (used):** APK signature/package inspection; class search; class and
single-method decompilation (fast, evidence-bundled, overload-safe); apktool client check;
resource decoding. These cover §4 areas A–E statically.

**Not used / not available on this machine:** ADB tools (no Windows adb; the Linux
platform-tools in `07_tools/android-sdk-linux` only run under WSL, which lacks node/java) →
§6 runtime analysis was NOT possible; Hopper/Ghidra/IDA providers (native-binary analysis,
irrelevant for a JVM APK); frida-based dynamic instrumentation (unbuilt, no device anyway).

## 5. Security & hygiene statement

- Nothing installed system-wide; no global PATH change; no agent config modified.
- Downloaded package and jar were hash-checked/inspected before use.
- No device was touched; no credentials handled (the REA setup path that would write to
  agent configs was never executed).
