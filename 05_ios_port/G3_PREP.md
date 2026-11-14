# G3 PREPARATION — Xcode XIP download & SDK extraction (NOT EXECUTED — awaiting approval)

Prepared 2026-11-12 from xtool v1.24.0 official docs (`Documentation/xtool.docc/Installation-Linux.md`) and local verification against the installed toolchain. Nothing has been downloaded, extracted, or authenticated.

## 1. Official download page and requirements
- **Page:** `https://developer.apple.com/download/all/?q=Xcode` (Apple's official Developer Downloads page)
- Requires a **free Apple ID** login in the browser (cannot be curl'd — Apple enforces auth) and **accepting the Apple Developer Program license agreement** the first time.
- **Exact archive:** `Xcode_27.1.xip` — the version xtool 1.24.0's documentation names explicitly.
- Save location for this project: **`07_tools/xcode/Xcode_27.1.xip`** (create the folder; keep the original filename).

## 2. Xcode ↔ xtool compatibility
- xtool 1.24.0's own Linux install doc instructs exactly **Xcode 27.1** (example path `~/Downloads/Xcode_27.1.xip`) — this is the tested/supported pairing for this release. No minimum-version statement is published; matching the documented version exactly is the safe choice.

## 3. Expected space (XIP path)
| Item | Size | Notes |
|---|---|---|
| `Xcode_27.1.xip` download | ≈ 12–16 GB | exact size shown on Apple's download page after login |
| XIP payload unpack (transient, by `xtool sdk build`) | ≈ 30 GB | XIP expands to a full `Xcode.app`; needed only during build |
| Generated Darwin/iOS SDK | ≈ 3–6 GB | xtool's SDK output; installed as artifactbundle |
| Installed SDK (`~/.swiftpm/swift-sdks/darwin.artifactbundle`) | — | already present via Swift 6.4.2, see §6 |
- Peak transient ≈ 45 GB if the XIP path is exercised; WSL has 941 GB free. The XIP can be deleted after SDK generation (recording the decision in PROJECT_STATUS.md before any delete).

## 4. How to download the XIP manually (you perform this; I never touch your credentials)
1. Open `https://developer.apple.com/download/all/?q=Xcode` in your browser.
2. Sign in with your Apple ID (2FA as usual) — **do not share the password with me or put it in any project file**.
3. Accept the license agreement if prompted.
4. In the results, locate **Xcode 27.1** and click the download icon for `Xcode_27.1.xip` (the list shows its exact byte size — record it).
5. Move the completed file to `07_tools\xcode\Xcode_27.1.xip` inside the project (copy, don't leave it only in Downloads).
6. Tell me when it's placed; I will verify size + SHA-256 against Apple's page values where shown before use.

## 5. SDK extraction procedure (only if/when approved — G4)
Primary documented flow (`xtool setup`):
1. `xtool setup` → interactive Apple login (mode `1: Password`). **I stop at the credential prompt; you type credentials/2FA interactively.** Credentials go only to Apple; never stored in project files/scripts/logs.
2. When prompted `Path to Xcode.xip:` → provide `07_tools/xcode/Xcode_27.1.xip`.
3. xtool extracts the XIP and generates + installs the iOS Swift SDK.
4. Verify: `swift sdk list` → `darwin`.
Project-local equivalent, skipping auth (no Apple login needed for SDK build alone):
`xtool sdk build 07_tools/xcode/Xcode_27.1.xip 07_tools/xtool-sdk/`
then `swift sdk install --json <output>/sdk.json` (paths confirmed from `xtool sdk build --help`: `<path> <output-dir>`; install step verified at run time).

## 6. Discovery: the Darwin SDK may already be present — XIP possibly NOT needed
`xtool sdk status` (run 2026-11-12, xtool 1.24.0) reports:
```
Darwin SDK is installed
  Path: /home/naredi/.swiftpm/swift-sdks/darwin.artifactbundle
  Flavor: normal
  Version: epoch=4,darwinTools=1.1.0,oam=1.4.1
```
`swift sdk list` → `darwin`. Swift 6.4.2 appears to bundle a Darwin SDK artifactbundle (installed into `~/.swiftpm/swift-sdks/` during toolchain extraction). **Implication:** the Xcode XIP (G3) may be unnecessary — xtool's XIP flow predates toolchain-bundled SDKs. Proposal: defer G3; attempt the Hello World build against the bundled SDK first (still gated on G4 auth + device access per plan). Keep this document as the fallback procedure if the bundled SDK fails to produce an installable app.
- SDK storage location: `~/.swiftpm/swift-sdks/darwin.artifactbundle` (WSL ext4, outside project — same documented-deviation precedent; size to be measured; deletable via `xtool sdk remove`).

## 7. Temporary GPG keyring (outside project) — record & cleanup
- Location: `$HOME/.gpg-weather/` in WSL (`/home/naredi/.gpg-weather/`, ext4, ≈ 1–2 MB) — temporary GPG keyring used once to verify the Swift 6.4.2 tarball signature (gnupg refuses keyrings on `/mnt/c` drvfs).
- Contents: swift.org's public key bundle only (`all-keys.asc` import). **No private keys, no credentials.**
- Cleanup (when approved — rule 3 forbids unapproved deletes; this keyring is a cache created by me, so deletion is safe):
  `rm -rf /home/naredi/.gpg-weather`
- Recommendation: leave in place until Phase 2 toolchain verification work is done (re-verification of future downloads reuses it), then clean up in the Phase 2 final cleanup pass.

## Current gate state
- G2 (usbmuxd/libimobiledevice-utils): **deferred by you** until physical-device deployment is needed.
- G3 (XIP download): prepared, not executed; may be unnecessary per §6 — awaiting your call.
- G4 (`xtool setup` auth): not executed.
- G5: not executed.
