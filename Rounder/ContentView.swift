//
//  ContentView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI
import AppKit

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
    @AppStorage("cornerRadius") private var cornerRadius: Double = 20.0
    @AppStorage("cornerColor") private var cornerColorData: Data = Data()
    @AppStorage("isEnabled") private var isEnabled: Bool = true
    @AppStorage("superGamingMode") private var savedSuperGamingMode: Bool = false
    @AppStorage("gamingSpeed") private var savedGamingSpeed: Double = 1.0
    @AppStorage("glowIntensity") private var savedGlowIntensity: Double = 1.0
    @AppStorage("topLeftEnabled") private var savedTopLeftEnabled: Bool = true
    @AppStorage("topRightEnabled") private var savedTopRightEnabled: Bool = true
    @AppStorage("bottomLeftEnabled") private var savedBottomLeftEnabled: Bool = true
    @AppStorage("bottomRightEnabled") private var savedBottomRightEnabled: Bool = true
    @State private var selectedColor: Color = .black
    @State private var hasUnsavedChanges: Bool = false
    @State private var selectedTab: Int = 0
    
    // 一時的な設定値
    @State private var tempRadius: Double = 20.0
    @State private var tempColor: Color = .black
    @State private var tempEnabled: Bool = true
    
    // 四つの角の切り欠き設定
    @State private var tempTopLeftEnabled: Bool = true
    @State private var tempTopRightEnabled: Bool = true
    @State private var tempBottomLeftEnabled: Bool = true
    @State private var tempBottomRightEnabled: Bool = true
    
    // すーぱーげーみんぐもーど設定
    @State private var superGamingMode: Bool = false
    @State private var gamingSpeed: Double = 1.0
    @State private var glowIntensity: Double = 1.0
    
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
                    .frame(width: 24, height: 24)
                
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
                    hasUnsavedChanges: $hasUnsavedChanges,
                    superGamingMode: $superGamingMode,
                    gamingSpeed: $gamingSpeed,
                    glowIntensity: $glowIntensity,
                    markAsChanged: markAsChanged
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
                
                // 権限タブ
                PermissionsTabView()
                .tabItem {
                    Label("permissions_tab", systemImage: "lock.shield")
                }
                .tag(2)
                
                // クレジットタブ
                CreditsTabView()
                .tabItem {
                    Label("credits_tab", systemImage: "info.circle")
                }
                .tag(3)
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
        .frame(minWidth: 500, idealWidth: 600, maxWidth: .infinity, minHeight: 450, idealHeight: 650, maxHeight: .infinity)
        .onAppear {
            loadSavedColor()
            resetToSavedValues()
        }
        .onChange(of: cornerRadius) { _, newValue in
            selectedColor = loadColorFromData(cornerColorData)
            tempRadius = newValue
        }
        .onChange(of: cornerColorData) { _, newData in
            selectedColor = loadColorFromData(newData)
            tempColor = selectedColor
        }
        .onChange(of: isEnabled) { _, newValue in
            tempEnabled = newValue
        }
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
        let topLeftChanged = tempTopLeftEnabled != savedTopLeftEnabled
        let topRightChanged = tempTopRightEnabled != savedTopRightEnabled
        let bottomLeftChanged = tempBottomLeftEnabled != savedBottomLeftEnabled
        let bottomRightChanged = tempBottomRightEnabled != savedBottomRightEnabled
        
        hasUnsavedChanges = radiusChanged || colorChanged || enabledChanged || gamingModeChanged || gamingSpeedChanged || glowIntensityChanged || topLeftChanged || topRightChanged || bottomLeftChanged || bottomRightChanged
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
        savedTopLeftEnabled = tempTopLeftEnabled
        savedTopRightEnabled = tempTopRightEnabled
        savedBottomLeftEnabled = tempBottomLeftEnabled
        savedBottomRightEnabled = tempBottomRightEnabled
        
        // 色を保存
        let nsColor = NSColor(tempColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
        }
        
        // 即時適用：AppDelegateに設定変更を通知
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.updateOverlaySettings(radius: CGFloat(cornerRadius), color: NSColor(tempColor))
            appDelegate.updateGamingMode(enabled: superGamingMode, speed: gamingSpeed, glowIntensity: glowIntensity)
            appDelegate.updateCornerVisibility(
                topLeft: tempTopLeftEnabled,
                topRight: tempTopRightEnabled,
                bottomLeft: tempBottomLeftEnabled,
                bottomRight: tempBottomRightEnabled
            )
        }
        
        // アプリを再起動して設定を反映
        restartApplication()
        
        hasUnsavedChanges = false
    }
    
    private func restartApplication() {
        // アプリのバンドルパスを取得
        let bundlePath = Bundle.main.bundlePath
        
        // NSTaskを使用して新しいインスタンスとして再起動
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundlePath] // -n で新しいインスタンスとして開く
        
        // バックグラウンドで実行し、アプリを終了
        DispatchQueue.global().async {
            do {
                try task.run()
                
                // タスクが開始されたらアプリを終了
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                print("Failed to restart application: \(error)")
                
                // フォールバック：シェルスクリプト方式
                self.restartWithShellScript()
            }
        }
    }
    
    private func restartWithShellScript() {
        // フォールバックとしてシェルスクリプト方式を使用
        let bundlePath = Bundle.main.bundlePath
        let shellScript = """
        #!/bin/bash
        sleep 0.5
        open "\(bundlePath)"
        exit 0
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let scriptFile = tempDir.appendingPathComponent("restart_rounder.sh")
        
        do {
            try shellScript.write(to: scriptFile, atomically: true, encoding: .utf8)
            
            // 実行権限を付与
            let chmodProcess = Process()
            chmodProcess.launchPath = "/bin/chmod"
            chmodProcess.arguments = ["+x", scriptFile.path]
            chmodProcess.launch()
            chmodProcess.waitUntilExit()
            
            // シェルスクリプトを実行
            let scriptProcess = Process()
            scriptProcess.launchPath = scriptFile.path
            scriptProcess.arguments = []
            
            DispatchQueue.global().async {
                do {
                    try scriptProcess.run()
                    
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                } catch {
                    print("Shell script restart failed: \(error)")
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            
        } catch {
            print("Failed to create restart script: \(error)")
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    private func resetToSavedValues() {
        tempRadius = cornerRadius
        tempColor = selectedColor
        tempEnabled = isEnabled
        tempTopLeftEnabled = savedTopLeftEnabled
        tempTopRightEnabled = savedTopRightEnabled
        tempBottomLeftEnabled = savedBottomLeftEnabled
        tempBottomRightEnabled = savedBottomRightEnabled
        superGamingMode = savedSuperGamingMode
        gamingSpeed = savedGamingSpeed
        glowIntensity = savedGlowIntensity
        hasUnsavedChanges = false
    }
    
    private func closeSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示に戻す
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.hideSettings()
        }
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
    @Binding var hasUnsavedChanges: Bool
    @Binding var superGamingMode: Bool
    @Binding var gamingSpeed: Double
    @Binding var glowIntensity: Double
    let markAsChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 有効/無効トグル
            VStack(alignment: .leading, spacing: 8) {
                Text("general")
                    .font(.headline)
                
                Toggle("enable_rounded_corners", isOn: $tempEnabled)
                    .onChange(of: tempEnabled) { _, _ in
                        markAsChanged()
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
                                .frame(width: 50)
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
                    
                    Slider(value: $tempRadius, in: 0...40, step: 1)
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
                            .frame(width: 50, height: 30)
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
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: tempColor == color ? 2 : 0)
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
                            .font(.custom(Locale.current.languageCode == "ja" ? "Hiragino Maru Gothic ProN" : "Comic Sans MS", size: 16))
                            .fontWeight(.bold)
                            .applyIf(superGamingMode) { view in
                                view.modifier(RainbowEffect())
                            }
                            .onChange(of: superGamingMode) { _, _ in
                                markAsChanged()
                            }
                        
                        if superGamingMode {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("gaming_speed")
                                        .font(.custom(Locale.current.languageCode == "ja" ? "Hiragino Maru Gothic ProN" : "Comic Sans MS", size: 14))
                                        .foregroundColor(.orange)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        TextField("1.0", value: $gamingSpeed, format: .number.precision(.fractionLength(1)))
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 50)
                                            .multilineTextAlignment(.center)
                                            .font(.custom(Locale.current.languageCode == "ja" ? "Hiragino Maru Gothic ProN" : "Comic Sans MS", size: 12))
                                            .onChange(of: gamingSpeed) { _, newValue in
                                                let clampedValue = max(0.1, min(5.0, newValue))
                                                if clampedValue != newValue {
                                                    gamingSpeed = clampedValue
                                                } else {
                                                    markAsChanged()
                                                }
                                            }
                                        
                                        Text("x")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                
                                Slider(value: $gamingSpeed, in: 0.1...5.0, step: 0.1)
                                    .accentColor(.orange)
                                    .onChange(of: gamingSpeed) { _, _ in
                                        markAsChanged()
                                    }
                                
                                // 範囲のヒント
                                HStack {
                                    Text("0.1x")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("5.0x")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, -4)
                                
                                // 発光強度設定
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("glow_intensity")
                                            .font(.custom(Locale.current.languageCode == "ja" ? "Hiragino Maru Gothic ProN" : "Comic Sans MS", size: 14))
                                            .foregroundColor(.cyan)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            TextField("1.0", value: $glowIntensity, format: .number.precision(.fractionLength(1)))
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 50)
                                                .multilineTextAlignment(.center)
                                                .font(.custom(Locale.current.languageCode == "ja" ? "Hiragino Maru Gothic ProN" : "Comic Sans MS", size: 12))
                                                .onChange(of: glowIntensity) { _, newValue in
                                                    let clampedValue = max(0.1, min(3.0, newValue))
                                                    if clampedValue != newValue {
                                                        glowIntensity = clampedValue
                                                    } else {
                                                        markAsChanged()
                                                    }
                                                }
                                            
                                            Text("x")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Slider(value: $glowIntensity, in: 0.1...3.0, step: 0.1)
                                        .accentColor(.cyan)
                                        .onChange(of: glowIntensity) { _, _ in
                                            markAsChanged()
                                        }
                                    
                                    // 範囲のヒント
                                    HStack {
                                        Text("0.1x")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("3.0x")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, -4)
                                }
                            }
                            .padding(.leading, 16)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: superGamingMode)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct PermissionsTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("permission_management")
                .font(.headline)
            
            VStack(spacing: 16) {
                PermissionStatusRow(
                    title: "アクセシビリティ権限",
                    description: "画面の角を検出してオーバーレイを表示",
                    icon: "accessibility",
                    status: .granted
                )
                
                PermissionStatusRow(
                    title: "画面録画権限",
                    description: "スクリーンセーバーレベルでの表示",
                    icon: "display",
                    status: .granted
                )
                
                PermissionStatusRow(
                    title: "自動化権限",
                    description: "システムイベントの監視",
                    icon: "gear.badge",
                    status: .pending
                )
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("reset_permissions")
                    .font(.headline)
                
                Text("permission_regrant_instructions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(String(localized: "open_system_preferences")) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
}

struct PermissionStatusRow: View {
    let title: String
    let description: String
    let icon: String
    let status: PermissionStatus
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch status {
        case .granted:
            return .green
        case .pending:
            return .orange
        case .denied:
            return .red
        }
    }
    
    private var statusText: String {
        switch status {
        case .granted:
            return "許可済み"
        case .pending:
            return "要確認"
        case .denied:
            return "拒否"
        }
    }
}

enum PermissionStatus {
    case granted
    case pending
    case denied
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
                        "Nisesimadao - 開発者",
                        "SwiftUI & AppKit 実装"
                    ]
                )
                
                CreditSection(
                    title: "技術",
                    items: [
                        "Core Graphics 描画エンジン",
                        "NSWindow オーバーレイシステム",
                        "UserDefaults 設定管理"
                    ]
                )
                
                CreditSection(
                    title: String(localized: "license"),
                    items: [
                        "MIT License",
                        "オープンソースプロジェクト"
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
                            .frame(width: 4, height: 4)
                        
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
