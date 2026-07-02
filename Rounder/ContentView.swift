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
    /// ブルームの広さ（範囲）
    static let bloomWidthMin: Double = 0.1
    static let bloomWidthMax: Double = 3.0
    static let bloomWidthStep: Double = 0.1
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

/// NSVisualEffectView をラップして、ウィンドウ背後をぼかす半透明（vibrancy）を提供する。
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
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


struct AdvancedSettingsView: View {
    @AppStorage(UserDefaultsKeys.cornerRadius) private var cornerRadius: Double = RounderAppConstants.defaultCornerRadius
    @AppStorage(UserDefaultsKeys.cornerColor) private var cornerColorData: Data = Data()
    @AppStorage(UserDefaultsKeys.isEnabled) private var isEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.superGamingMode) private var savedSuperGamingMode: Bool = false
    @AppStorage(UserDefaultsKeys.gamingSpeed) private var savedGamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed
    @AppStorage(UserDefaultsKeys.glowIntensity) private var savedGlowIntensity: Double = PresetManagerConstants.defaultGlowIntensity
    @AppStorage(UserDefaultsKeys.bloomWidth) private var savedBloomWidth: Double = PresetManagerConstants.defaultBloomWidth
    @AppStorage(UserDefaultsKeys.cornerCutoutStyle) private var savedCornerCutoutStyleRawValue: String = CornerCutoutStyle.rounded.rawValue
    @AppStorage(UserDefaultsKeys.topLeftEnabled) private var savedTopLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.topRightEnabled) private var savedTopRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomLeftEnabled) private var savedBottomLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomRightEnabled) private var savedBottomRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.selectedDisplayIDs) private var savedDisplayIDs: Data = Data()
    @State private var selectedColor: Color = .black
    @State private var hasUnsavedChanges: Bool = false
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
    @State private var bloomWidth: Double = PresetManagerConstants.defaultBloomWidth
    @State private var availableDisplays: [DisplayInfo] = []
    @State private var selectedDisplays: Set<CGDirectDisplayID> = Set()
    @State private var scrolledPane: SettingsPane? = .general
    @State private var launchAtLogin: Bool = LoginItemManager.isEnabled

    // サイドバーの各セクション
    enum SettingsPane: String, CaseIterable, Identifiable {
        case general, appearance, corners, displays, gaming, presets, about
        var id: String { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .general:    return "pane_general"
            case .appearance: return "pane_appearance"
            case .corners:    return "pane_corners"
            case .displays:   return "pane_displays"
            case .gaming:     return "pane_gaming"
            case .presets:    return "presets_tab"
            case .about:      return "credits_tab"
            }
        }

        var icon: String {
            switch self {
            case .general:    return "gearshape"
            case .appearance: return "paintpalette"
            case .corners:    return "rectangle.roundedbottom"
            case .displays:   return "display"
            case .gaming:     return "gamecontroller"
            case .presets:    return "bookmark"
            case .about:      return "info.circle"
            }
        }

        /// 適用/OK/キャンセルのフッターを出すセクション（プリセット・情報は独立操作）
        var showsActionBar: Bool { self != .presets && self != .about }
    }

    // バージョン情報
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return String(format: String(localized: "version_with_build", defaultValue: "Version %@ (%@)"), version, build)
        }
        return String(localized: "version_unknown", defaultValue: "Version Unknown")
    }
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailColumn
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .frame(
            minWidth: RounderAppConstants.settingsMinWindowSize.width,
            idealWidth: RounderAppConstants.settingsWindowSize.width,
            minHeight: RounderAppConstants.settingsMinWindowSize.height,
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
        .onChange(of: savedBloomWidth) { _, newValue in bloomWidth = newValue }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLogin = LoginItemManager.isEnabled
        }
    }

    // MARK: - モダンUI（サイドバー + グループForm）

    // MARK: サイドバー（セクションへジャンプ＋スクロール追従ハイライト）

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 10) {
                Image("ICON")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rounder").font(.system(size: 14, weight: .semibold))
                    Text(appVersion).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 28)
            .padding(.bottom, 12)

            ForEach(SettingsPane.allCases) { pane in
                if pane == .presets { Divider().padding(.vertical, 4) }
                sidebarButton(pane)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 216)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }

    private func sidebarButton(_ pane: SettingsPane) -> some View {
        let selected = (scrolledPane == pane)
        return Button {
            scrolledPane = pane
        } label: {
            HStack(spacing: 9) {
                Image(systemName: pane.icon)
                    .font(.system(size: 13))
                    .frame(width: 20)
                    .foregroundStyle(selected ? Color.white : Color.secondary)
                Text(pane.titleKey)
                    .font(.system(size: 13))
                    .foregroundStyle(selected ? Color.white : Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(selected ? Color.accentColor : Color.clear,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: 詳細（全セクションを1つの連続スクロールに並べる）

    private var detailColumn: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    sectionCard(.general) { generalContent }
                    sectionCard(.appearance) { appearanceContent }
                    sectionCard(.corners) { cornersContent }
                    sectionCard(.displays) { displaysContent }
                    sectionCard(.gaming) { gamingContent }
                    sectionCard(.presets) { PresetsTabView() }
                    sectionCard(.about) { CreditsTabView() }
                }
                .scrollTargetLayout()
                .padding(24)
            }
            .scrollPosition(id: $scrolledPane, anchor: .top)
            .scrollContentBackground(.hidden)

            Divider()
            actionBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// セクション見出し＋半透明のカード
    @ViewBuilder
    private func sectionCard<Content: View>(_ pane: SettingsPane,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: pane.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(pane.titleKey)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
        .id(pane)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 各セクションの中身（Formを使わずカード内に直接配置）

    @ViewBuilder private var generalContent: some View {
        Toggle("enable_rounded_corners", isOn: $tempEnabled)
            .onChange(of: tempEnabled) { _, _ in markAsChanged() }
        Divider()
        Toggle("launch_at_login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { _, newValue in
                let applied = LoginItemManager.setEnabled(newValue)
                if applied != newValue { launchAtLogin = applied }
            }
    }

    @ViewBuilder private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("corner_radius")
                Spacer()
                Text("\(Int(tempRadius)) px").monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: $tempRadius,
                   in: RounderAppConstants.cornerRadiusMin...RounderAppConstants.cornerRadiusMax,
                   step: RounderAppConstants.cornerRadiusStep)
                .onChange(of: tempRadius) { _, newValue in
                    let clamped = max(0, min(40, newValue))
                    if clamped != newValue { tempRadius = clamped } else { markAsChanged() }
                }
        }
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            Text("corner_shape").font(.subheadline).foregroundStyle(.secondary)
            Picker("corner_shape", selection: $tempCornerCutoutStyle) {
                Text("rounded_corner").tag(CornerCutoutStyle.rounded)
                Text("squircle_corner").tag(CornerCutoutStyle.squircle)
                Text("polygon_cutout").tag(CornerCutoutStyle.polygon)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: tempCornerCutoutStyle) { _, _ in markAsChanged() }
        }
        Divider()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("corner_color")
                Spacer()
                ColorPicker("", selection: $tempColor)
                    .labelsHidden()
                    .onChange(of: tempColor) { _, _ in markAsChanged() }
            }
            HStack(spacing: 10) {
                Text("quick_select").font(.caption).foregroundStyle(.secondary)
                Spacer()
                ForEach([Color.black, Color.white, Color.gray], id: \.self) { color in
                    Button {
                        tempColor = color
                        markAsChanged()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(.separator, lineWidth: 0.5))
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: tempColor.matchesSwatch(color) ? 2.5 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder private var cornersContent: some View {
        Grid(horizontalSpacing: 24, verticalSpacing: 12) {
            GridRow {
                Toggle("top_left_corner", isOn: $tempTopLeftEnabled)
                    .onChange(of: tempTopLeftEnabled) { _, _ in markAsChanged() }
                Toggle("top_right_corner", isOn: $tempTopRightEnabled)
                    .onChange(of: tempTopRightEnabled) { _, _ in markAsChanged() }
            }
            GridRow {
                Toggle("bottom_left_corner", isOn: $tempBottomLeftEnabled)
                    .onChange(of: tempBottomLeftEnabled) { _, _ in markAsChanged() }
                Toggle("bottom_right_corner", isOn: $tempBottomRightEnabled)
                    .onChange(of: tempBottomRightEnabled) { _, _ in markAsChanged() }
            }
        }
    }

    @ViewBuilder private var displaysContent: some View {
        HStack {
            Text("select_monitors_description").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button {
                refreshDisplayList()
            } label: {
                Label("refresh_monitors", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        ForEach(Array(availableDisplays.enumerated()), id: \.element.id) { index, display in
            if index > 0 { Divider() }
            Toggle(isOn: Binding(
                get: { selectedDisplays.contains(display.displayID) },
                set: { isSelected in
                    if isSelected { selectedDisplays.insert(display.displayID) }
                    else { selectedDisplays.remove(display.displayID) }
                    markAsChanged()
                }
            )) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(display.name).fontWeight(.medium)
                        Text("\(Int(display.resolution.width))×\(Int(display.resolution.height))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if display.isMain {
                        Text("main_display")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }

    @ViewBuilder private var gamingContent: some View {
        Toggle("super_gaming_mode", isOn: $superGamingMode)
            .onChange(of: superGamingMode) { _, _ in markAsChanged() }
        if superGamingMode {
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("gaming_speed")
                    Spacer()
                    Text(String(format: "%.1fx", gamingSpeed)).monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $gamingSpeed,
                       in: ContentViewConstants.gamingSpeedMin...ContentViewConstants.gamingSpeedMax,
                       step: ContentViewConstants.gamingSpeedStep)
                    .tint(.orange)
                    .onChange(of: gamingSpeed) { _, _ in markAsChanged() }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("glow_intensity")
                    Spacer()
                    Text(String(format: "%.1fx", glowIntensity)).monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $glowIntensity,
                       in: ContentViewConstants.glowIntensityMin...ContentViewConstants.glowIntensityMax,
                       step: ContentViewConstants.glowIntensityStep)
                    .tint(.cyan)
                    .onChange(of: glowIntensity) { _, _ in markAsChanged() }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("bloom_width")
                    Spacer()
                    Text(String(format: "%.1fx", bloomWidth)).monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $bloomWidth,
                       in: ContentViewConstants.bloomWidthMin...ContentViewConstants.bloomWidthMax,
                       step: ContentViewConstants.bloomWidthStep)
                    .tint(.purple)
                    .onChange(of: bloomWidth) { _, _ in markAsChanged() }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("exit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            Spacer()
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
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
        let bloomWidthChanged = bloomWidth != savedBloomWidth
        let cutoutStyleChanged = tempCornerCutoutStyle != (CornerCutoutStyle(rawValue: savedCornerCutoutStyleRawValue) ?? .rounded)
        let topLeftChanged = tempTopLeftEnabled != savedTopLeftEnabled
        let topRightChanged = tempTopRightEnabled != savedTopRightEnabled
        let bottomLeftChanged = tempBottomLeftEnabled != savedBottomLeftEnabled
        let bottomRightChanged = tempBottomRightEnabled != savedBottomRightEnabled
        
        // モニター選択の変更をチェック（保存値の読み出しは savedSelectedDisplays() に一本化）
        let displaySelectionChanged = savedSelectedDisplays() != selectedDisplays
        
        hasUnsavedChanges = radiusChanged || colorChanged || enabledChanged || gamingModeChanged || gamingSpeedChanged || glowIntensityChanged || bloomWidthChanged || cutoutStyleChanged || topLeftChanged || topRightChanged || bottomLeftChanged || bottomRightChanged || displaySelectionChanged
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
        savedBloomWidth = bloomWidth
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
        bloomWidth = savedBloomWidth
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
            bloomWidth: bloomWidth,
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
