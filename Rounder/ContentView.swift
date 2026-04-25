//
//  ContentView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("cornerRadius") private var cornerRadius: Double = 20.0
    @AppStorage("cornerColor") private var cornerColorData: Data = Data()
    @AppStorage("isEnabled") private var isEnabled: Bool = true
    @AppStorage("rainbowMode") private var rainbowMode: Bool = false
    @State private var selectedColor: Color = .black
    @State private var hasUnsavedChanges: Bool = false
    @State private var selectedTab: Int = 0
    
    // 一時的な設定値
    @State private var tempRadius: Double = 20.0
    @State private var tempColor: Color = .black
    @State private var tempEnabled: Bool = true
    @State private var tempRainbowMode: Bool = false
    
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
                    tempRainbowMode: $tempRainbowMode,
                    hasUnsavedChanges: $hasUnsavedChanges,
                    markAsChanged: markAsChanged
                )
                .tabItem {
                    Label("settings_tab", systemImage: "gearshape")
                }
                .tag(0)
                
                // 権限タブ
                PermissionsTabView()
                .tabItem {
                    Label("permissions_tab", systemImage: "lock.shield")
                }
                .tag(1)
                
                // クレジットタブ
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
        .frame(width: 600, height: 600)
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
        .onChange(of: rainbowMode) { _, newValue in
            tempRainbowMode = newValue
        }
    }
    
    // MARK: - 設定管理
    private func markAsChanged() {
        // 現在の一時値と保存値を比較
        let radiusChanged = tempRadius != cornerRadius
        let colorChanged = !colorsEqual(tempColor, selectedColor)
        let enabledChanged = tempEnabled != isEnabled
        let rainbowModeChanged = tempRainbowMode != rainbowMode
        
        hasUnsavedChanges = radiusChanged || colorChanged || enabledChanged || rainbowModeChanged
    }
    
    private func colorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let nsColor1 = NSColor(color1)
        let nsColor2 = NSColor(color2)
        return nsColor1.isEqual(nsColor2)
    }
    
    private func applySettings() {
        print("Applying settings...")
        
        // @AppStorageを直接更新
        cornerRadius = tempRadius
        isEnabled = tempEnabled
        rainbowMode = tempRainbowMode
        
        // 色を保存（レインボーモードがオンの場合は保存しない）
        if !tempRainbowMode {
            let nsColor = NSColor(tempColor)
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
                cornerColorData = data
            }
        }
        
        // レインボーモードの即時適用（エラーが発生しても続行）
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            print("Updating rainbow mode...")
            appDelegate.updateRainbowMode(tempRainbowMode)
        } else {
            print("Warning: Could not get AppDelegate for rainbow mode update")
        }
        
        // アプリを再起動して設定を反映
        print("Starting restart process...")
        restartApplication()
        
        hasUnsavedChanges = false
    }
    
    private func restartApplication() {
        // アプリのバンドルパスを取得
        let bundlePath = Bundle.main.bundlePath
        print("Bundle path: \(bundlePath)")
        
        // NSTaskを使用して新しいインスタンスとして再起動
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundlePath] // -n で新しいインスタンスとして開く
        
        print("Starting restart task...")
        
        // バックグラウンドで実行し、アプリを終了
        DispatchQueue.global().async {
            do {
                print("Executing restart task...")
                try task.run()
                print("Task executed successfully")
                
                // タスクが開始されたらアプリを終了
                DispatchQueue.main.async {
                    print("Terminating application...")
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                print("Failed to restart application: \(error)")
                
                // フォールバック：シェルスクリプト方式
                print("Trying fallback method...")
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
        tempRainbowMode = rainbowMode
        hasUnsavedChanges = false
    }
    
    private func closeSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示に戻す
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.hideSettings()
        }
    }
    
    // MARK: - オーバーレイ操作
    private func updateOverlaySettingsWithTempValues() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        
        let nsColor = NSColor(tempColor)
        appDelegate.updateOverlaySettings(radius: CGFloat(tempRadius), color: nsColor)
    }
    
    private func saveColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
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
    @Binding var tempRainbowMode: Bool
    @Binding var hasUnsavedChanges: Bool
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
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("corner_radius")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("半径", value: $tempRadius, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                                .onSubmit {
                                    // Enterキーで入力確定時に範囲チェック
                                    if tempRadius < 0 {
                                        tempRadius = 0
                                    } else if tempRadius > 40 {
                                        tempRadius = 40
                                    }
                                    markAsChanged()
                                }
                                .onChange(of: tempRadius) { _, _ in
                                    // 値の範囲を制限
                                    if tempRadius < 0 {
                                        tempRadius = 0
                                    } else if tempRadius > 40 {
                                        tempRadius = 40
                                    }
                                    markAsChanged()
                                }
                            
                            Text("px")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Slider(value: $tempRadius, in: 0...40, step: 1)
                        .onChange(of: tempRadius) { _, _ in
                            markAsChanged()
                        }
                }
                
                // 色選択
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("corner_color")
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // レインボーモードトグル
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(String(localized: "rainbow_mode"), isOn: $tempRainbowMode)
                                .onChange(of: tempRainbowMode) { _, _ in
                                    markAsChanged()
                                }
                            
                            if tempRainbowMode {
                                Text(String(localized: "rainbow_mode_description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 通常の色選択（レインボーモードがオフの場合のみ表示）
                        if !tempRainbowMode {
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
