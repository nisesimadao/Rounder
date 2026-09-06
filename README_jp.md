# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

macOSの画面の角を、自然な角丸にするネイティブなメニューバーユーティリティです。

[![Latest release](https://img.shields.io/github/v/release/nisesimadao/Rounder?label=download)](https://github.com/nisesimadao/Rounder/releases/latest)
[![Build & Release](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml/badge.svg)](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-14.6%2B-blue)](#システム要件)

角が直線的な外部モニターや、Notch導入以前のMacで特に効果を発揮します。メニューバーに静かに常駐し、**アクセシビリティ・画面収録・自動化・ネットワーク権限は不要**です。

[English README](./README.md)

## メニューバーからすぐ調整

普段使う操作は、ほぼすべてメニューバーパネルから行えます。Rounderのオン/オフ、角の半径、形状、クイック色、四隅の表示、すーぱーげーみんぐもーど、設定、終了までまとめています。

<img src="docs/menu-panel-ja.webp" alt="Rounder メニューバー操作パネル" width="360" />

半径と形状は既存のオーバーレイウィンドウをその場で更新するため、スライダーを動かしたり形状を比較したりしても、毎回ウィンドウを作り直しません。

> Notch搭載Macの内蔵ディスプレイは物理的に角丸なので、Rounderの効果はほとんど見えません。外部ディスプレイや古いMacで最も分かりやすく使えます。

## 主な機能

- **3種類の角形状** — Rounded / Squircle / Polygon
- **0〜40pxの角半径** — メニューバーからライブ調整
- **任意の角色** — 黒 / 白 / グレーのクイック選択付き
- **四隅を個別にオン/オフ**
- **マルチディスプレイ対応** — Rounderを適用する画面を選択可能
- **プリセット** — 好きな設定を保存・適用
- **すーぱーげーみんぐもーど** — レインボー発光、速度、強度、Bloom幅を調整
- **ログイン時に起動** — `SMAppService`を使用
- **メニューバー中心** — 通常時はDockアイコンを表示しません
- **強い権限なし** — ローカルのオーバーレイと`UserDefaults`だけで動作

## ダウンロードとインストール

[Releases](https://github.com/nisesimadao/Rounder/releases/latest) から `Rounder.zip` をダウンロードし、解凍した `Rounder.app` を `/Applications` に移動してください。

リリース版は**ad-hoc署名されていますが、Developer ID署名・公証（notarization）は行っていません**。そのため、初回起動時にmacOS Gatekeeperに止められることがあります。

1. `Rounder.app` を右クリックして **開く** を選びます。
2. 確認画面でもう一度 **開く** を選びます。

必要な場合は、quarantine属性を手動で外すこともできます。

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

詳しくは [FAQ](./docs/FAQ.ja.md) を参照してください。

## 初回起動

短いオンボーディングが表示されます。

**ようこそ → 半径・色の基本設定 → 完了**

ログイン時に起動するかを選び、**Rounderを開始**を押すと、そのままメニューバー常駐モードに移ります。

## 設定

メニューバーパネルは素早い調整用です。詳細な設定画面では次の項目を変更できます。

- フルカラーピッカー
- 対象ディスプレイ
- プリセット管理
- すーぱーげーみんぐもーどの速度 / 強度 / Bloom幅
- ログイン時に起動
- 四隅や表示方法の詳細設定

<img src="Rounder/SCREENSHOT.png" alt="Rounder 設定画面" />

## システム要件

- macOS 14.6 以降
- Apple Silicon または Intel Mac

## プライバシーと権限

Rounderは、アクセシビリティ、画面収録、自動化、連絡先、位置情報、マイク、カメラ、ネットワーク権限を要求しません。設定はMac内の`UserDefaults`に保存されます。

詳しくは [Privacy](./docs/PRIVACY.md) と [Security](./docs/SECURITY.md) を参照してください。

## 技術メモ

- SwiftUI + AppKit
- `.screenSaver`レベルのボーダーレス`NSWindow`オーバーレイ
- Core Graphics / Core Animationによる角描画
- 本物の`NSMenu`内にSwiftUIの操作パネルを載せ、macOSのメニュートラッキングを維持
- 初回配置、ライブリサイズ、メニュープレビュー、角の向き、Gaming hue mappingは`CornerGeometry` / `ScreenCorner`を共通の正本として使用
- 半径・形状はin-place更新、構造が変わる設定は従来のオーバーレイ再生成経路を使用

## ソースからビルド

```bash
open Rounder.xcodeproj
```

コマンドラインからは次のようにビルドできます。

```bash
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Release build
```

## リリース / CI

`vX.Y.Z` タグをpushすると、Release workflowが角形状の回帰テストと必須の日英ローカライズを確認してから、`Rounder.zip`をビルド・公開します。

## プロジェクト文書

- [Changelog](./docs/CHANGELOG.md)
- [FAQ 日本語](./docs/FAQ.ja.md)
- [FAQ English](./docs/FAQ.md)
- [Privacy](./docs/PRIVACY.md)
- [Security](./docs/SECURITY.md)
- [Contributing](./docs/CONTRIBUTING.md)
- [Demo asset checklist](./docs/DEMO_ASSETS.md)
- [Launch checklist](./docs/LAUNCH_CHECKLIST.md)
- [License](./LICENSE)

## トラブルシューティング

**角丸が表示されない**  
Rounderが有効になっているか、設定で対象ディスプレイが選択されているか確認してください。Notch搭載Macでは、内蔵画面が最初から物理的に角丸なので、外部ディスプレイで試すと分かりやすいです。

**変更が反映されていない気がする**  
半径と形状はメニューバー操作中に即時反映されます。ディスプレイ選択など構造が変わる設定で違和感がある場合は、Rounderを一度オフ/オンするか、設定からディスプレイ一覧を再取得してください。

**メニューバーにアイコンがない**  
Rounderが起動しているか確認してください。通常のメニューバー常駐中は、仕様としてDockアイコンを表示しません。
