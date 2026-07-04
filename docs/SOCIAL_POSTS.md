# Social Post Drafts

## Short Launch Post

I built Rounder, a tiny macOS menu-bar app that gives external monitors and older MacBooks clean rounded screen corners.

- No Accessibility permission
- No Screen Recording permission
- Live settings
- Multi-monitor support
- Presets
- Optional rainbow gaming mode

Download: https://github.com/nisesimadao/Rounder/releases/latest

Suggested media: settings screenshot + 5 second before/after clip on an external monitor.

## Technical Post

Rounder is a small SwiftUI + AppKit macOS utility that draws lightweight borderless overlay windows at the screen corners.

It exists because many external monitors still have sharp rectangular edges, while modern macOS hardware and UI increasingly assume rounded displays.

The useful part: it works without Accessibility, Screen Recording, or Automation permission.

Repo: https://github.com/nisesimadao/Rounder

Suggested media: short clip showing live radius changes without a restart.

## Japanese Launch Post

Rounder という macOS メニューバーアプリを作りました。

外部モニターや古い MacBook の画面の角を、ソフトウェア的にきれいに角丸化します。

- アクセシビリティ権限不要
- 画面収録権限不要
- 設定は即時反映
- マルチモニター対応
- プリセット対応
- レインボー発光のゲーミングモードあり

Download: https://github.com/nisesimadao/Rounder/releases/latest

添付推奨: 設定画面スクショ + 外部モニターでの before/after 短尺動画。

## Reddit / Hacker News Style

I made a small macOS utility for people who use external monitors with sharp screen corners.

Rounder adds software-controlled rounded corners via lightweight overlay windows. It stays in the menu bar, supports multi-monitor setups, and does not ask for Accessibility or Screen Recording permission.

The app is open source and the release zip is available here:

https://github.com/nisesimadao/Rounder

## Follow-up Reply

The main design goal was to avoid scary permissions. Rounder does not need Accessibility or Screen Recording because it only draws local borderless overlay windows and keeps settings in macOS UserDefaults.
