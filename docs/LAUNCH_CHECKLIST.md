# Rounder Launch Checklist

Use this before sharing a new Rounder release publicly.

## Release

- [ ] Confirm `CHANGELOG.md` includes the release highlights.
- [ ] Confirm the Xcode project version/build match the intended release.
- [ ] Run the CornerGeometry regression tests.
- [ ] Confirm a clean **Release** build succeeds for both Apple Silicon and Intel.
- [ ] Push a `vX.Y.Z` tag.
- [ ] Wait for GitHub Actions to publish `Rounder.zip`.
- [ ] Download `Rounder.zip` from GitHub.
- [ ] Install the downloaded app into `/Applications`.
- [ ] Launch it from `/Applications`.
- [ ] Confirm macOS Gatekeeper instructions in `README.md` still match the first-launch behavior.

## Menu Panel

- [ ] Open the menu-bar panel and confirm it stays open while adjusting controls.
- [ ] Toggle Rounder off/on and confirm the switch uses the accent color when enabled.
- [ ] Drag Radius through 0 → 40 → a normal value and confirm the corners follow without flicker.
- [ ] Switch Rounded → Squircle → Polygon → Rounded and confirm the physical corner anchor does not move.
- [ ] Confirm all three shape previews are readable and remain clipped inside their tiles.
- [ ] Change the quick corner color and verify the overlay + Settings draft stay synchronized.
- [ ] Toggle all four individual corners and confirm the correct physical corner changes.
- [ ] Toggle Super Duper Gaming Mode and confirm the menu stays responsive.
- [ ] Open Settings from the panel and confirm menu tracking ends cleanly before the window appears.
- [ ] Confirm `⌘,` opens Settings and `⌘Q` quits.
- [ ] With macOS menu-bar auto-hide enabled, confirm the menu bar remains visible while the panel is open.

## Displays / Spaces

- [ ] Test the built-in display plus at least one external display if available.
- [ ] Test a display positioned left of the main display (negative desktop coordinates) if available.
- [ ] Enter/leave a fullscreen Space and confirm all enabled corners remain attached.
- [ ] Switch Spaces while the panel is open and confirm overlays recover correctly.

## Visual Proof

- [ ] Capture one clean screenshot of the settings window.
- [ ] Capture one clean screenshot of the menu-bar panel.
- [ ] Capture one before/after screenshot on an external monitor.
- [ ] Capture one short demo clip or GIF showing live radius changes.
- [ ] Capture one gaming-mode clip if promoting the fun angle.
- [ ] Follow `DEMO_ASSETS.md` and keep final assets small enough to load quickly on GitHub.
- [ ] Update `Rounder/SCREENSHOT.png` only if the Settings UI changed materially.
- [ ] Update `docs/menu-panel.webp` if the menu panel changed materially.

## Release Notes

- [ ] Draft the GitHub release body from `RELEASE_NOTES_TEMPLATE.md`.
- [ ] Include the unsigned-app Gatekeeper note.
- [ ] Mention the macOS version tested locally.
- [ ] Call out the live menu-bar controls in releases that include them.

## GitHub

- [ ] Check the README on GitHub after push.
- [ ] Confirm the settings and menu-panel screenshots render.
- [ ] Confirm badges render.
- [ ] Confirm latest release link works.
- [ ] Confirm issue templates appear when creating a new issue.
- [ ] Add repository topics such as `macos`, `swift`, `swiftui`, `appkit`, `menubar`, `utility`, `rounded-corners`.
- [ ] Add a social preview image in repository settings.

## Posting

- [ ] Use `SOCIAL_POSTS.md` as the starting point.
- [ ] Lead with the problem: external monitors still have sharp corners.
- [ ] Mention no Accessibility or Screen Recording permission.
- [ ] Mention that Radius / Shape can now be adjusted live from the menu bar when relevant.
- [ ] Include the download link.
- [ ] Include a screenshot, GIF, or short video.
