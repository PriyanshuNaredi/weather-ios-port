#!/bin/bash
F="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/PROJECT_STATUS.md"
cat >> "$F" <<'EOF'

---

## 2026-11-12 — G4 preparation (auth NOT executed; awaiting explicit approval)

- XTLAuthToken hardened: perms 644 → **600**; parent `~/.config/xtool/data/` 755 → **700**; verified via `stat` (owner naredi:naredi, 409 B, mtime unchanged). **Contents never read or printed.**
- xtool 1.24.0 auth workflow verified against official docs @ tag 1.24.0 (Documentation/xtool.docc/Installation-Linux.md): `xtool setup` = `xtool auth && xtool sdk`; login mode **0: API Key** (paid only — N/A) vs **1: Password** (any Apple ID; email+password+2FA; uses private Apple APIs — docs suggest a throwaway Apple ID); credentials "only sent to Apple". `xtool auth` subcommands confirmed live: login/logout/status. `xtool auth status` is credential-free and will be the post-login verification.
- Free-account signing limits documented (7-day app expiry, 3 App IDs per 7 days, device registration, Developer Mode, 1 dev cert, no push/TestFlight/App Store).
- New files: `05_ios_port/G4_PREP.md` (checklist, exact user interaction, limitations, secrets commitments), `07_tools/g4-token.sh`, `07_tools/g4-authhelp.sh`.
- Honored: no auth, no Xcode, no usbmuxd, no device access, no Weather port work. **STOP — awaiting explicit approval for `xtool auth login`.**
