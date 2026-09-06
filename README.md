# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

A native macOS menu-bar utility that gives sharp display corners a cleaner, rounded look.

[![Latest release](https://img.shields.io/github/v/release/nisesimadao/Rounder?label=download)](https://github.com/nisesimadao/Rounder/releases/latest)
[![Build & Release](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml/badge.svg)](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-14.6%2B-blue)](#requirements)

Rounder is especially useful for external monitors and older Macs whose displays still have sharp rectangular corners. It runs quietly in the menu bar and requires **no Accessibility, Screen Recording, Automation, or network permission**.

[日本語版 README](./README_jp.md)

## Menu-bar controls

Most everyday controls live directly in the menu-bar panel: enable/disable, radius, corner shape, quick colors, individual corners, Gaming Mode, Settings, and Quit.

<img src="docs/menu-panel.webp" alt="Rounder menu-bar control panel" width="360" />

Radius and shape changes update the existing overlay windows in place, so you can drag and compare shapes without repeatedly rebuilding the overlay.

> On notch-equipped Macs, the built-in display already has physically rounded corners. Rounder is most noticeable on external displays and older Macs.

## Highlights

- **Three corner shapes** — Rounded, Squircle, and Polygon
- **0–40 px radius** with live menu-bar adjustment
- **Any corner color** plus black / white / gray quick swatches
- **Per-corner control** for all four corners
- **Multi-display selection** for choosing which screens Rounder affects
- **Presets** for saving and applying favorite configurations
- **Super Duper Gaming Mode** with animated rainbow glow, speed, intensity, and bloom controls
- **Launch at Login** through `SMAppService`
- **Menu-bar-first** — no Dock icon during normal use
- **No invasive permissions** — local overlay windows and local `UserDefaults` only

## Download & install

Download `Rounder.zip` from [Releases](https://github.com/nisesimadao/Rounder/releases/latest), unzip it, and move `Rounder.app` to `/Applications`.

Release builds are **ad-hoc signed, but not Developer ID signed or notarized**. Because of that, macOS Gatekeeper may block the first launch. If it does:

1. Right-click `Rounder.app` and choose **Open**.
2. Choose **Open** again in the confirmation dialog.

If necessary, you can also remove the quarantine attribute manually:

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

See the [FAQ](./docs/FAQ.md) for more details.

## First launch

Rounder shows a short onboarding flow:

**Welcome → basic radius/color setup → finish**

Choose whether Rounder should launch at login, then click **Start Rounder**. After setup, it moves into the menu bar.

## Settings

The menu panel is for fast adjustments. The full Settings window provides:

- full color picker
- display selection
- preset management
- Gaming Mode speed / intensity / bloom width
- Launch at Login
- detailed corner configuration

<img src="Rounder/SCREENSHOT.png" alt="Rounder Settings window" />

## Requirements

- macOS 14.6 or later
- Apple Silicon or Intel Mac

## Privacy & permissions

Rounder does not request Accessibility, Screen Recording, Automation, Contacts, Location, Microphone, Camera, or network permissions. Settings stay on your Mac in `UserDefaults`.

See [Privacy](./docs/PRIVACY.md) and [Security](./docs/SECURITY.md).

## Technical notes

- SwiftUI + AppKit
- borderless `NSWindow` overlays at `.screenSaver` level
- Core Graphics / Core Animation corner rendering
- a real `NSMenu` hosts the interactive SwiftUI menu panel, preserving normal macOS menu tracking behavior
- `CornerGeometry` / `ScreenCorner` are the shared source of truth for initial placement, live resizing, menu previews, orientation, and Gaming hue mapping
- radius and shape use in-place geometry updates; structural changes still use the full overlay rebuild path

## Build from source

```bash
open Rounder.xcodeproj
```

Or from the command line:

```bash
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Release build
```

## Releases / CI

Pushing a `vX.Y.Z` tag runs the release workflow, which checks corner-geometry regressions and required English/Japanese localizations before building and packaging `Rounder.zip`.

## Project docs

- [Changelog](./docs/CHANGELOG.md)
- [FAQ](./docs/FAQ.md)
- [Privacy](./docs/PRIVACY.md)
- [Security](./docs/SECURITY.md)
- [Contributing](./docs/CONTRIBUTING.md)
- [Demo asset checklist](./docs/DEMO_ASSETS.md)
- [Launch checklist](./docs/LAUNCH_CHECKLIST.md)
- [License](./LICENSE)

## Troubleshooting

**Rounded corners are not visible**  
Make sure Rounder is enabled and the target display is selected in Settings. On notch-equipped Macs, try an external display because the built-in panel is already physically rounded.

**A change did not seem to apply**  
Radius and shape should react immediately in the menu panel. For display-selection or other structural changes, toggle Rounder off/on or refresh the display list in Settings.

**No menu-bar icon**  
Make sure Rounder is running. It intentionally has no Dock icon during normal menu-bar use.
