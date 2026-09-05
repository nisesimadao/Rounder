# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

macOSの画面の角を美しく角丸化する、小さなメニューバーアプリ。

[![Latest release](https://img.shields.io/github/v/release/nisesimadao/Rounder?label=download)](https://github.com/nisesimadao/Rounder/releases/latest)
[![Build & Release](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml/badge.svg)](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-14.6%2B-blue)](#システム要件)

Notch導入以前のMacBookや、角が直線的な外部モニターに、ソフトウェア制御の軽量オーバーレイでモダンな角丸を与えます。メニューバーに静かに常駐し、**アクセシビリティ権限や画面収録権限は不要**。日常的な調整はメニューバーからその場で操作できます。

<img src="Rounder/SCREENSHOT.png" alt="Rounder設定画面" />

### メニューバーからすぐ調整

角の半径、形状、クイック色、四隅の表示、すーぱーげーみんぐもーど、設定、終了まで、普段使う操作をメニューバーパネルにまとめています。

<img src="docs/menu-panel.webp" alt="Rounder メニューバー操作パネル" width="360" />

[English README](./README.md)

> 注意: Notch搭載Macの内蔵ディスプレイは物理的に角丸なので、そこでは効果がありません。外部ディスプレイや古いMacで最も役立ちます。

## ひとことで

- **角が直線的な外部モニター**に特に向いています
- **強い権限なし**: アクセシビリティ、画面収録、自動化、ネットワーク権限は不要
- **メニューバーから即操作**: 半径、形状、クイック色、四隅、Gaming Mode
- **小さく透明な実装**: 設定はローカルの `UserDefaults`、UI はメニューバー中心、Swift コードは公開

## ダウンロード

[Releases](https://github.com/nisesimadao/Rounder/releases/latest) から最新版をダウンロードできます。

- `Rounder.zip` — アプリ本体

Rounder は現在、有料 Developer ID 署名なしで配布しています。初回起動時に macOS にブロックされた場合は、`Rounder.app` を右クリックして **開く** → **開く** を選んでください。詳しくは [FAQ](./docs/FAQ.md) を参照してください。

## Rounder の良さ

- 特別な macOS 権限なしで動作
- 外部モニターとマルチディスプレイに対応
- 普段の調整はメニューバーだけで完結
- 角ごと・ディスプレイごとの制御
- 控えめな角丸からゲーミング風まで切り替えられるプリセット

## 特徴

- **ライブメニューバーパネル** — 半径、形状、クイック色、四隅の表示、Gaming Modeを設定画面を開かず操作
- **半径・形状を即時更新** — 既存の角ウィンドウをその場でリサイズし、チラつきを抑えて追従
- **メニューバー常駐** — 通常時はDockに出ない静かなユーティリティ
- **ワンクリックでオン/オフ** — メニューバーから効果を即切り替え
- **ログイン時に起動** — 一度設定すればあとはお任せ（`SMAppService`使用）
- **半径・色を調整** — 0〜40px、任意の色、黒/白/グレーのクイック選択付き
- **3種類の角形状** — Rounded / Squircle / Polygon
- **四隅を個別制御** — 4つの角をそれぞれ独立してオン/オフ
- **マルチモニター** — 角丸を出すディスプレイを選択可能
- **プリセット** — お気に入り設定の保存・適用・編集（すべて/上/下/左/右/なし を同梱）
- **すーぱーげーみんぐもーど** — 速度・強度・Bloom幅を調整できるレインボー発光アニメ
- **特別な権限が不要** — ボーダーレスのオーバーレイウィンドウで描画するため、アクセシビリティ/画面録画/自動化の許可を求めません

## システム要件

- macOS 14.6 (Sonoma) 以降
- Apple Silicon または Intel Mac

## インストール

### ビルド済みアプリ

1. [最新リリース](https://github.com/nisesimadao/Rounder/releases/latest) から `Rounder.zip` をダウンロードして解凍。
2. `Rounder.app` をアプリケーションフォルダへ移動。
3. **有料のDeveloper ID署名は付いていない**ため、初回起動時にGatekeeperがブロックすることがあります。アプリを右クリック → **開く** → **開く**、または次を実行してください:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Rounder.app
   ```

### ソースからビルド

```bash
# Xcodeで開く
open Rounder.xcodeproj

# もしくはコマンドラインで
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Release build
```

## 使い方

### 初回起動

短いセットアップが表示されます: **ようこそ → 基本設定（半径・色）→ 完了**。ログイン時に起動するかを選び、**Rounderを開始**を押すとメニューバーに常駐します。権限の確認はありません。

### 普段の使用

- **メニューバーのアイコン** → Rounderのオン/オフ、**角の半径**スライダー、**Rounded / Squircle / Polygon**切替、クイック色、四隅の表示、Gaming Mode、**設定**、**終了**。
- **設定** → フルカラーピッカー、対象ディスプレイ、プリセット、Gamingの速度/強度/Bloom幅、ログイン時起動など詳細項目を調整。

### プリセット

- 保存した設定を**ワンクリックで適用**。
- 現在の設定を**新規プリセットとして保存**。
- 既存プリセットの**編集・削除**。
- **すべての角/上のみ/下のみ/左のみ/右のみ/なし** を同梱。

## 設定リファレンス

### 一般
- **ログイン時に起動** — ログイン時にRounderを自動起動
- **角丸を有効にする** — 全体のオン/オフ（メニューバーからも操作可）

### 外観
- **角の半径** — 0〜40px
- **角の色** — カラーピッカー＋クイック選択
- **角の形状** — Rounded / Squircle / Polygon
- **角の表示** — 四隅を個別にオン/オフ

### モニター
- **モニター選択** — 角丸を出すディスプレイを選択（プリセットとは別に保存）
- **再取得** — 接続中のディスプレイを再スキャン

### すーぱーげーみんぐもーど
- **レインボーアニメーション** — **速度**（0.1×〜5.0×）、**発光強度**、**Bloom幅**を調整

## 技術メモ

- **SwiftUI + AppKit**。`.screenSaver`レベルのボーダーレス`NSWindow`に**Core Graphics**で描画。
- Radius / Shape変更は既存のCorner Windowをその場で更新。ON/OFF、四隅の表示、Gaming Mode、プリセット、ディスプレイ変更など構造が変わる操作は従来の再生成経路を使用。
- 初回生成・ライブリサイズ・メニュープレビュー・角の向き・Gaming hue mappingは`CornerGeometry` / `ScreenCorner`を共通の正本として使用。
- 設定は`UserDefaults`に永続化。ログイン時起動は`SMAppService`を使用。

## リリース / CI

`vX.Y.Z` タグを push すると、GitHub Actions（`.github/workflows/release.yml`）がGeometry回帰テストを実行し、アプリをビルドして `Rounder.zip` を [Releases](https://github.com/nisesimadao/Rounder/releases) に自動公開します。

## プロジェクト文書

- [Changelog](./docs/CHANGELOG.md)
- [FAQ](./docs/FAQ.md)
- [Privacy](./docs/PRIVACY.md)
- [Security](./docs/SECURITY.md)
- [Contributing](./docs/CONTRIBUTING.md)
- [Demo asset checklist](./docs/DEMO_ASSETS.md)
- [Launch checklist](./docs/LAUNCH_CHECKLIST.md)
- [License](./LICENSE)

## トラブルシューティング

**角丸が表示されない**  
Notch搭載Macの内蔵画面は元から角丸です。外部モニターで試し、Rounderが有効か、Settings → モニターで対象ディスプレイが選択されているかを確認してください。

**変更が反映されていない気がする**  
Radius / Shapeはメニューバー操作中に即時反映されます。ディスプレイ選択や構造変更で違和感がある場合は、Rounderを一度オフ/オンするか、Settings → モニター → 再取得を試してください。

**メニューバーにアイコンがない**  
Rounderが起動しているか確認してください（通常のメニューバー常駐中はDockアイコンを表示しません）。
