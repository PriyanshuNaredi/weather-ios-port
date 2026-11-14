#!/bin/bash
P="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"

# --- PROJECT_STATUS.md ---
{
printf '\n---\n\n'
printf '%s\n' "## 2026-11-13 — Unsigned IPA packaging test (HelloWorld, no signing, no Apple services)"
printf '%s\n' "- \`xtool dev build --help\` inspected first: \`--sign\` is a separate opt-in flag, \`--ipa\` packages a .ipa; without \`--sign\` no codesigning/Apple Developer Services is invoked — confirmed empirically (no auth calls, no cert/profile activity; \`XTLAuthToken\` untouched, never read)."
printf '%s\n' "- Command: \`xtool dev build --ipa\` in ext4 scratch \`~/hello-src\` (mirrored from project; drvfs cannot hold executables). \`Build complete! (16.07 secs)\` + \`Packaging...\` → \`Wrote to /home/naredi/hello-src/xtool/HelloWorld.ipa\` (96 KB). Log: \`06_build_artifacts/logs/hello-ipa-build-20261113-*.log\`."
printf '%s\n' "- Verification: ZIP contains exactly \`Payload/HelloWorld.app/{HelloWorld (92,648 B), Info.plist}\`; Info.plist: CFBundleIdentifier dev.kiankonrad.weather.hello, CFBundleExecutable HelloWorld, MinimumOSVersion 17.0, platform iPhoneOS; executable = Mach-O 64-bit arm64 (magic cf fa ed fe, NOUNDEFS|DYLDLINK|TWOLEVEL|PIE); **unsigned**: 0 × LC_CODE_SIGNATURE, no _CodeSignature/, no embedded.mobileprovision."
printf '%s\n' "- IPA SHA-256: \`98b123e85425624e3796cdf09d151552973669f0910dc0afe2f76b573191aa51\` — copied to \`06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa\` (new dir; no existing files overwritten)."
printf '%s\n' "- Clarification: packaging ≠ installation. This IPA cannot launch on a device until signed (G5) — physical install requires G2 usbmuxd + device access, still pending approval. No iPhone touched."
printf '%s\n' "- Scripts: \`07_tools/ipa-help.sh\`, \`ipa-build.sh\`, \`ipa-verify.sh\`. **STOP after verification, per instruction.**"
} >> "$P/PROJECT_STATUS.md"

# --- CHANGELOG.md ---
{
printf '%s\n' ""
printf '%s\n' "## Session 2026-11-13"
printf '%s\n' "- G4 completed: Apple authentication via \`xtool auth login\` (mode 1 Password) run by the user in their own terminal; \`xtool auth status\` exit 0; XTLAuthToken refreshed (perms 600, contents never read); no provisioning/device activity. Recorded in PROJECT_STATUS.md + G4_PREP.md."
printf '%s\n' "- Unsigned IPA packaging test: \`xtool dev build --ipa\` (no \`--sign\`) from ext4 scratch → \`Payload/HelloWorld.app\` verified (Mach-O arm64, unsigned — no LC_CODE_SIGNATURE/_CodeSignature/mobileprovision); IPA SHA-256 98b123e8…1aa51 archived at \`06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa\`. Packaging ≠ installation; no device touched."
} >> "$P/CHANGELOG.md"

# --- REPRODUCE.md ---
{
printf '%s\n' ""
printf '%s\n' "## 3. Reproduce the unsigned iOS IPA (Phase 2, no signing / no Apple services)"
printf '%s\n' '```bash'
printf '%s\n' '# script: 07_tools/ipa-build.sh (build) + ipa-verify.sh (verify)'
printf '%s\n' '# Requirements: Swift 6.4.2 + xtool 1.24.0 (07_tools), Darwin SDK 27.2 (~/.swiftpm/swift-sdks), WSL Ubuntu.'
printf '%s\n' '# Build runs from ext4 scratch ~/hello-src because /mnt/c drvfs cannot hold executable Mach-O files.'
printf '%s\n' 'MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/ipa-build.sh"'
printf '%s\n' '#   → xtool dev build --ipa  (NOTE: --sign omitted → unsigned, no Apple Developer Services calls)'
printf '%s\n' 'MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- bash "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/ipa-verify.sh"'
printf '%s\n' '#   → ZIP structure Payload/HelloWorld.app, Info.plist fields, Mach-O arm64 check,'
printf '%s\n' '#     LC_CODE_SIGNATURE count (0), _CodeSignature/mobileprovision absence, SHA-256,'
printf '%s\n' '#     copies IPA to 06_build_artifacts/unsigned-ipa/HelloWorld-unsigned.ipa'
printf '%s\n' '```'
printf '%s\n' 'Observed (2026-11-13): `Build complete! (16.07 secs)`; `Wrote to /home/naredi/hello-src/xtool/HelloWorld.ipa` (96 KB); IPA SHA-256 `98b123e85425624e3796cdf09d151552973669f0910dc0afe2f76b573191aa51`. The IPA is UNSIGNED — it will not launch on a device until signed (G5).'
} >> "$P/REPRODUCE.md"
echo DONE
