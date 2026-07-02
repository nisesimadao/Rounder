//
//  ContentView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI
import AppKit

// MARK: - Constants
/// ContentViewで使用する定数値を管理する構造体
struct ContentViewConstants {
    /// ゲーミングモード用フォント名
    static let gamingFontName = (Locale.current.language.languageCode?.identifier == "ja") ? "Hiragino Maru Gothic ProN" : "Comic Sans MS"
    /// ゲーミング速度の最小値
    static let gamingSpeedMin: Double = 0.1
    /// ゲーミング速度の最大値
    static let gamingSpeedMax: Double = 5.0
    /// ゲーミング速度のステップ
    static let gamingSpeedStep: Double = 0.1
    /// ブルーム強度の最小値
    static let glowIntensityMin: Double = 0.1
    /// ブルーム強度の最大値
    static let glowIntensityMax: Double = 3.0
    /// ブルーム強度のステップ
    static let glowIntensityStep: Double = 0.1
    /// テキストフィールドの幅
    static let textFieldWidth: CGFloat = 50
    /// ヘッダーアイコンサイズ
    static let headerIconSize: CGFloat = 24
    /// ボタン幅
    static let buttonWidth: CGFloat = 50
    /// ボタン高さ
    static let buttonHeight: CGFloat = 30
    /// スモールアイコンサイズ
    static let smallIconSize: CGFloat = 24
    /// ドットサイズ
    static let dotSize: CGFloat = 8
    /// スモールドットサイズ
    static let smallDotSize: CGFloat = 4
    /// クイック色選択ボタンのサイズ
    static let quickSelectColorSize: CGFloat = 24
}

// レインボーカラーの修飾子
struct RainbowEffect: ViewModifier {
    @State private var hue: Double = 0.0
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(hue: hue, saturation: 0.8, brightness: 0.8))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    hue = 1.0
                }
            }
    }
}

extension Color {
    /// クイック選択の枠表示用の色一致判定。SwiftUI の `==` は NSColor アーカイブの往復や
    /// 色空間の違いで一致しなくなるため、sRGB に揃えて成分で比較する。
    func matchesSwatch(_ other: Color) -> Bool {
        guard let a = NSColor(self).usingColorSpace(.sRGB),
              let b = NSColor(other).usingColorSpace(.sRGB) else {
            return NSColor(self).isEqual(NSColor(other))
        }
        let tolerance: CGFloat = 0.01
        return abs(a.redComponent - b.redComponent) < tolerance &&
               abs(a.greenComponent - b.greenComponent) < tolerance &&
               abs(a.blueComponent - b.blueComponent) < tolerance &&
               abs(a.alphaComponent - b.alphaComponent) < tolerance
    }
}

extension View {
    func rainbow() -> some View {
        self.modifier(RainbowEffect())
    }
    
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
}

// MARK: - Common Components
/// スライダーとテキストフィールドを組み合わせた共通コンポーネント
/// ゲーミング速度やブルーム強度などの調整に使用する
struct SliderWithTextField: View {
    /// タイトル
    let title: String
    /// バインディングされた値
    @Binding var value: Double
    /// 値の範囲
    let range: ClosedRange<Double>
    /// ステップ値
    let step: Double
    /// アクセントカラー
    let accentColor: Color
    /// 値が変更された時のコールバック
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.custom(ContentViewConstants.gamingFontName, size: 14))
                    .foregroundColor(accentColor)
                Spacer()
                HStack(spacing: 4) {
                    TextField("1.0", value: $value, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: ContentViewConstants.textFieldWidth)
                        .multilineTextAlignment(.center)
                        .font(.custom(ContentViewConstants.gamingFontName, size: 12))
                        .onChange(of: value) { _, newValue in
                            let clampedValue = max(range.lowerBound, min(range.upperBound, newValue))
                            if clampedValue != newValue {
                                value = clampedValue
                            } else {
                                onChange()
                            }
                        }
                    
                    Text("x")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(accentColor)
                .onChange(of: value) { _, _ in
                    onChange()
                }
            
            // 範囲のヒント
            HStack {
                Text("\(range.lowerBound.formatted())x")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(range.upperBound.formatted())x")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, -4)
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage(UserDefaultsKeys.cornerRadius) private var cornerRadius: Double = RounderAppConstants.defaultCornerRadius
    @AppStorage(UserDefaultsKeys.cornerColor) private var cornerColorData: Data = Data()
    @AppStorage(UserDefaultsKeys.isEnabled) private var isEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.superGamingMode) private var savedSuperGamingMode: Bool = false
    @AppStorage(UserDefaultsKeys.gamingSpeed) private var savedGamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed
    @AppStorage(UserDefaultsKeys.glowIntensity) private var savedGlowIntensity: Double = PresetManagerConstants.defaultGlowIntensity
    @AppStorage(UserDefaultsKeys.cornerCutoutStyle) private var savedCornerCutoutStyleRawValue: String = CornerCutoutStyle.rounded.rawValue
    @AppStorage(UserDefaultsKeys.topLeftEnabled) private var savedTopLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.topRightEnabled) private var savedTopRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomLeftEnabled) private var savedBottomLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomRightEnabled) private var savedBottomRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.selectedDisplayIDs) private var savedDisplayIDs: Data = Data()
    @State private var selectedColor: Color = .black
    @State private var hasUnsavedChanges: Bool = false
    @State private var selectedTab: Int = 0
    @State private var tempRadius: Double = RounderAppConstants.defaultCornerRadius
    @State private var tempColor: Color = .black
    @State private var tempEnabled: Bool = true
    @State private var tempTopLeftEnabled: Bool = true
    @State private var tempTopRightEnabled: Bool = true
    @State private var tempBottomLeftEnabled: Bool = true
    @State private var tempBottomRightEnabled: Bool = true
    @State private var tempCornerCutoutStyle: CornerCutoutStyle = .rounded
    @State private var superGamingMode: Bool = false
    @State private var gamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed
    @State private var glowIntensity: Double = PresetManagerConstants.defaultGlowIntensity
    @State private var availableDisplays: [DisplayInfo] = []
    @State private var selectedDisplays: Set<CGDirectDisplayID> = Set()
    
    // バージョン情報
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return String(format: String(localized: "version_with_build", defaultValue: "Version %@ (%@)"), version, build)
        }
        return String(localized: "version_unknown", defaultValue: "Version Unknown")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Image("ICON")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: ContentViewConstants.headerIconSize, height: ContentViewConstants.headerIconSize)
                
                Text("rounder_settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(appVersion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // タブコンテンツ
            TabView(selection: $selectedTab) {
                // 設定タブ
                SettingsTabView(
                    tempRadius: $tempRadius,
                    tempColor: $tempColor,
                    tempEnabled: $tempEnabled,
                    tempTopLeftEnabled: $tempTopLeftEnabled,
                    tempTopRightEnabled: $tempTopRightEnabled,
                    tempBottomLeftEnabled: $tempBottomLeftEnabled,
                    tempBottomRightEnabled: $tempBottomRightEnabled,
                    tempCornerCutoutStyle: $tempCornerCutoutStyle,
                    hasUnsavedChanges: $hasUnsavedChanges,
                    superGamingMode: $superGamingMode,
                    gamingSpeed: $gamingSpeed,
                    glowIntensity: $glowIntensity,
                    availableDisplays: $availableDisplays,
                    selectedDisplays: $selectedDisplays,
                    markAsChanged: markAsChanged,
                    refreshDisplayList: refreshDisplayList
                )
                .tabItem {
                    Label("settings_tab", systemImage: "slider.horizontal.3")
                }
                .tag(0)
                
                // プリセットタブ
                PresetsTabView()
                .tabItem {
                    Label("presets_tab", systemImage: "bookmark.square")
                }
                .tag(1)

                // 情報タブ
                CreditsTabView()
                .tabItem {
                    Label("credits_tab", systemImage: "info.circle")
                }
                .tag(2)
            }
            .padding()
            
            // フッターボタン
            HStack(spacing: 12) {
                Button("cancel") {
                    resetToSavedValues()
                    closeSettings()
                }
                .keyboardShortcut(.escape)
                
                Button("apply") {
                    applySettings()
                }
                .disabled(!hasUnsavedChanges)
                .keyboardShortcut(.return, modifiers: .command)

                Button("ok") {
                    applySettings()
                    closeSettings()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("exit") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(
            minWidth: RounderAppConstants.minWindowSize.width,
            idealWidth: RounderAppConstants.settingsWindowSize.width,
            minHeight: RounderAppConstants.minWindowSize.height,
            idealHeight: RounderAppConstants.settingsWindowSize.height
        )
        .onAppear {
            loadSavedColor()
            resetToSavedValues()
            loadDisplaySettings()
        }
        .onChange(of: cornerRadius) { _, newValue in
            selectedColor = loadColorFromData(cornerColorData)
            tempRadius = newValue
        }
        .onChange(of: cornerColorData) { _, newData in
            selectedColor = loadColorFromData(newData)
            tempColor = selectedColor
        }
        .onChange(of: savedCornerCutoutStyleRawValue) { _, newValue in
            tempCornerCutoutStyle = CornerCutoutStyle(rawValue: newValue) ?? .rounded
        }
        .onChange(of: isEnabled) { _, newValue in
            tempEnabled = newValue
        }
        // プリセット適用など、設定ウィンドウの外から保存値が変わったときにも
        // 各タブの一時状態を追従させる（ウィンドウは使い回されるため onAppear は再実行されない）。
        .onChange(of: savedTopLeftEnabled) { _, newValue in tempTopLeftEnabled = newValue }
        .onChange(of: savedTopRightEnabled) { _, newValue in tempTopRightEnabled = newValue }
        .onChange(of: savedBottomLeftEnabled) { _, newValue in tempBottomLeftEnabled = newValue }
        .onChange(of: savedBottomRightEnabled) { _, newValue in tempBottomRightEnabled = newValue }
        .onChange(of: savedSuperGamingMode) { _, newValue in superGamingMode = newValue }
        .onChange(of: savedGamingSpeed) { _, newValue in gamingSpeed = newValue }
        .onChange(of: savedGlowIntensity) { _, newValue in glowIntensity = newValue }
    }
    
    // MARK: - 設定管理
    private func markAsChanged() {
        // 現在の一時値と保存値を比較
        let radiusChanged = tempRadius != cornerRadius
        let colorChanged = !colorsEqual(tempColor, selectedColor)
        let enabledChanged = tempEnabled != isEnabled
        let gamingModeChanged = superGamingMode != savedSuperGamingMode
        let gamingSpeedChanged = gamingSpeed != savedGamingSpeed
        let glowIntensityChanged = glowIntensity != savedGlowIntensity
        let cutoutStyleChanged = tempCornerCutoutStyle != (CornerCutoutStyle(rawValue: savedCornerCutoutStyleRawValue) ?? .rounded)
        let topLeftChanged = tempTopLeftEnabled != savedTopLeftEnabled
        let topRightChanged = tempTopRightEnabled != savedTopRightEnabled
        let bottomLeftChanged = tempBottomLeftEnabled != savedBottomLeftEnabled
        let bottomRightChanged = tempBottomRightEnabled != savedBottomRightEnabled
        
        // モニター選択の変更をチェック（保存値の読み出しは savedSelectedDisplays() に一本化）
        let displaySelectionChanged = savedSelectedDisplays() != selectedDisplays
        
        hasUnsavedChanges = radiusChanged || colorChanged || enabledChanged || gamingModeChanged || gamingSpeedChanged || glowIntensityChanged || cutoutStyleChanged || topLeftChanged || topRightChanged || bottomLeftChanged || bottomRightChanged || displaySelectionChanged
    }
    
    private func colorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let nsColor1 = NSColor(color1)
        let nsColor2 = NSColor(color2)
        return nsColor1.isEqual(nsColor2)
    }
    
    private func applySettings() {
        // @AppStorageを直接更新
        cornerRadius = tempRadius
        isEnabled = tempEnabled
        savedSuperGamingMode = superGamingMode
        savedGamingSpeed = gamingSpeed
        savedGlowIntensity = glowIntensity
        savedCornerCutoutStyleRawValue = tempCornerCutoutStyle.rawValue
        savedTopLeftEnabled = tempTopLeftEnabled
        savedTopRightEnabled = tempTopRightEnabled
        savedBottomLeftEnabled = tempBottomLeftEnabled
        savedBottomRightEnabled = tempBottomRightEnabled
        
        // 色を保存
        let nsColor = NSColor(tempColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
        }
        
        // ディスプレイ設定を保存
        saveDisplaySettings()

        // 即時適用：保存済みの読み戻しではなく、現在の画面状態をそのまま反映する
        AppDelegate.shared?.applyOverlayConfiguration(currentOverlayConfiguration())

        hasUnsavedChanges = false
    }
    
    private func resetToSavedValues() {
        tempRadius = cornerRadius
        tempColor = selectedColor
        tempEnabled = isEnabled
        tempTopLeftEnabled = savedTopLeftEnabled
        tempTopRightEnabled = savedTopRightEnabled
        tempBottomLeftEnabled = savedBottomLeftEnabled
        tempBottomRightEnabled = savedBottomRightEnabled
        tempCornerCutoutStyle = CornerCutoutStyle(rawValue: savedCornerCutoutStyleRawValue) ?? .rounded
        superGamingMode = savedSuperGamingMode
        gamingSpeed = savedGamingSpeed
        glowIntensity = savedGlowIntensity
        // モニター選択もキャンセルで元に戻す（他の設定と同様に破棄する）
        selectedDisplays = savedSelectedDisplays()
        hasUnsavedChanges = false
    }
    
    private func closeSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示に戻す
        AppDelegate.shared?.hideSettings()
    }

    private func loadSavedColor() {
        selectedColor = loadColorFromData(cornerColorData)
    }
    
    private func loadColorFromData(_ data: Data) -> Color {
        guard !data.isEmpty,
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return .black
        }
        return Color(nsColor)
    }

    private func currentOverlayConfiguration() -> OverlayConfiguration {
        OverlayConfiguration(
            isEnabled: tempEnabled,
            radius: tempRadius,
            color: NSColor(tempColor),
            superGamingMode: superGamingMode,
            gamingSpeed: gamingSpeed,
            glowIntensity: glowIntensity,
            cutoutStyle: tempCornerCutoutStyle,
            topLeftEnabled: tempTopLeftEnabled,
            topRightEnabled: tempTopRightEnabled,
            bottomLeftEnabled: tempBottomLeftEnabled,
            bottomRightEnabled: tempBottomRightEnabled,
            selectedDisplayIDs: Array(selectedDisplays)
        )
    }
    
    /// 保存済みの選択ディスプレイ集合。未保存なら「接続中のすべて」を返す（ここでは保存しない）。
    /// 空の選択（全解除）は空集合として尊重する。
    private func savedSelectedDisplays() -> Set<CGDirectDisplayID> {
        // 現行フォーマット（JSON Data）。"[]" は空集合として正しく復元される。
        if let displayIDs = try? JSONDecoder().decode([UInt32].self, from: savedDisplayIDs) {
            return Set(displayIDs.map { CGDirectDisplayID($0) })
        }
        // 旧フォーマット（プレーンな [UInt32] 配列）からの移行を許容する
        if let legacy = UserDefaults.standard.array(forKey: UserDefaultsKeys.selectedDisplayIDs) as? [UInt32] {
            return Set(legacy.map { CGDirectDisplayID($0) })
        }
        return Set(NSScreen.getAllDisplayInfo().map { $0.displayID })
    }

    private func loadDisplaySettings() {
        // 利用可能なディスプレイと保存済みの選択を読み込む。
        // 読み取り時にデフォルトを書き込まないこと（一度でも設定を開くと選択が固定され、
        // 後から接続したモニターに角が出なくなる不具合の原因になる）。
        availableDisplays = NSScreen.getAllDisplayInfo()
        selectedDisplays = savedSelectedDisplays()
    }

    private func saveDisplaySettings() {
        // 選択されたディスプレイIDを保存（プリセットには含まれない）
        let selectedDisplayIDs = Array(selectedDisplays).map { UInt32($0) }
        if let encoded = try? JSONEncoder().encode(selectedDisplayIDs) {
            savedDisplayIDs = encoded
        }
    }

    private func refreshDisplayList() {
        // 既知のディスプレイと以前の選択状態を控えておく
        let previouslyKnownIDs = Set(availableDisplays.map { $0.displayID })
        let previouslySelectedIDs = selectedDisplays

        // ディスプレイリストを更新
        availableDisplays = NSScreen.getAllDisplayInfo()

        // 既知のディスプレイは以前の選択状態を尊重し、新しく接続されたディスプレイは既定で選択する
        selectedDisplays = Set(availableDisplays.compactMap { display -> CGDirectDisplayID? in
            let isKnown = previouslyKnownIDs.contains(display.displayID)
            let keep = isKnown ? previouslySelectedIDs.contains(display.displayID) : true
            return keep ? display.displayID : nil
        })

        markAsChanged()
    }
}

// MARK: - タブビューコンポーネント

struct SettingsTabView: View {
    @Binding var tempRadius: Double
    @Binding var tempColor: Color
    @Binding var tempEnabled: Bool
    @Binding var tempTopLeftEnabled: Bool
    @Binding var tempTopRightEnabled: Bool
    @Binding var tempBottomLeftEnabled: Bool
    @Binding var tempBottomRightEnabled: Bool
    @Binding var tempCornerCutoutStyle: CornerCutoutStyle
    @Binding var hasUnsavedChanges: Bool
    @Binding var superGamingMode: Bool
    @Binding var gamingSpeed: Double
    @Binding var glowIntensity: Double
    @Binding var availableDisplays: [DisplayInfo]
    @Binding var selectedDisplays: Set<CGDirectDisplayID>
    let markAsChanged: () -> Void
    let refreshDisplayList: () -> Void

    // ログイン時起動はシステム状態なので、適用フローとは独立に即時反映する
    @State private var launchAtLogin: Bool = LoginItemManager.isEnabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
            // 有効/無効トグル
            VStack(alignment: .leading, spacing: 8) {
                Text("general")
                    .font(.headline)

                Toggle("enable_rounded_corners", isOn: $tempEnabled)
                    .onChange(of: tempEnabled) { _, _ in
                        markAsChanged()
                    }

                Toggle("launch_at_login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        // 反映後の実状態に同期（登録に失敗したら元へ戻る）
                        let applied = LoginItemManager.setEnabled(newValue)
                        if applied != newValue {
                            launchAtLogin = applied
                        }
                    }
            }
            
            // モニター選択
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("monitor_selection")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("refresh_monitors") {
                        refreshDisplayList()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("select_monitors_description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(availableDisplays) { display in
                        Toggle(isOn: Binding(
                            get: { selectedDisplays.contains(display.displayID) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDisplays.insert(display.displayID)
                                } else {
                                    selectedDisplays.remove(display.displayID)
                                }
                                markAsChanged()
                            }
                        )) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(display.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(Int(display.resolution.width))×\(Int(display.resolution.height))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if display.isMain {
                                    Text("main_display")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            
            // 角の半径設定
            VStack(alignment: .leading, spacing: 12) {
                Text("appearance")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("corner_radius")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("0", value: $tempRadius, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: ContentViewConstants.buttonWidth)
                                .multilineTextAlignment(.center)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: tempRadius) { _, newValue in
                                    // 負の数値を禁止し、範囲を制限
                                    let clampedValue = max(0, min(40, newValue))
                                    if clampedValue != newValue {
                                        tempRadius = clampedValue
                                    } else {
                                        markAsChanged()
                                    }
                                }
                            
                            Text("px")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .padding(.leading, 2)
                        }
                    }
                    
                    Slider(value: $tempRadius, in: RounderAppConstants.cornerRadiusMin...RounderAppConstants.cornerRadiusMax, step: RounderAppConstants.cornerRadiusStep)
                        .onChange(of: tempRadius) { _, _ in
                            markAsChanged()
                        }
                    
                    // 範囲のヒント
                    HStack {
                        Text("0px")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("40px")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, -4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("corner_shape")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("corner_shape", selection: $tempCornerCutoutStyle) {
                        Text("rounded_corner").tag(CornerCutoutStyle.rounded)
                        Text("squircle_corner").tag(CornerCutoutStyle.squircle)
                        Text("polygon_cutout").tag(CornerCutoutStyle.polygon)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tempCornerCutoutStyle) { _, _ in
                        markAsChanged()
                    }
                }
                
                // 四つの角の切り欠き設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("corner_visibility")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        // 上段
                        HStack(spacing: 20) {
                            Toggle("top_left_corner", isOn: $tempTopLeftEnabled)
                                .onChange(of: tempTopLeftEnabled) { _, _ in
                                    markAsChanged()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Toggle("top_right_corner", isOn: $tempTopRightEnabled)
                                .onChange(of: tempTopRightEnabled) { _, _ in
                                    markAsChanged()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // 下段
                        HStack(spacing: 20) {
                            Toggle("bottom_left_corner", isOn: $tempBottomLeftEnabled)
                                .onChange(of: tempBottomLeftEnabled) { _, _ in
                                    markAsChanged()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Toggle("bottom_right_corner", isOn: $tempBottomRightEnabled)
                                .onChange(of: tempBottomRightEnabled) { _, _ in
                                    markAsChanged()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                // 色選択
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("corner_color")
                        Spacer()
                    }
                    
                    HStack(spacing: 15) {
                        ColorPicker("", selection: $tempColor)
                            .labelsHidden()
                            .frame(width: ContentViewConstants.buttonWidth, height: ContentViewConstants.buttonHeight)
                            .onChange(of: tempColor) { _, _ in
                                markAsChanged()
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("quick_select")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach([Color.black, Color.white, Color.gray], id: \.self) { color in
                                    Button(action: {
                                        tempColor = color
                                        markAsChanged()
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: ContentViewConstants.quickSelectColorSize, height: ContentViewConstants.quickSelectColorSize)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: tempColor.matchesSwatch(color) ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // すーぱーげーみんぐもーど
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("super_gaming_mode", isOn: $superGamingMode)
                            .font(.custom(ContentViewConstants.gamingFontName, size: 16))
                            .fontWeight(.bold)
                            .applyIf(superGamingMode) { view in
                                view.modifier(RainbowEffect())
                            }
                            .onChange(of: superGamingMode) { _, _ in
                                markAsChanged()
                            }
                        
                        if superGamingMode {
                            VStack(alignment: .leading, spacing: 16) {
                                SliderWithTextField(
                                    title: "gaming_speed",
                                    value: $gamingSpeed,
                                    range: ContentViewConstants.gamingSpeedMin...ContentViewConstants.gamingSpeedMax,
                                    step: ContentViewConstants.gamingSpeedStep,
                                    accentColor: .orange,
                                    onChange: markAsChanged
                                )
                                
                                SliderWithTextField(
                                    title: "glow_intensity",
                                    value: $glowIntensity,
                                    range: ContentViewConstants.glowIntensityMin...ContentViewConstants.glowIntensityMax,
                                    step: ContentViewConstants.glowIntensityStep,
                                    accentColor: .cyan,
                                    onChange: markAsChanged
                                )
                            }
                            .padding(.leading, 16)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: superGamingMode)
                        }
                    }
                }
            }
            
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // 設定ウィンドウは close ではなく orderOut で使い回されるため onAppear が再発火しない。
            // 設定を開くとアプリがアクティブ化されるので、その契機で実状態へ同期する。
            launchAtLogin = LoginItemManager.isEnabled
        }
    }
}

struct CreditsTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("credits")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                CreditSection(
                    title: String(localized: "developer"),
                    items: [
                        String(localized: "credit_developer_name"),
                        String(localized: "credit_implementation")
                    ]
                )
                
                CreditSection(
                    title: String(localized: "technology_credit"),
                    items: [
                        String(localized: "credit_drawing_engine"),
                        String(localized: "credit_overlay_system"),
                        String(localized: "credit_settings_management")
                    ]
                )
                
                CreditSection(
                    title: String(localized: "license"),
                    items: [
                        "MIT License",
                        String(localized: "credit_open_source")
                    ]
                )
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("support")
                    .font(.headline)
                
                Text("github_issues_description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(String(localized: "open_github")) {
                    if let url = URL(string: "https://github.com/nisesimadao/rounder") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
}

struct CreditSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: ContentViewConstants.smallDotSize, height: ContentViewConstants.smallDotSize)
                        
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    AdvancedSettingsView()
}
