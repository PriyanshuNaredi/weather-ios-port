# Weather for iOS — unsigned IPA

Built by CI from the tag's commit. **This IPA is unsigned** — no Apple ID, certificate or
provisioning profile is bundled. It cannot be installed with Finder, Xcode or a plain
`.ipa` double-click, and it will not run on its own.

## Install it with SideStore or LiveContainer

Both run on-device, sign the app with **your own Apple ID**, and re-sign it automatically
before the 7-day development certificate expires.

| Tool | What it is | Link |
|---|---|---|
| **SideStore** | Untethered AltStore fork: installs any `.ipa` with just your Apple ID, refreshes apps in the background | <https://sidestore.io/> · [docs](https://docs.sidestore.io/docs/installation/install) · [GitHub](https://github.com/SideStore/SideStore) |
| **LiveContainer** | Runs apps inside a container so they don't each consume one of your 3 free app slots; ships a SideStore build (`LiveContainer + SideStore`) | <https://github.com/LiveContainer/LiveContainer> · [docs](https://livecontainer.github.io/) · [LC + SideStore](https://livecontainer.github.io/docs/installation/lc_sidestore) |

Typical flow (SideStore): install SideStore once with a computer → connect it once so
`LocalDevVPN` is trusted → **My Apps → + → select the downloaded `.ipa`** → SideStore signs and
installs it.

### Free Apple ID limits, so nothing surprises you

- 3 active apps at a time (SideStore itself counts as one) — LiveContainer avoids the
  per-app slot cost.
- 10 new App IDs per 7 days.
- Certificates last 7 days and must be refreshed; SideStore/LiveContainer do this in the
  background over Wi-Fi.
- A paid Apple Developer account lifts the slot limit and extends certificates to a year.

## Verify the download

Each release ships a `.sha256` next to the `.ipa`:

```sh
shasum -a 256 -c Weather-*-unsigned.ipa.sha256
```

## What is inside

- Release build for `arm64` device, minimum iOS 17.0.
- Bundle `legal/` notices and the app icon (rendered from the original Android icon vector).
- No radar/temperature diagnostics, no `#if DEBUG` views.

Source and licences: see `CREDITS.md` in the repository. The app is a port of
[Weather for Android](https://github.com/Kian-hdr/Weather) by Kian Konrad (MIT).