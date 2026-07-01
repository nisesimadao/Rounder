# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

A tiny menu-bar app that beautifully rounds the corners of your macOS screen.

It uses a lightweight, software-controlled overlay to give modern rounded corners to older MacBooks (pre-notch) and external monitors that still have sharp edges. It runs quietly in the menu bar, needs **no special permissions**, and applies every change **instantly — no restart required**.

<img src="Rounder/SCREENSHOT.png" alt="Screenshot" />

[日本語版READMEはこちら](./README_jp.md)

> Note: On Macs with a notch, the built-in display already has physically rounded corners, so this app has no visible effect there. It's most useful on external displays and older Macs.

## Features

- **Instant apply** — every change takes effect live; no restart, no flicker
- **Runs in the menu bar** — quiet background utility, no Dock icon
- **One-click on/off** — toggle the effect straight from the menu bar
- **Launch at Login** — set it once and forget it (via `SMAppService`)
- **Adjustable radius & color** — 0–40 px, any color, with quick black/white/gray swatches
- **Corner shape** — smooth rounded corners or a sharp polygon cutout
- **Per-corner control** — enable each of the four corners independently
- **Multi-monitor** — choose exactly which displays get rounded corners; newly connected displays are covered automatically
- **Presets** — save, apply, and edit favorite configurations (ships with All / Top / Bottom / Left / Right / None)
- **Super Duper Gaming Mode** — animated rainbow glow with adjustable speed and intensity
- **No special permissions** — draws with borderless overlay windows, so no Accessibility / Screen Recording / Automation prompts

## System Requirements

- macOS 14.6 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

### Prebuilt App (Recommended)

1. Download `Rounder.zip` from the [latest release](https://github.com/nisesimadao/Rounder/releases/latest) and unzip it.
2. Move `Rounder.app` to your Applications folder.
3. The build is **not signed with a paid Developer ID**, so on first launch macOS Gatekeeper may block it. Right-click the app → **Open** → **Open**, or run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Rounder.app
   ```

### Build from Source

```bash
# Open in Xcode
open Rounder.xcodeproj

# …or build from the command line
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Release build
```

## Usage

### First Launch

A short setup appears: **Welcome → basic settings (radius & color) → done**. Choose whether to launch at login, click **Start Rounder**, and it moves into the menu bar. No permission prompts.

### Everyday Use

- **Menu bar icon** → toggle rounded corners on/off, open **Settings**, or **Quit**.
- **Settings** → adjust radius (0–40 px), color, corner shape, which corners show, which monitors are covered, and Launch at Login. Changes apply the moment you click **Apply** / **OK** — no restart.

### Presets

- **Apply** a saved configuration with one click.
- **Save** the current settings as a new preset.
- **Edit** or delete existing presets.
- Ships with **All Corners / Top Only / Bottom Only / Left Only / Right Only / None**.

## Settings Reference

### General
- **Launch at Login** — start Rounder automatically when you log in
- **Enable rounded corners** — master on/off (also available from the menu bar)

### Appearance
- **Corner radius** — 0–40 px
- **Corner color** — color picker + quick swatches
- **Corner shape** — rounded corner or polygon cutout
- **Corner visibility** — toggle each corner independently (2×2 grid)

### Monitors
- **Monitor selection** — pick which displays get rounded corners (stored separately from presets)
- **Refresh** — re-scan connected displays

### Super Duper Gaming Mode
- **Rainbow animation** with **speed** (0.1×–5.0×) and **glow intensity** controls

## Technical Notes

- **SwiftUI + AppKit**, drawing with **Core Graphics** into borderless `NSWindow`s at `.screenSaver` level.
- Overlays are rebuilt through a single configuration path, so live apply, presets, the menu toggle, and display hot-plug all share the same reliable code.
- Settings persist in `UserDefaults`; Launch at Login uses `SMAppService`.

## Releases / CI

Pushing a `vX.Y.Z` tag triggers a GitHub Actions workflow (`.github/workflows/release.yml`) that builds the app and publishes `Rounder.zip` to [Releases](https://github.com/nisesimadao/Rounder/releases) automatically.

## Troubleshooting

**Rounded corners aren't visible**
On a Mac with a notch, the built-in display is already rounded — try an external monitor, and make sure the effect is enabled (menu bar → toggle) and the display is selected in Settings → Monitors.

**A change didn't seem to apply**
It should apply instantly; if a display was just connected, open Settings → Monitors → Refresh, or toggle the effect off/on from the menu bar.

**No menu bar icon**
Make sure Rounder is running (it has no Dock icon by design).
