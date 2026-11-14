# G5 COMPILE TEST — native iOS compilation & linking WITHOUT signing (2026-11-12)

Approved scope: Hello World SwiftUI app, compile+link only. No Apple auth, no signing, no IPA, no device access, no system packages, no SDK replacement.

## Result: ✅ SUCCESS — compilation and linking succeeded independently of signing

## 1. Project
- `05_ios_port/HelloWorld/` — created via `xtool new HelloWorld --skip-setup` (SwiftPM package, tools 6.0, SwiftUI template: `HelloWorldApp.swift` (@main App, WindowGroup) + `ContentView.swift`).
- `xtool.yml` bundle ID set to **`dev.kiankonrad.weather.hello`** (verified in built `Info.plist`: `CFBundleIdentifier = dev.kiankonrad.weather.hello`).
- Package declares platforms `.iOS(.v17)`; product: library `HelloWorld` (xtool's app-bundle convention).

## 2. Toolchain / SDK
| Item | Value |
|---|---|
| Host compiler | Swift 6.4.2 (swift-6.4.2-RELEASE, x86_64-unknown-linux-gnu) |
| Build driver | xtool 1.24.0 `dev build` (SwiftPM + xcbuild) |
| SDK | Darwin SDK 27.2 (`~/.swiftpm/swift-sdks/darwin.artifactbundle`) |
| Target triple | `arm64-apple-ios` (xtool default; `Debug-iphoneos` products dir) |
| Linker | `ld64.lld` via toolset.json; librarian `llvm-lib` |
| Auth/signing | none (`xtool dev build` without `--sign`) |

## 3. Commands executed (build scripts in `07_tools/`: g5-new.sh, g5-build.sh, g5-build2.sh)
1. `xtool new HelloWorld --skip-setup` → template generated.
2. First attempt, in project on /mnt/c: `xtool dev build` → **`Build complete! (54.00 secs)`**, 98 build steps, 0 errors. xtool's post-build move of `HelloWorld.app` to /mnt/c **failed** (EPERM — drvfs rejects executable Mach-O files; macOS copy semantics). Working `.app` was in xtool's ext4 staging (auto-cleaned).
3. Recovery: source mirrored to `~/hello-src/` (WSL ext4 — same documented-deviation precedent as the Gradle caches; source of truth stays in the project) and rebuilt: **`Build complete! (18.10 secs)`**; `Wrote to /home/naredi/hello-src/xtool/HelloWorld.app`.

## 4. Compiler/linker evidence
xcbuild does not echo invocations; exact flags recovered from persisted build files (`.build/out/Intermediates.noindex/.../Objects-normal/arm64/`):
- **Common compiler args** (`*common-args.resp`): `-fmodules -gmodules -fmodules-cache-path=... -fpascal-strings -O0 -DSWIFT_PACKAGE -DDEBUG=1 -g -I... -F.../PackageFrameworks -iframework .../iPhoneOS.platform/Developer/Library/Frameworks -iframework .../SDKs/iPhoneOS27.2.sdk/Developer/Library/Frameworks -fmodule-map-file=.../HelloWorld.modulemap -DXcode`
- **Link inputs** (`HelloWorld-App.LinkFileList`): `ContentView.o`, `HelloWorldApp.o` (arm64 objects).
- **Module dependencies** reference SDK frameworks: `iPhoneOS.sdk/System/Library/Frameworks/{Accessibility,CFNetwork,CoreAudio,...}.framework/Modules/module.modulemap`.
- Standalone `swift build --swift-sdk darwin --triple arm64-apple-ios` cannot target iOS from a manifest declaring `.iOS` (error `unable to find platform for 'iphoneos'`) — xtool's xcbuild driver is required; logged in `06_build_artifacts/logs/hello-swift-build-verbose.log`.

## 5. Binary verification (executable `HelloWorld`, 92,648 B)
- `file`: **`Mach-O 64-bit arm64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>`** — iOS ARM64 Mach-O, NOT Linux ELF.
- Magic bytes (`od -N 32`): `cf fa ed fe 0c 00 00 01 ... 02 00 00 00` — `MH_MAGIC_64`, cputype 0x0100000C (arm64), filetype 2 (MH_EXECUTE).
- `llvm-objdump -f`: `file format mach-o arm64`.
- SHA-256: `25948c8da8fe74e2ca459ce7f24c6fc41f518a00c1db1a170722068d5e4469aa` (identical in ext4 and in the project archive copy).
- The executable is **unsigned** (no signing was requested); it is not launchable on-device until G4/G5 signing.

## 6. Duration, errors, warnings
- Cold build (drvfs): 54.00 s; warm ext4 rebuild: 18.10 s. Wall time incl. staging ≈ 78 s / 38 s.
- Errors: **0**. Warnings: 33, all `Stale file ... outside of the allowed root paths` (harmless residue of the abandoned drvfs scratch; none from compilation).

## 7. Artifacts
- `06_build_artifacts/hello-world-ios-binary/HelloWorld-App/` — `HelloWorld` (Mach-O) + `Info.plist` (archived byte copy).
- `06_build_artifacts/logs/hello-build-20261112-2242*.log` (drvfs attempt), `hello-build-ext4-20261112-224627.log` (successful), `hello-swift-build-verbose.log`.
- Scripts: `07_tools/g5-new.sh`, `g5-build.sh`, `g5-build2.sh`, `g5-verify*.sh`, `g5-verbose*.sh`, `g5-args.sh`.

## 8. Deviations / housekeeping (rule 7)
- `~/hello-src/` — build scratch on ext4 (drvfs cannot store executable files). Deletable: `rm -rf ~/hello-src`.
- Broken partial `.app` from the failed drvfs move exists under `05_ios_port/HelloWorld/.build/out/Products/Debug-iphoneos/HelloWorld-App` and a stub dir at `05_ios_port/HelloWorld/xtool/`; harmless build residue, left untouched per rule 3 (no deletes) — can be cleaned later with the `.build` dir.
- `~/.config/xtool/data/XTLAuthToken` — inspected **metadata only** per your instruction: perms 644, owner naredi:naredi, 409 B, mtime=ctime 2026-11-12 14:52:34, parent dirs 755 owned by naredi. Contents NOT read; file NOT modified/deleted. Note: 644 means readable by any local user of the WSL distro.
- Android sources untouched; all new project files inside the project root.

## Gate state
- G1 ✅ · G2 deferred (device time) · G3 skipped by approval (XIP fallback documented) · **G5 compile-only ✅ (this document)** · G4 auth + G5 sign/install/device: awaiting your approval.
