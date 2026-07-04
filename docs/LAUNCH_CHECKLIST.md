# Rounder Launch Checklist

Use this before sharing a new Rounder release publicly.

## Release

- [ ] Confirm `CHANGELOG.md` includes the release highlights.
- [ ] Push a `vX.Y.Z` tag.
- [ ] Wait for GitHub Actions to publish `Rounder.zip` and `Rounder.zip.sha256`.
- [ ] Download both release assets from GitHub.
- [ ] Verify the checksum:

```bash
shasum -a 256 -c Rounder.zip.sha256
```

- [ ] Install the downloaded app into `/Applications`.
- [ ] Launch it from `/Applications`.
- [ ] Confirm macOS Gatekeeper instructions in `README.md` still match the first-launch behavior.

## Visual Proof

- [ ] Capture one clean screenshot of the settings window.
- [ ] Capture one before/after screenshot on an external monitor.
- [ ] Capture one short demo clip or GIF showing live radius changes.
- [ ] Capture one gaming-mode clip if promoting the fun angle.

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

