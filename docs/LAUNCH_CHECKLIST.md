# Rounder Launch Checklist

Use this before sharing a new Rounder release publicly.

## Release

- [ ] Confirm `CHANGELOG.md` includes the release highlights.
- [ ] Confirm the Xcode marketing version and build number match the intended release.
- [ ] Run the CornerGeometry regression tests.
- [ ] Run `python3 Tests/LocalizationTests.py`.
- [ ] Confirm a clean **Release** build succeeds for both Apple Silicon and Intel.
- [ ] Confirm the built app reports the expected `CFBundleShortVersionString` and `CFBundleVersion`.
- [ ] Push a `vX.Y.Z` tag only after local/RC visual verification is complete.
- [ ] Wait for GitHub Actions to publish `Rounder.zip`.
- [ ] Download the published `Rounder.zip` from GitHub and verify its SHA-256 digest.
- [ ] Install the downloaded app into `/Applications` and launch that exact build.
- [ ] Confirm README/FAQ Gatekeeper instructions still match the first-launch behavior for the ad-hoc-signed, non-notarized build.

## Menu Panel

- [ ] Open the menu-bar panel and confirm it stays open while adjusting controls.
- [ ] Toggle Rounder off/on and confirm the state is visually clear.
- [ ] Confirm the active Radius track and selected controls use the macOS accent color while the menu is open.
- [ ] Drag Radius through 0 → 40 → a normal value and confirm the corners follow without flicker.
- [ ] Switch Rounded → Squircle → Polygon → Rounded and confirm the physical corner anchor does not move.
- [ ] Confirm all three shape previews are readable and clipped inside their tiles.
- [ ] Change the quick corner color and verify the overlay + Settings draft stay synchronized.
- [ ] Toggle all four individual corners and confirm the correct physical corner changes.
- [ ] Toggle Super Duper Gaming Mode and confirm the menu stays responsive.
- [ ] Confirm Quit is visually destructive and easy to distinguish from Settings.
- [ ] Open Settings from the panel and confirm menu tracking ends cleanly before the window appears.
- [ ] Confirm `⌘,` opens Settings and `⌘Q` quits.
- [ ] With macOS menu-bar auto-hide enabled, confirm the menu bar remains visible while the panel is open.

## Localization / Accessibility

- [ ] Test the menu panel in Japanese and English.
- [ ] Confirm no menu label is clipped at 300 pt panel width.
- [ ] Confirm `Settings…` / `設定…` use the macOS ellipsis character.
- [ ] Confirm Squircle terminology is correct in both languages.
- [ ] With VoiceOver, verify labels for enable, radius, three shapes, black/white/gray swatches, all four corners, Gaming Mode, Settings, and Quit.
- [ ] With VoiceOver, confirm corner state values are localized as On/Off or オン/オフ.

## Onboarding

- [ ] Reset first-launch state or use a clean test bundle and open onboarding.
- [ ] Confirm no macOS TabView/tab-strip chrome appears at the top of the window.
- [ ] Confirm the progress bar advances through all three steps.
- [ ] Confirm Back / Next keyboard and pointer navigation works.
- [ ] Confirm radius and color setup values persist into the running app.
- [ ] Confirm the final Launch at Login toggle can be changed without being overwritten when moving back/forward.
- [ ] Confirm Start Rounder closes onboarding and enters menu-bar mode without restarting.

## Displays / Spaces

- [ ] Test the built-in display plus at least one external display if available.
- [ ] Test a display positioned left of the main display (negative desktop coordinates) if available.
- [ ] Enter/leave a fullscreen Space and confirm all enabled corners remain attached.
- [ ] Switch Spaces while the panel is open and confirm overlays recover correctly.

## Visual Proof

- [ ] Capture one clean screenshot of the Settings window.
- [ ] Capture one clean screenshot of the final menu-bar panel.
- [ ] Capture one before/after screenshot on an external monitor.
- [ ] Capture one short demo clip or GIF showing live radius changes.
- [ ] Capture one Gaming Mode clip if promoting the fun angle.
- [ ] Follow `DEMO_ASSETS.md` and keep final assets small enough to load quickly on GitHub.
- [ ] Update `Rounder/SCREENSHOT.png` only if the Settings UI changed materially.
- [ ] Update `docs/menu-panel.webp` whenever the menu panel changed materially.

## Release Notes

- [ ] Draft the GitHub release body from `RELEASE_NOTES_TEMPLATE.md`.
- [ ] State that the release is ad-hoc signed but not Developer ID signed/notarized, and include the Gatekeeper note.
- [ ] Mention the macOS version tested locally.
- [ ] Call out the live menu-bar controls and three corner shapes.
- [ ] Mention the onboarding/tab-chrome fix and localization polish when relevant.

## GitHub

- [ ] Check both README files on GitHub after push.
- [ ] Confirm the Settings and menu-panel screenshots render.
- [ ] Confirm badges render.
- [ ] Confirm the latest release link works.
- [ ] Confirm issue templates appear when creating a new issue.
- [ ] Add repository topics such as `macos`, `swift`, `swiftui`, `appkit`, `menubar`, `utility`, `rounded-corners`.
- [ ] Add a social preview image in repository settings.

## Posting

- [ ] Use `SOCIAL_POSTS.md` as the starting point.
- [ ] Lead with the problem: external monitors still have sharp corners.
- [ ] Mention no Accessibility or Screen Recording permission.
- [ ] Mention that Radius / Shape can be adjusted live from the menu bar.
- [ ] Include the download link.
- [ ] Include a screenshot, GIF, or short video.
