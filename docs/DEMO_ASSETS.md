# Demo Asset Checklist

Use this when preparing screenshots, GIFs, or short videos for the README, GitHub release, and launch posts.

## Assets To Prepare

- `docs/menu-panel.webp`: final menu-panel screenshot showing the current v2.2.0 UI.
- `Rounder/SCREENSHOT.png`: clean full Settings-window screenshot.
- `docs/assets/rounder-social-preview.png`: 1280 × 640 GitHub/social preview image.
- Before/after image: external monitor with sharp corners, then with Rounder enabled.
- 5–8 second live-menu clip: open the menu, drag Radius, switch Rounded / Squircle / Polygon, and keep the panel open while the corners update.
- Optional Gaming Mode clip: rainbow edge and corner glow on a dark desktop.

## Capture Guidance

- Prefer an external monitor. Rounder is less obvious on notch-equipped MacBook displays.
- Use the final release candidate, not an older debug build.
- Keep the desktop quiet: plain wallpaper, no private notifications, no unrelated windows.
- Show the actual app or screen state, not a mockup.
- For the menu screenshot, keep the complete panel visible from master toggle through Settings / Quit.
- Make sure destructive Quit styling and the currently selected shape/color/corners are readable.
- Capture Japanese and English once each during QA, even if only one language is used publicly.
- Crop only enough to focus the effect; keep a visible screen edge so before/after images remain understandable.
- Keep GIFs short and under roughly 8 MB when possible. Use MP4 for higher-quality posts.

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

Only reference an asset after the final file is committed. Broken or visibly stale media makes the project look less trustworthy than having one current screenshot.
