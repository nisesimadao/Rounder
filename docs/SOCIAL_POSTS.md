# Social Post Drafts

## Short Launch Post

I built Rounder, a native macOS menu-bar utility that gives external monitors and older Macs clean rounded screen corners.

v2.2 adds an interactive menu panel, so you can drag Radius, switch Rounded / Squircle / Polygon, change quick colors, toggle individual corners, and turn on Gaming Mode without opening Settings.

- No Accessibility permission
- No Screen Recording permission
- Multi-monitor support
- Presets
- Open source

Download: https://github.com/nisesimadao/Rounder/releases/latest

Suggested media: final menu-panel screenshot + a 5 second live Radius/Shape clip on an external monitor.

## Technical Post

Rounder is a small SwiftUI + AppKit macOS utility that draws lightweight borderless overlay windows at the screen corners.

For v2.2 I rebuilt the status-item menu as a real `NSMenu` hosting an interactive SwiftUI panel. Radius and Shape update the existing corner windows in place, while structural changes still use the full overlay rebuild path.

The useful part: it works without Accessibility, Screen Recording, or Automation permission.

Repo: https://github.com/nisesimadao/Rounder

Suggested media: short clip with the menu left open while Radius and Shape update live.

## Japanese Launch Post

Rounder という macOS メニューバーユーティリティを作っています。

外部モニターや古いMacの画面の角を、ソフトウェアで自然に角丸化します。

v2.2ではメニューバーを開くだけで、角の半径、Rounded / Squircle / Polygon、クイック色、四隅の表示、すーぱーげーみんぐもーどまで直接調整できるようにしました。

- アクセシビリティ権限不要
- 画面収録権限不要
- マルチモニター対応
- プリセット対応
- オープンソース

Download: https://github.com/nisesimadao/Rounder/releases/latest

添付推奨: 最終メニューパネルのスクショ + 外部モニターで半径/形状をライブ変更する短い動画。

## Reddit / Hacker News Style

I made a small open-source macOS utility for people who use external monitors with sharp screen corners.

Rounder adds software-controlled rounded corners via lightweight overlay windows. It stays in the menu bar, supports multi-monitor setups, and does not ask for Accessibility or Screen Recording permission.

The v2.2 menu panel lets Radius and corner shape update live while the menu stays open.

https://github.com/nisesimadao/Rounder

## Follow-up Reply

The main design goal was to avoid invasive permissions. Rounder does not need Accessibility or Screen Recording because it only draws local borderless overlay windows and keeps settings in macOS `UserDefaults`.
