# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

A tool that beautifully rounds the corners of your macOS screen.

It uses a software-controlled overlay to give modern rounded corners to older MacBooks (pre-notch) and external monitors that still have sharp edges. It runs quietly in the background and does not interfere with normal system behavior.

<img src="Rounder/SCREENSHOT.png" alt="Screenshot" />

[日本語版READMEはこちら](./README_jp.md)

> Note: On Macs with a notch, the built-in display already has physically rounded corners, so this app has no visible effect.

## Project Structure

```
Rounder/
├── Rounder/
│   ├── RounderApp.swift           # Main application entry point
│   ├── CornerOverlayWindow.swift  # Rounded corner overlay window
│   ├── ContentView.swift          # Advanced settings UI
│   ├── PresetsTabView.swift       # Preset management UI
│   ├── PresetManager.swift        # Preset data management
│   ├── FirstLaunchSetupView.swift # First launch setup flow
│   ├── MenuBarController.swift    # Menu bar control
│   └── ScreenMonitor.swift        # Screen change monitoring
├── Rounder.xcodeproj              # Xcode project
└── README.md                      # This file
```

## Features

- **Background operation**: Runs as a menu bar app
- **Real-time configuration**: Instantly adjust corner radius and color
- **Individual corner control**: Toggle each corner independently
- **Preset functionality**: Save and switch between favorite settings
- **Import/Export**: Share and backup presets
- **Super Duper Gaming Mode**: Special mode with animated effects
- **Simple interface**: Intuitive settings screen
- **Lightweight and stable**: Runs smoothly in the background

## System Requirements

- macOS 14.6 (Sonoma) or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- Accessibility permission required

## Installation

### Prebuilt App (Recommended)

1. Download the latest version from [Releases](https://github.com/nisesimadao/rounder/releases)
2. Move it to your Applications folder
3. Grant permissions on first launch

### Build from Source

```bash
# Open the project in Xcode
open Rounder.xcodeproj

# Or build from the command line
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Release build
```

## Usage

### First Launch

1. Launch the app to open the setup wizard
2. Grant required permissions (Accessibility, Screen Recording)
3. Set corner radius and color
4. Click "Start Rounder" to finish

### Daily Use

- **Menu bar**: Open settings from the Rounder icon
- **Adjust settings**: Change corner radius (0–40px) and color in real time
- **Individual corners**: Toggle each corner independently (2x2 grid layout)
- **Enable/disable**: Toggle rounded corner effect on or off
- **Quit**: Fully exit the app

### Preset Features

- **Apply presets**: One-click apply saved configurations
- **Save current settings**: Create new preset from current configuration
- **Edit presets**: Rename or delete existing presets
~~- **Import/Export**: Share and backup presets in JSON format~~
- **Default presets**: Includes "All Corners", "Top Only", "Bottom Only", "Left Only", "Right Only", and "None"

## Configuration Options

### General Settings
- **Corner radius**: Adjustable from 0 to 40 pixels
- **Corner color**: Choose via color picker or presets
- **Corner visibility**: Toggle each corner independently (2x2 grid layout)
- **Enable**: Toggle the rounded corner effect

### Super Duper Gaming Mode
- **Enable**: Rainbow animation effects
- **Speed control**: Adjust animation speed from 0.1x to 5.0x

### Preset Management
- **Preset list**: View and manage saved configurations
- **Create new**: Save current settings as preset
~~- **Import**: Load presets from JSON files~~
~~- **Export**: Save presets as JSON files~~

### Permissions
- **Accessibility**: Required for detecting screen elements
- **Screen Recording**: Required for overlay rendering at screen-saver level
- **Automation**: Required for monitoring system events

## Technical Details

### Core Technologies
- **SwiftUI + AppKit**: Modern native macOS app
- **Core Graphics**: High-performance overlay rendering
- **NSWindow.Level.screenSaver**: Displays above menu bar layer
- **UserDefaults**: Persistent settings storage

### Performance
- **Low overhead**: Minimal CPU usage
- **Memory efficient**: Uses only necessary resources
- **Real-time updates**: Changes apply instantly

## Troubleshooting

### Common Issues

**Q: Rounded corners are not visible**  
A: Make sure Accessibility permission is granted

**Q: Settings changes are not applied**  
A: Click "Apply" or restart the app

**Q: No menu bar icon appears**  
A: Ensure the app is running in the background

### Reset Permissions

```bash
# Open System Settings directly
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```