# FAQ

## Why do I see a Gatekeeper warning?

Rounder release builds are currently not signed with a paid Apple Developer ID. macOS may block the first launch.

Right-click `Rounder.app`, choose **Open**, then choose **Open** again. You can also remove quarantine manually:

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

## Does Rounder need Accessibility or Screen Recording permission?

No. Rounder draws borderless overlay windows and does not need Accessibility, Screen Recording, Automation, or other special permissions.

## Why do I not see rounded corners on my MacBook display?

On Macs with a notch, the built-in display already has physical rounded corners. Rounder is most useful on external monitors and older MacBook displays with sharp corners.

## Does Rounder send any data?

No. Rounder does not collect telemetry or analytics. Settings are stored locally in macOS `UserDefaults`.

## How do I verify a download?

GitHub shows a SHA-256 digest for uploaded release assets. Open the latest release, expand the `Rounder.zip` asset details, and compare the digest shown by GitHub with a local checksum:

```bash
shasum -a 256 Rounder.zip
```
