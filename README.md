<div align="center">

# Tanzanite-HyperUnlocked
<img src="https://img.shields.io/github/last-commit/itswill00/HyperUnlocked?style=flat-square&color=FF5A54&cacheSeconds=100" alt="GitHub last commit">
<img src="https://img.shields.io/github/release-date/itswill00/HyperUnlocked?style=flat-square&label=latest%20release&color=FF5A54&cacheSeconds=100" alt="GitHub Release Date">
<img src="https://img.shields.io/github/downloads/itswill00/HyperUnlocked/total?style=flat-square&label=total%20downloads&color=FF5A54&cacheSeconds=100" alt="GitHub Downloads"><br>

**Tanzanite-HyperUnlocked** — high-end Xiaomi features tuned for **Redmi Note 14 4G (tanzanite)**.
<br>By **@noticesa**, based on [HyperUnlocked by **ukriu**](https://github.com/ukriu/HyperUnlocked) (rebranded with permission).
</div>

## Table of contents

- [About](#about)
- [Features](#features)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building from source](#building-from-source)
- [Project structure](#project-structure)
- [Credits](#credits)
- [License](#license)

## About

Tanzanite-HyperUnlocked is a Magisk / KernelSU / APatch module that unlocks
high-end HyperOS features on the Redmi Note 14 4G (`tanzanite`). It applies a
curated set of system properties, `device_features` XML unlocks, and runtime
resource overlays — with safe, non-interactive defaults so one install works
across the whole community (HyperOS 1.0 / 2.x / 3.0).

> [!NOTE]
> This is a device-tuned variant, not a universal module. Flags that are
> placebo, duplicated, or risky on tanzanite (branding flips, hardware spoofs,
> screen-resolution mod, redundant overlays) have been stripped out. See
> [Configuration](#configuration) for what gets applied.

## Features

| Area | What you get | Notes for tanzanite |
| --- | --- | --- |
| System | High-end mode (`deviceLevelList v:1,c:3,g:3`), advanced blurs, smooth corners, shadows | Verified via `getprop` after install |
| Display | Ripple charging animation, sunlight mode, expert options | Refresh rates stay native (60/90/120 Hz) |
| Camera | Extra modes and options (4K, HFR, manual, watermark, portrait helpers, …) | App-level toggles; needs no extra hardware |
| Gallery | Dolby/HDR/print/compress/media-feature flags | — |
| Power & battery | Extra battery profiles and power modes, AI prediction flags | `support_power_mode` confirmed on-device |
| Quick Settings | Mic toggle, Camera toggle, Extra Dim, Data Saver, GMS tiles | Added automatically on install |
| Wallpapers | Super Wallpapers, video-depth marker | Overlay idmap verified active |
| Always-on display | Fullscreen AOD support | Auto-skipped on HyperOS 3 (bootloop guard) |

Fine-grained toggles (blur, high-end props, screenshot-blur, LEICA spoof,
Dynamic Island, device level) stay available in the WebUI.

## Compatibility

| Device | Codename | ROMs | Status |
| --- | --- | --- | --- |
| Redmi Note 14 4G | `tanzanite` | HyperOS 1.0 / 2.x / 3.0 (tested on 2.0.207 Global) | ✅ Supported |

> [!WARNING]
> Other codenames are not tuned for. The installer warns and continues, but
> results are untested — use the WebUI to adjust, at your own risk.

Requirements:

- A Xiaomi device running MIUI or HyperOS, rooted with
  [Magisk](https://github.com/topjohnwu/Magisk),
  [KernelSU](https://github.com/tiann/KernelSU), APatch, or similar.
- On KernelSU (or forks): a [metamodule](https://kernelsu.org/guide/metamodule.html).
  A `magicmount` metamodule is recommended — some bits may break on `overlayfs`.
- `Umount modules by default` must be **disabled**.

## Installation

1. **Coming from the old `HyperUnlocked`?** Uninstall it first (your stock
   backups are kept and get migrated automatically on the next step).
2. Download `Tanzanite-HyperUnlocked.zip` from
   [releases](https://github.com/itswill00/HyperUnlocked/releases/latest).
3. Install the zip from your root manager app.
4. **Reboot.** Props and overlays only take effect after a reboot.
5. (Optional) Open the WebUI to fine-tune. See [Configuration](#configuration).

> [!TIP]
> Installing from recovery is not recommended. If you do, press the module's
> **Action** button in your manager afterwards to finish the setup.

## Configuration

Fresh installs apply these fixed defaults (no volume-key prompts, so community
installs can't mis-press):

| Setting | Default | Change later via |
| --- | --- | --- |
| System blur (live blur) | ON | WebUI |
| High-end mode props | ON | WebUI |
| Screenshot-blur overlay | OFF (enable it if live blur lags on Mali-G57) | WebUI |
| Extra QS tiles | Added | WebUI (`extra_tiles`) |
| LEICA camera spoof | OFF (needs Camera v6.4+) | WebUI |
| Dynamic Island | Follows current state (OFF pre-HyperOS 3) | WebUI |

WebUI access:

- KernelSU or a fork: built-in WebUI support.
- Otherwise: [WebUI X](https://github.com/MMRLApp/WebUI-X-Portable) or
  [MMRL](https://github.com/MMRLApp/MMRL).
- Staged values live in `/data/adb/Tanzanite-HyperUnlocked/config` until you
  press **Apply staged settings**. A **Soft Restart** button applies prop-only
  changes without a full reboot.

## Building from source

On-device (Termux) or any Linux shell:

```sh
./build.sh
```

Requirements: `aapt`, `zipalign`, `apksigner`, `openssl`, `zip`, `java`,
plus `node` + `npm` for the Vue WebUI (`webui/` sources rebuild
automatically when newer than the last build).
The script compiles the overlays, signs them with the repo platform keys, and
writes `Tanzanite-HyperUnlocked.zip` next to itself. (The repo's
`tools/aapt`/`zipalign`/`signapk.jar` are x86_64-only; the script falls back
to native tools where they can't execute.)

## Project structure

```text
module/
  customize.sh / action.sh / uninstall.sh   # installer entry points (thin)
  webui.sh                                  # WebUI backend (called verbatim)
  webroot/                                  # config.json + built index.html
  common/
    apply.sh                                # single source of install defaults
    utils.sh                                # core helpers
    xml.sh                                  # device_features unlock lists
    all.prop                                # system prop groups
webui/                                      # Vue 3 + Vite source of the WebUI
  src/App.vue                               # 1:1 port of the classic WebUI
  src/assets/                               # Material You theme (unchanged look)
overlay/                                    # overlay sources (built by build.sh)
tools/                                      # aapt/signapk/keys (CI use)
```

## Credits

- [ukriu](https://github.com/ukriu/HyperUnlocked) — original HyperUnlocked.
  Rebrand and redistribution permitted by the author; original copyright kept.
- **@noticesa** — tanzanite tuning, structure, WebUI polish, and this variant.
- [dvop](https://github.com/MMRLApp) — WebUI base tooling (via MMRL/KernelSU
  WebUI ecosystem).

## License

```text
Tanzanite-HyperUnlocked is a modification of HyperUnlocked, which is free
software: you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com).
Tanzanite variant modifications (C) 2026 @noticesa.
```
