# G4 — Apple authentication (PREPARED 2026-11-12; **EXECUTED & COMPLETED 2026-11-13**)

**Outcome (2026-11-13):** user ran `xtool auth login` (mode 1 Password) in their own WSL terminal via `07_tools/g4-auth-login.sh` (no tee/redirect/logging in the script); credentials entered privately by the user, never captured or automated. Verification: `xtool auth status` → **exit 0**; `XTLAuthToken` refreshed (409→412 B, mtime 2026-11-12 23:45, perms 600; contents never read); `XTLProvisioningInfo`/`XTLRoutingInfo` untouched → no device registration, no provisioning profile. Original prep content below retained for reference.

## 1. XTLAuthToken hardening (done, contents never read)
| | Before | After |
|---|---|---|
| `~/.config/xtool/data/XTLAuthToken` | 644 | **600** (owner naredi:naredi, 409 B, mtime unchanged) |
| `~/.config/xtool/data/` | 755 | **700** |
- `chmod 600` + `chmod 700` executed and verified via `stat`; contents not read or printed.

## 2. Official authentication workflow (verified against xtool 1.24.0 docs @ tag 1.24.0)
- `xtool setup` = `xtool auth && xtool sdk`. The SDK half is **already satisfied** (Darwin SDK 27.2 installed), so when SDK steps are auto-skipped the effective remaining work is authentication. We can also run **`xtool auth`** alone (subcommands: `login` default / `logout` / `status`) — equivalent, skips any SDK prompt entirely.
- Login modes (interactive `Select login mode`):
  - **0: API Key** — paid Apple Developer Program only → not applicable to us.
  - **1: Password** — works with any Apple ID (free included); prompts for **email + password + 2FA**. Docs state credentials are "only sent to Apple" and suggest building xtool from source to verify; password mode uses **private Apple APIs**, so xtool's docs suggest a throwaway Apple ID for extra caution.
- First run also creates xtool's local identity scaffolding (`~/.config/xtool/data/XTL*` — the files already present from 14:52).
- Device pairing/provisioning (`xtool dev`) is a **later, separate** step (G5 device): device registration + certificate + App ID + provisioning profile happen automatically then, not during auth.

## 3. Exact interaction required from you (the only manual steps)
1. I start `xtool auth login` in the WSL terminal and **stop touching it**.
2. It prompts `Select login mode:` → **you type `1`** (Password).
3. It prompts for your **Apple ID email** → you type it.
4. It prompts for your **password** → you type it (invisible). It goes only to Apple — never into a project file, script, or log.
5. It prompts for your **2FA code** (sent to your trusted devices) → you type the 6 digits.
6. Success looks like a completion message; then I run `xtool auth status` (no credentials involved) to record that authentication exists. If you ever want to revoke: `xtool auth logout`.

## 4. Authentication checklist (G4)
- [x] You approved G4 explicitly (2026-11-12).
- [x] You chose the Apple ID and completed mode/email/password/2FA interactively in your own terminal (2026-11-13).
- [x] Verified with `xtool auth status` (exit 0) — status only, no credential material recorded.
- [x] No Xcode download (G3 skipped), no usbmuxd (G2 deferred), no device registration, no Weather port start.

## 5. Free-account signing limitations (Apple policy; verified in Phase 2 planning)
| Limitation | Detail |
|---|---|
| App expiry | Apps signed with a free (personal team) profile **expire after 7 days**; they stop launching until re-signed/reinstalled. Weekly re-install for an evaluation app is acceptable. |
| App ID cap | **3 App IDs per 7-day window** on free accounts (we will use 1: `dev.kiankonrad.weather.hello` now, `dev.kiankonrad.weather` for the port later). |
| Device cap | Free profile allows limited registered devices (Apple's guidance: up to 10 app-limited devices; practically 1–2 devices per profile). |
| Device registration | The iPhone's UDID must be registered into the provisioning profile (xtool automates this at first device deploy). |
| Developer Mode | iOS 16+ requires **Settings → Privacy & Security → Developer Mode → On** (reboot + confirm) before any self-signed app launches. |
| Certificate | 1 free development certificate; xtool creates/rotates it automatically during device deploy. |
| No push/background entitlements, no TestFlight, no App Store | Only local development installs. Fine for our port (Open-Meteo HTTP needs no special entitlements; location permission works normally). |

## 6. Secrets handling (rule 5, standing)
- Your email/password/2FA are typed by **you**, at xtool's interactive prompt, and go only to Apple.
- I will never place them in project files, scripts, logs, or chat; build logs are captured with credentials never appearing (xtool does not echo them).
- Auth state lives only in `~/.config/xtool/data/` (now 700/600) outside the project; removable with `xtool auth logout` (+ delete the dir if desired).

## Restrictions honored in this preparation
No authentication, no Xcode, no usbmuxd, no device access, no Weather port work. Only file-permission changes above + documentation.

**STOP — awaiting your explicit approval to run `xtool auth login`.**
