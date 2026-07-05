# <img src="Rounder/ICON.png" width="40" vertical-align="middle" /> Rounder

macOSの画面の角を美しく角丸化する、小さなメニューバーアプリ。

[![Latest release](https://img.shields.io/github/v/release/nisesimadao/Rounder?label=download)](https://github.com/nisesimadao/Rounder/releases/latest)
[![Build & Release](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml/badge.svg)](https://github.com/nisesimadao/Rounder/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-14.6%2B-blue)](#システム要件)

Notch導入以前のMacBookや、角が直線的な外部モニターに、ソフトウェア制御の軽量オーバーレイでモダンな角丸を与えます。メニューバーに静かに常駐し、**アクセシビリティ権限や画面収録権限は不要**、変更は**再起動なしで即座に反映**されます。

<img src="Rounder/SCREENSHOT.png" alt="Screenshot" />

[English README](./README.md)

> 注意: Notch搭載Macの内蔵ディスプレイは物理的に角丸なので、そこでは効果がありません。外部ディスプレイや古いMacで最も役立ちます。

## ひとことで

- **角が直線的な外部モニター**に特に向いています
- **強い権限なし**: アクセシビリティ、画面収録、自動化、ネットワーク権限は不要
- **即時反映**: 半径、色、モニター選択、プリセット、ゲーミング発光を再起動なしで適用
- **小さく透明な実装**: 設定はローカルの `UserDefaults`、UI はメニューバー中心、Swift コードは公開

## ダウンロード

[Releases](https://github.com/nisesimadao/Rounder/releases/latest) から最新版をダウンロードできます。

- `Rounder.zip` — アプリ本体

Rounder は現在、有料 Developer ID 署名なしで配布しています。初回起動時に macOS にブロックされた場合は、`Rounder.app` を右クリックして **開く** → **開く** を選んでください。詳しくは [FAQ](./docs/FAQ.md) を参照してください。

## Rounder の良さ

- 特別な macOS 権限なしで動作
- 外部モニターとマルチディスプレイに対応
- 再起動なしで設定を即時反映
- 角ごと・ディスプレイごとの制御
- 控えめな角丸からゲーミング風まで切り替えられるプリセット

## 特徴

- **即時反映** — すべての変更がその場で反映。再起動もチラつきもなし
- **メニューバー常駐** — 静かに動く常駐ユーティリティ（Dockアイコンなし）
- **ワンクリックでオン/オフ** — メニューバーから効果を即切り替え
- **ログイン時に起動** — 一度設定すればあとはお任せ（`SMAppService`使用）
- **半径・色を調整** — 0〜40px、任意の色、黒/白/グレーのクイック選択付き
- **角の形状** — なめらかな角丸、またはシャープな多角形カットアウト
- **四隅を個別制御** — 4つの角をそれぞれ独立してオン/オフ
- **マルチモニター** — 角丸を出すディスプレイを選択可能。新しく接続したディスプレイは自動でカバー
- **プリセット** — お気に入り設定の保存・適用・編集（すべて/上/下/左/右/なし を同梱）
- **すーぱーげーみんぐもーど** — 速度と強度を調整できるレインボー発光アニメ
- **特別な権限が不要** — ボーダーレスのオーバーレイウィンドウで描画するため、アクセシビリティ/画面録画/自動化の許可を求めません

## システム要件

- macOS 14.6 (Sonoma) 以降
- Apple Silicon または Intel Mac

## インストール

### ビルド済みアプリ

1. [最新リリース](https://github.com/nisesimadao/Rounder/releases/latest) から `Rounder.zip` をダウンロードして解凍。
2. `Rounder.app` をアプリケーションフォルダへ移動。
3. **有料のDeveloper ID署名は付いていない**ため、初回起動時にGatekeeperがブロックすることがあります。アプリを右クリック →**開く**→**開く**、または次を実行してください:
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

短いセットアップが表示されます: **ようこそ → 基本設定（半径・色）→ 完了**。ログイン時に起動するかを選び、**Rounderを開始**を押すとメニューバーに常駐します。権限の確認は一切ありません。

### 普段の使用

- **メニューバーのアイコン** → 角丸のオン/オフ、**設定**を開く、**終了**。
- **設定** → 半径（0〜40px）、色、角の形状、表示する角、対象モニター、ログイン時起動を調整。**適用/OK**を押した瞬間に反映されます（再起動不要）。

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
- **角の形状** — 角丸 / 多角形カットアウト
- **角の表示** — 四隅を個別にオン/オフ（2×2グリッド）

### モニター
- **モニター選択** — 角丸を出すディスプレイを選択（プリセットとは別に保存）
- **再取得** — 接続中のディスプレイを再スキャン

### すーぱーげーみんぐもーど
- **レインボーアニメーション** — **速度**（0.1×〜5.0×）と**発光強度**を調整

## 技術メモ

- **SwiftUI + AppKit**。`.screenSaver`レベルのボーダーレス`NSWindow`に**Core Graphics**で描画。
- オーバーレイは単一の構成パスから再生成されるため、即時適用・プリセット・メニュートグル・ディスプレイ着脱が同じ信頼できるコードを共有します。
- 設定は`UserDefaults`に永続化。ログイン時起動は`SMAppService`を使用。

## リリース / CI

`vX.Y.Z` タグを push すると、GitHub Actions（`.github/workflows/release.yml`）がアプリをビルドし、`Rounder.zip` を [Releases](https://github.com/nisesimadao/Rounder/releases) に自動で公開します。

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
Notch搭載Macの内蔵画面は元から角丸です。外部モニターで試し、効果が有効か（メニューバーのトグル）、Settings→モニターでそのディスプレイが選択されているかを確認してください。

**変更が反映されていない気がする**
即時反映されるはずです。ディスプレイを接続直後なら Settings→モニター→再取得、またはメニューバーから効果をオフ/オンしてください。

**メニューバーにアイコンがない**
Rounderが起動しているか確認してください（仕様上Dockアイコンはありません）。
