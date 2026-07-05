# 機能アップグレードガイド

## 概要

このドキュメントは、設定画面（`ContentView.swift`の`SettingsTabView`）に新しい機能を追加する際、プリセット編集画面（`EditPresetTabView.swift`）も同期してアップグレードするためのガイドです。

## アーキテクチャ

### 設定画面の構成
- **ファイル**: `ContentView.swift`
- **主要コンポーネント**: `SettingsTabView`
- **役割**: アプリの現在の設定を管理・表示

### プリセット編集画面の構成  
- **ファイル**: `EditPresetTabView.swift`
- **主要コンポーネント**: `EditPresetTabView`
- **役割**: プリセットに保存された設定を編集

## 同期アップグレードの原則

### 1. データ構造の同期
設定画面に新しい設定項目を追加する場合、以下のデータ構造を同期する必要があります：

```swift
// PresetManager.swift - CornerPreset構造体
struct CornerPreset: Codable, Identifiable {
    // 既存のプロパティ...
    
    // 新しい設定項目をここに追加
    var newSetting: Type = defaultValue
}
```

### 2. UIコンポーネントの同期
設定画面とプリセット編集画面で同じUIコンポーネントを使用する：

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

### 3. State管理の同期

#### 設定画面のState変数
```swift
// ContentView.swift - AdvancedSettingsView
@State private var tempNewSetting: Type = defaultValue
```

#### プリセット編集画面のState変数
```swift
// EditPresetTabView.swift
@State private var tempNewSetting: Type
```

### 4. データ変換メソッドの拡張

#### PresetManager.swiftに追加
```swift
// 現在の設定からプリセットを作成
func createPresetFromCurrentSettings(name: String) -> CornerPreset {
    // 新しい設定項目を追加
    let newSetting = UserDefaults.standard.object(forKey: "newSetting") as? Type ?? defaultValue
    
    return CornerPreset(
        // 既存のパラメータ...
        newSetting: newSetting
    )
}

// プリセットを適用
func applyPreset(_ preset: CornerPreset) {
    // 新しい設定項目を適用
    UserDefaults.standard.set(preset.newSetting, forKey: "newSetting")
    
    // 既存の適用処理...
}
```

#### EditPresetTabView.swiftに拡張メソッドを追加
```swift
extension CornerPreset {
    func withNewSetting(_ value: Type) -> CornerPreset {
        var updated = self
        updated.newSetting = value
        return updated
    }
}
```

### 5. ローカライゼーションの同期

#### Localizable.xcstringsに追加
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

### Step 1: データ構造の拡張
1. `CornerPreset`構造体に新しいプロパティを追加
2. デフォルト値を設定
3. 必要に応じて`init`メソッドを更新

### Step 2: 設定画面の更新
1. `AdvancedSettingsView`に新しいState変数を追加
2. UIコンポーネントを追加
3. `markAsChanged()`に変更検出ロジックを追加
4. `applySettings()`に保存ロジックを追加
5. `resetToSavedValues()`にリセットロジックを追加

### Step 3: プリセット編集画面の更新
1. `EditPresetTabView`に新しいState変数を追加
2. 設定画面と同じUIコンポーネントを追加
3. `markAsChanged()`に変更検出ロジックを追加
4. `savePreset()`に保存ロジックを追加

### Step 4: データ管理の更新
1. `PresetManager.createPresetFromCurrentSettings()`を更新
2. `PresetManager.applyPreset()`を更新
3. `CornerPreset`拡張メソッドを追加

### Step 5: ローカライゼーションの追加
1. `Localizable.xcstrings`に新しい文字列を追加
2. 日本語と英語の翻訳を追加

## 注意事項

### 1. 一貫性の維持
- 設定画面とプリセット編集画面で同じUIデザインを使用する
- 同じローカライゼーションキーを使用する
- 同じデフォルト値を使用する

### 2. データ型の互換性
- `UserDefaults`と`CornerPreset`で同じデータ型を使用する
- NSColorとSwiftUI Colorの変換を正しく行う

### 3. バージョン互換性
- 新しい設定項目はオプション扱いにする
- 既存のプリセットが読み込めるようにデフォルト値を用意する

### 4. テスト
- 設定画面での変更が正しく保存されること
- プリセット編集画面での変更が正しく反映されること
- プリセットの適用が正しく動作すること
- インポート/エクスポートが正常に動作すること

## 具体例：新しい設定項目「アニメーション速度」を追加する場合

### 1. データ構造の拡張
```swift
struct CornerPreset: Codable, Identifiable {
    // 既存...
    var animationSpeed: Double = 1.0  // 新規追加
}
```

### 2. 設定画面の更新
```swift
// AdvancedSettingsView
@State private var tempAnimationSpeed: Double = 1.0

// UI追加
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

### 3. プリセット編集画面の更新
```swift
// EditPresetTabView
@State private var tempAnimationSpeed: Double

// 同じUIを追加
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

### 4. データ管理の更新
```swift
// PresetManager
func createPresetFromCurrentSettings(name: String) -> CornerPreset {
    let animationSpeed = UserDefaults.standard.object(forKey: "animationSpeed") as? Double ?? 1.0
    
    return CornerPreset(
        // 既存...
        animationSpeed: animationSpeed
    )
}

// 拡張メソッド
extension CornerPreset {
    func withAnimationSpeed(_ speed: Double) -> CornerPreset {
        var updated = self
        updated.animationSpeed = speed
        return updated
    }
}
```

## 最新のアップデート (2026-04-25)

### エラー修正とパフォーマンス最適化

#### 1. Metal関連エラーの修正
- **問題**: `flock failed to lock list file` エラーが発生
- **解決策**: 
  - `Info.plist` に Metal デバッグ設定を追加
  - 環境変数 `MTL_DEBUG_LAYER`, `MTL_ENABLE_DEBUG_INFO`, `MTL_HUD_ENABLED` を無効化
  - `Rounder.entitlements` ファイルを新規作成

#### 2. レイアウト再帰呼び出しの修正
- **問題**: `layoutSubtreeIfNeeded` の再帰呼び出し警告
- **解決策**: `draw` メソッド内でのレイアウト操作を回避

#### 3. アプリ再起動機能の改善
- **問題**: 設定適用時の再起動が不安定
- **解決策**: `Process` + `waitUntilExit()` 方式に変更
- **ファイル**: `ContentView.swift`, `FirstLaunchSetupView.swift`

#### 4. パフォーマンス最適化
- **描画パフォーマンス向上**: 線幅を細くし、描画順序を整理
- **メモリ使用量最適化**: ウィンドウの再作成を避けて再利用
- **再描画効率化**: `dirtyRect` のみを再描画

#### 5. エンタイトルメント設定
```xml
<!-- Rounder.entitlements -->
<key>com.apple.security.cs.allow-jit</key>
<true/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

### 変更ファイル一覧
- `Info.plist` - Metal デバッグ設定を追加
- `Rounder.entitlements` - 新規作成
- `RounderApp.swift` - 環境変数設定とパフォーマンス最適化
- `CornerOverlayWindow.swift` - 描画パフォーマンス最適化
- `ContentView.swift` - 再起動機能の改善
- `FirstLaunchSetupView.swift` - 再起動機能の改善


## まとめ

このガイドに従うことで、設定画面とプリセット編集画面の同期を維持し、一貫性のあるユーザー体験を提供できます。常に両画面の機能が同期していることを確認することが重要です。

最新のアップデートにより、アプリの安定性とパフォーマンスが大幅に向上しました。定期的にこのガイドを更新し、新たな改善点を追加してください。
