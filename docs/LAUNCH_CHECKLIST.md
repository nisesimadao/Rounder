# Rounder Launch Checklist

Use this before sharing a new Rounder release publicly.

## Release

- [ ] Confirm `CHANGELOG.md` includes the release highlights.
- [ ] Push a `vX.Y.Z` tag.
- [ ] Wait for GitHub Actions to publish `Rounder.zip`.
- [ ] Download `Rounder.zip` from GitHub.
- [ ] Install the downloaded app into `/Applications`.
- [ ] Launch it from `/Applications`.
- [ ] Confirm macOS Gatekeeper instructions in `README.md` still match the first-launch behavior.

## Visual Proof

- [ ] Capture one clean screenshot of the settings window.
- [ ] Capture one before/after screenshot on an external monitor.
- [ ] Capture one short demo clip or GIF showing live radius changes.
- [ ] Capture one gaming-mode clip if promoting the fun angle.
- [ ] Follow `docs/DEMO_ASSETS.md` and keep final assets small enough to load quickly on GitHub.
- [ ] Update `Rounder/SCREENSHOT.png` only if the current UI changed materially.

## Release Notes

- [ ] Draft the GitHub release body from `docs/RELEASE_NOTES_TEMPLATE.md`.
- [ ] Include the unsigned-app Gatekeeper note.
- [ ] Mention the macOS version tested locally.

## GitHub

- [ ] Check the README on GitHub after push.
- [ ] Confirm badges render.
- [ ] Confirm latest release link works.
- [ ] Confirm issue templates appear when creating a new issue.
- [ ] Add repository topics such as `macos`, `swift`, `swiftui`, `appkit`, `menubar`, `utility`, `rounded-corners`.
- [ ] Add a social preview image in repository settings.

## Posting

- [ ] Use `docs/SOCIAL_POSTS.md` as the starting point.
- [ ] Lead with the problem: external monitors still have sharp corners.
- [ ] Mention no Accessibility or Screen Recording permission.
- [ ] Include the download link.
- [ ] Include a screenshot, GIF, or short video.
