# Demo Asset Checklist

Use this when preparing screenshots, GIFs, or short videos for the README, GitHub release, and launch posts.

## Assets To Prepare

- `Rounder/SCREENSHOT.png`: clean settings-window screenshot, already referenced by the README.
- `docs/assets/rounder-social-preview.png`: 1280 x 640 GitHub/social preview image.
- Before/after image: external monitor with sharp corners, then with Rounder enabled.
- 5-8 second live-settings clip: drag the radius slider, click Apply, show corners updating.
- Optional gaming-mode clip: rainbow edge and corner glow on a dark desktop.
- Optional social preview image: 1280 x 640 PNG for GitHub repository settings.

## Capture Guidance

- Prefer an external monitor. Rounder is less obvious on notched MacBook displays.
- Keep the desktop quiet: plain wallpaper, no private notifications, no unrelated windows.
- Show the actual app or screen state, not a mockup.
- Crop only enough to focus the corner effect; keep a visible screen edge so the before/after is understandable.
- Keep GIFs short and under roughly 8 MB when possible. Use MP4 for higher quality posts.

## Suggested Commands

Screenshot:

```bash
screencapture -i ~/Desktop/rounder-screenshot.png
```

Short screen recording:

```bash
screencapture -v ~/Desktop/rounder-demo.mov
```

Compress a video with `ffmpeg` if available:

```bash
ffmpeg -i ~/Desktop/rounder-demo.mov -vf "scale=1280:-2" -r 30 -c:v libx264 -crf 24 -pix_fmt yuv420p ~/Desktop/rounder-demo.mp4
```

## README Rule

Only reference assets in README files after the final file is committed. Broken media links make the project look less trustworthy than having one good screenshot.
