# FAQ

## Why do I see a Gatekeeper warning?

Rounder release builds are **ad-hoc signed, but not Developer ID signed or notarized**. Because macOS cannot establish the same trust chain as a notarized Developer ID app, Gatekeeper may block the first launch.

Right-click `Rounder.app`, choose **Open**, then choose **Open** again. If necessary, you can also remove the quarantine attribute manually:

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

## Does Rounder need Accessibility or Screen Recording permission?

No. Rounder draws borderless overlay windows and does not need Accessibility, Screen Recording, Automation, or other special permissions.

## Why do I not see rounded corners on my MacBook display?

A notched MacBook already has rounded physical screen corners. In 2.4.0, apply the **Notched MacBook** preset to paint the menu bar black, blend the notch into that background, and round the application area below it. External monitors and older MacBooks can use the **Default** preset for their screen edges.

## How do I make the menu bar black?

Apply **Notched MacBook** in Settings → Presets, or enable **Exclude menu bar** and **Black menu bar background** in Corners, select black as the corner color in Appearance, and click Apply. The black background applies to the displays selected in Displays.

macOS chooses the menu text color from the wallpaper. If labels are hard to read against black, use a dark wallpaper or turn off the black background. Rounder does not change the system text color.

## Can the menu bar use Gaming Mode?

In the current source build, the menu bar strip shares the top corners' colors and the edge glow's speed and timing. There is no separate menu bar color control. Turning Gaming Mode off restores the black strip.

## What happens in fullscreen and Mission Control?

With Exclude menu bar enabled, screen-fixed top corners move to the screen edge in a fullscreen Space and return below the menu bar in a normal Space. Mission Control hides the black strip and top corners with the same fade. Lower corners remain visible. The animations respect Reduce Motion.

## Do presets include the menu-bar and attachment settings?

Yes. In 2.4.0, presets save screen attachment, virtual-desktop attachment, menu-bar exclusion, and the black background along with the corner appearance. The initial presets are Default, Virtual Desktops, and Notched MacBook. Older preset files still load, and upgrading keeps user-created presets.

## Does Rounder send any data?

No. Rounder does not collect telemetry or analytics. Settings are stored locally in macOS `UserDefaults`.

## How do I verify a download?

GitHub shows a SHA-256 digest for uploaded release assets. Open the latest release, expand the `Rounder.zip` asset details, and compare the digest shown by GitHub with a local checksum:

```bash
shasum -a 256 Rounder.zip
```
