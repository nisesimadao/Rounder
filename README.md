# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

A tiny menu-bar app that beautifully rounds the corners of your macOS screen.

[![Latest release](https://img.shields.io/github/v/release/nisesimadao/Rounder?label=download)](https://github.com/nisesimadao/Rounder/releases/latest)
[![Build & Release](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml/badge.svg)](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-14.6%2B-blue)](#system-requirements)

Rounder gives modern rounded corners to older MacBooks and external monitors that still have sharp rectangular edges. It runs quietly in the menu bar, needs **no Accessibility or Screen Recording permission**, and applies every change **instantly, with no restart**.

<img src="Rounder/SCREENSHOT.png" alt="Screenshot" />

[日本語版READMEはこちら](./README_jp.md)

> Note: On Macs with a notch, the built-in display already has physically rounded corners, so this app has no visible effect there. It's most useful on external displays and older Macs.

## At a Glance

- **Best for external monitors** that still have sharp rectangular corners
- **No invasive permissions**: no Accessibility, Screen Recording, Automation, or network access
- **Live apply**: radius, color, monitor selection, presets, and gaming glow update without restarting the app
- **Small surface area**: local settings in `UserDefaults`, menu-bar-only UI, open-source Swift code

## Download

Download the latest build from [Releases](https://github.com/nisesimadao/Rounder/releases/latest).

- `Rounder.zip` — the app

Rounder is currently distributed as an unsigned app. If macOS blocks the first launch, right-click `Rounder.app`, choose **Open**, then **Open** again. See [FAQ](./FAQ.md) for details.

## Why Rounder?

- Works without special macOS permissions
- Covers external monitors and multi-display setups
- Live settings with no app restart
- Per-corner and per-display control
- Presets for switching between subtle, all-corner, and gaming-style setups

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

### Prebuilt App

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

## Project Docs

- [Changelog](./CHANGELOG.md)
- [FAQ](./FAQ.md)
- [Privacy](./PRIVACY.md)
- [Security](./SECURITY.md)
- [Contributing](./CONTRIBUTING.md)
- [Demo asset checklist](./docs/DEMO_ASSETS.md)
- [Launch checklist](./docs/LAUNCH_CHECKLIST.md)
- [License](./LICENSE)

## Troubleshooting

**Rounded corners aren't visible**
On a Mac with a notch, the built-in display is already rounded — try an external monitor, and make sure the effect is enabled (menu bar → toggle) and the display is selected in Settings → Monitors.

**A change didn't seem to apply**
It should apply instantly; if a display was just connected, open Settings → Monitors → Refresh, or toggle the effect off/on from the menu bar.

**No menu bar icon**
Make sure Rounder is running (it has no Dock icon by design).
