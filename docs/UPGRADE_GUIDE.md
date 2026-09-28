# 機能アップグレードガイド

## 概要

この文書は、設定画面（`ContentView.swift` の `SettingsTabView`）へ設定項目を追加する際に、プリセット編集画面（`EditPresetTabView.swift`）へ同じ変更を反映するための手順をまとめたものです。

## アーキテクチャ

### 設定画面

- **ファイル**：`ContentView.swift`
- **主要コンポーネント**：`SettingsTabView`
- **役割**：現在のアプリ設定を表示し、変更します。

### プリセット編集画面

- **ファイル**：`EditPresetTabView.swift`
- **主要コンポーネント**：`EditPresetTabView`
- **役割**：プリセットに保存する設定を編集します。

## 同期して変更する項目

### 1. データ構造

設定画面へ新しい項目を追加する場合は、プリセット側のデータ構造にも同じ値を保存できるようにします。

```swift
// PresetManager.swift - CornerPreset構造体
struct CornerPreset: Codable, Identifiable {
    // 既存のプロパティ...

    // 新しい設定項目をここに追加
    var newSetting: Type = defaultValue
}
```

### 2. UI コンポーネント

設定画面とプリセット編集画面では、同じ意味の項目に同じ UI 構成を使用します。

#### 設定画面（SettingsTabView）

```swift
// 新しい設定UI
VStack(alignment: .leading, spacing: 8) {
    Text("new_setting_label")
        .font(.subheadline)
        .fontWeight(.medium)

    // UIコントロール（Toggle、Slider、ColorPickerなど）
    NewSettingControl(value: $tempNewSetting)
        .onChange(of: tempNewSetting) { _, _ in
            markAsChanged()
        }
}
```

#### プリセット編集画面（EditPresetTabView）

```swift
// 同じUI構成をコピー
VStack(alignment: .leading, spacing: 8) {
    Text("new_setting_label")
        .font(.subheadline)
        .fontWeight(.medium)

    // 同じUIコントロール
    NewSettingControl(value: $tempNewSetting)
        .onChange(of: tempNewSetting) { _, _ in
            markAsChanged()
        }
}
```

### 3. State 管理

#### 設定画面

```swift
// ContentView.swift - AdvancedSettingsView
@State private var tempNewSetting: Type = defaultValue
```

#### プリセット編集画面

```swift
// EditPresetTabView.swift
@State private var tempNewSetting: Type
```

### 4. データ変換

#### PresetManager.swift

```swift
// 現在の設定からプリセットを作成
func createPresetFromCurrentSettings(name: String) -> CornerPreset {
    let newSetting = UserDefaults.standard.object(forKey: "newSetting") as? Type ?? defaultValue

    return CornerPreset(
        // 既存のパラメータ...
        newSetting: newSetting
    )
}

// プリセットを適用
func applyPreset(_ preset: CornerPreset) {
    UserDefaults.standard.set(preset.newSetting, forKey: "newSetting")

    // 既存の適用処理...
}
```

#### EditPresetTabView.swift

必要に応じて `CornerPreset` の更新用メソッドを追加します。

```swift
extension CornerPreset {
    func withNewSetting(_ value: Type) -> CornerPreset {
        var updated = self
        updated.newSetting = value
        return updated
    }
}
```

### 5. ローカライゼーション

`Localizable.xcstrings` に、日本語と英語の表示文字列を追加します。

```json
{
  "new_setting_label": {
    "localizations": {
      "en": { "value": "New Setting" },
      "ja": { "value": "新しい設定" }
    }
  }
}
```

## アップグレード手順

### Step 1：データ構造を拡張する

1. `CornerPreset` に新しいプロパティを追加します。
2. 既存プリセットを読み込めるよう、既定値を用意します。
3. 必要に応じて `init` を更新します。

### Step 2：設定画面を更新する

1. `AdvancedSettingsView` に新しい State 変数を追加します。
2. UI コンポーネントを追加します。
3. `markAsChanged()` の変更検出へ新しい項目を含めます。
4. `applySettings()` に保存処理を追加します。
5. `resetToSavedValues()` に読み戻し処理を追加します。

### Step 3：プリセット編集画面を更新する

1. `EditPresetTabView` に新しい State 変数を追加します。
2. 設定画面と同じ UI コンポーネントを追加します。
3. `markAsChanged()` の変更検出へ新しい項目を含めます。
4. `savePreset()` に保存処理を追加します。

### Step 4：データ管理を更新する

1. `PresetManager.createPresetFromCurrentSettings()` を更新します。
2. `PresetManager.applyPreset()` を更新します。
3. 必要に応じて `CornerPreset` の更新用メソッドを追加します。

### Step 5：ローカライゼーションを追加する

1. `Localizable.xcstrings` にキーを追加します。
2. 日本語と英語の文字列を設定します。

## 注意事項

### UI の一貫性

- 設定画面とプリセット編集画面で同じ UI デザインを使用します。
- 同じローカライゼーションキーを使用します。
- 同じ既定値を使用します。

### データ型の互換性

- `UserDefaults` と `CornerPreset` で同じデータ型を使用します。
- `NSColor` と SwiftUI `Color` の変換が必要な場合は、保存形式を統一します。

### 既存バージョンとの互換性

- 新しい設定項目には既定値を用意します。
- 過去のプリセットに新しいキーがなくても読み込めるようにします。

### テスト

少なくとも次の動作を確認します。

- 設定画面で変更した値が保存されること。
- プリセット編集画面で変更した値が保存されること。
- プリセット適用時に新しい設定も反映されること。
- インポート / エクスポート後も値が保持されること。

## 例：アニメーション速度を追加する

### 1. データ構造

```swift
struct CornerPreset: Codable, Identifiable {
    // 既存...
    var animationSpeed: Double = 1.0
}
```

### 2. 設定画面

```swift
// AdvancedSettingsView
@State private var tempAnimationSpeed: Double = 1.0

VStack(alignment: .leading, spacing: 8) {
    Text("animation_speed")
        .font(.subheadline)
        .fontWeight(.medium)

    Slider(value: $tempAnimationSpeed, in: 0.1...5.0, step: 0.1)
        .onChange(of: tempAnimationSpeed) { _, _ in
            markAsChanged()
        }
}
```

### 3. プリセット編集画面

```swift
// EditPresetTabView
@State private var tempAnimationSpeed: Double

VStack(alignment: .leading, spacing: 8) {
    Text("animation_speed")
        .font(.subheadline)
        .fontWeight(.medium)

    Slider(value: $tempAnimationSpeed, in: 0.1...5.0, step: 0.1)
        .onChange(of: tempAnimationSpeed) { _, _ in
            markAsChanged()
        }
}
```

### 4. データ管理

```swift
// PresetManager
func createPresetFromCurrentSettings(name: String) -> CornerPreset {
    let animationSpeed = UserDefaults.standard.object(forKey: "animationSpeed") as? Double ?? 1.0

    return CornerPreset(
        // 既存...
        animationSpeed: animationSpeed
    )
}

extension CornerPreset {
    func withAnimationSpeed(_ speed: Double) -> CornerPreset {
        var updated = self
        updated.animationSpeed = speed
        return updated
    }
}
```

## 2026-04-25 の更新記録

### Metal 関連エラーへの対応

- **問題**：`flock failed to lock list file` エラーが発生しました。
- **対応**：
  - `Info.plist` に Metal デバッグ設定を追加しました。
  - `MTL_DEBUG_LAYER`、`MTL_ENABLE_DEBUG_INFO`、`MTL_HUD_ENABLED` を無効化しました。
  - `Rounder.entitlements` を追加しました。

### レイアウト再帰呼び出しへの対応

- **問題**：`layoutSubtreeIfNeeded` の再帰呼び出し警告が発生しました。
- **対応**：`draw` メソッド内でレイアウト操作を行わないようにしました。

### アプリ再起動処理の変更

- **問題**：設定適用時の再起動が不安定でした。
- **対応**：`Process` と `waitUntilExit()` を使う方式へ変更しました。
- **対象ファイル**：`ContentView.swift`, `FirstLaunchSetupView.swift`

### 描画処理の調整

- 線幅と描画順序を見直しました。
- ウィンドウを必要以上に再作成せず、再利用するようにしました。
- `dirtyRect` を使い、必要な領域だけを再描画するようにしました。

### エンタイトルメント

```xml
<!-- Rounder.entitlements -->
<key>com.apple.security.cs.allow-jit</key>
<true/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

### 変更ファイル

- `Info.plist`：Metal デバッグ設定を追加。
- `Rounder.entitlements`：新規追加。
- `RounderApp.swift`：環境変数設定と描画処理を調整。
- `CornerOverlayWindow.swift`：描画処理を調整。
- `ContentView.swift`：再起動処理を変更。
- `FirstLaunchSetupView.swift`：再起動処理を変更。

## まとめ

新しい設定項目を追加するときは、設定画面だけでなく、プリセットの保存形式、編集画面、適用処理、ローカライゼーション、テストまで一組として更新してください。
片方の画面だけを変更すると、通常設定とプリセットの間で値が一致しなくなるため、変更箇所をこの文書の手順で確認します。
