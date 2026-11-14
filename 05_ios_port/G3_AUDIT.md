# G3 SDK AUDIT — read-only audit of the existing Darwin SDK (2026-11-12)

Nothing was modified. No Xcode download, no `xtool setup`, no Apple auth, no system packages, no device access, no test project created.

## 1–2. Status and manifests

`xtool sdk status`:
```
.artifactbundle
  Flavor: normal
  Version: epoch=4,darwinTools=1.1.0,oam=1.4.1
```

`swift sdk list` (Swift 6.4.2 host toolchain): `darwin`

Manifests in `/home/naredi/.swiftpm/swift-sdks/darwin.artifactbundle`:
- `info.json` — artifactbundle schema 1.0, artifact `darwin`, type `swiftSDK`, `supportedTriples: ["aarch64-unknown-linux-gnu","x86_64-unknown-linux-gnu"]` (host-side triples — the *target* triples live in `swift-sdk.json`).
- `swift-sdk.json` (SwiftPM schema 4.0) declares five targets, each with `swiftResourcesPath`, `toolsetPaths:["toolset.json"]`, SDK root and include/library search paths:
  - `arm64-apple-ios` → `iPhoneOS27.2.sdk`  ← the device target we need
  - `arm64-apple-ios-simulator`, `x86_64-apple-ios-simulator` → `iPhoneSimulator27.2.sdk`
  - `arm64-apple-macosx`, `x86_64-apple-macosx` → `MacOSX27.2.sdk`
- `toolset.json` — linker `ld64.lld`, librarian `llvm-lib`, swiftCompiler extra flags `-enable-cross-import-overlays`, `-use-ld=lld`.

## 3. Version & platforms
- **iOS SDK 27.2** (dirs `iPhoneOS27.2.sdk`, `iPhoneSimulator27.2.sdk`, `MacOSX27.2.sdk`) — newer than the 27.1 pairing named in xtool's docs; same major, fine.
- Bundle version stamp: `epoch=4,darwinTools=1.1.0,oam=1.4.1` (`darwin-sdk-version.txt`).
- Size: **7.0 GB**, 234,218 entries.

## 4. Origin & timestamp
- Installed **2026-11-12 14:58–15:01**, during the G1 `xtool sdk status` verification call — `xtool sdk status` **auto-installs** the SDK if missing (downloaded from xtool's infrastructure; bundled binaries carry original build dates, e.g. `OpenAppleMacrosServer` 2026-10-19, `llvm-lib` 2026-09-21). It is NOT in the Swift 6.4.2 tarball itself (tarball grep: only SwiftBuild xcspecs match). Disk usage outside project: 7.0 GB at `~/.swiftpm/swift-sdks/` — same documented-deviation precedent, deletable via `xtool sdk remove`.
- **Transparency note:** `~/.config/xtool/data/` contains 5 small files (XTLAuthToken 409 B, XTLADIProviderID, XTLLocalUserUID, XTLProvisioningInfo, XTLRoutingInfo), created 14:51–14:52. **Contents were deliberately NOT read** (secrets rule). No interactive auth was performed in our sessions; these appear to be xtool's local ADI/identity scaffolding created by the same status/help calls. If you did not authorize any Apple interaction, we can delete `~/.config/xtool` at G4 time (it gets recreated then) — flagged for your decision.

## 5. Required components (iPhoneOS27.2.sdk)

| Component | Result |
|---|---|
| iPhoneOS SDK | ✅ `iPhoneOS27.2.sdk` + `iPhoneOS.sdk` symlink |
| iPhoneSimulator SDK | ✅ `iPhoneSimulator27.2.sdk` (302 frameworks) |
| UIKit | ✅ 6.9 MB, `.swiftmodule` present |
| SwiftUI | ✅ 8.1 MB, `arm64e-apple-ios.swiftinterface` present |
| MapKit | ✅ 580 KB, `.swiftmodule` present |
| CoreLocation | ✅ 228 KB, Headers + swiftinterface overlay (`CLLocationManager.h` verified) |
| Foundation/Combine/CoreGraphics | ✅ 13 MB / 864 KB / 832 KB |
| Device framework count | 341 `.framework` dirs, 301 `.swiftmodule`s |
| Toolchain utilities | ✅ toolset/bin: `ld64.lld` (+ `-r` static-lib trampoline), `llvm-lib`, `dsymutil`; host toolchain ships clang 21, `ld64.lld`, `lld` |

## 6. Triples & toolset
- Targets declared in `swift-sdk.json` (§1–2 above). Device target `arm64-apple-ios` → `iPhoneOS27.2.sdk`. Module interfaces are `arm64e-apple-ios` slices — the standard convention; the arm64 device target consumes these (Swift falls back to the arm64e interface for arm64).
- Toolset wiring complete: SwiftPM finds linker (`ld64.lld`), librarian (`llvm-lib`); compiler extra flags set for cross-import overlays (needed for `import SwiftUI`+`import MapKit` interplay).

## 7. xtool 1.24.0 discovery
`xtool sdk status` reports the bundle as installed, flavor normal, and `swift sdk list` lists `darwin` — both discovery paths work.

## 8. Missing components
**None identified for compile+link of our app.** Everything in the PHASE2_PLAN dependency list (SwiftUI, MapKit, CoreLocation, Canvas, MKTileOverlay) is present. Remaining gaps are *not SDK* gaps:
- Apple authentication + signing/provisioning → G4 (`xtool setup`/`xtool auth`), as planned.
- Device install → G5 + G2 usbmuxd, as planned.

## Recommendation
**Skip the G3 XIP download.** The installed Darwin SDK 27.2 is complete for compiling and linking the Hello World and the eventual Weather port. Keep `G3_PREP.md` §5 as the documented fallback if the Hello World build fails for an SDK reason.

## Hello World SwiftUI compile test plan (awaiting approval — nothing created yet)
1. `xtool new 05_ios_port/HelloWorld --bundle-id dev.kiankonrad.weather.hello` (project-local SwiftPM package + `xtool.yml`).
2. Compile-only first, no device: `xtool dev build` (or `swift build --swift-sdk darwin` targeting `arm64-apple-ios`) — validates SDK, toolset, linker entirely on Linux.
3. Expect first build to precompile Swift modules (minutes). Capture full output to `06_build_artifacts/logs/`.
4. Only after a successful compile do we proceed to G4 (auth) → G5 (sign + install; needs your device-approval and G2 usbmuxd).
5. All artifacts inside the project; SDK/toolset untouched.
