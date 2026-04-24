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
    @State private var selectedColor: Color = .black
    @State private var isEnabled: Bool = true
    @State private var hasUnsavedChanges: Bool = false
    @State private var selectedTab: Int = 0
    
    // 一時的な設定値
    @State private var tempRadius: Double = 20.0
    @State private var tempColor: Color = .black
    @State private var tempEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Image("ICON")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text("Rounder 設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("バージョン 1.0.0")
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
                    hasUnsavedChanges: $hasUnsavedChanges,
                    markAsChanged: markAsChanged
                )
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(0)
                
                // 権限タブ
                PermissionsTabView()
                .tabItem {
                    Label("権限", systemImage: "lock.shield")
                }
                .tag(1)
                
                // クレジットタブ
                CreditsTabView()
                .tabItem {
                    Label("クレジット", systemImage: "info.circle")
                }
                .tag(2)
            }
            .padding()
            
            // フッターボタン
            HStack(spacing: 12) {
                Button("キャンセル") {
                    resetToSavedValues()
                    closeSettings()
                }
                .keyboardShortcut(.escape)
                
                Button("適用") {
                    applySettings()
                }
                .disabled(!hasUnsavedChanges)
                .keyboardShortcut(.return, modifiers: .command)
                
                Button("OK") {
                    applySettings()
                    closeSettings()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("終了") {
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
    }
    
    // MARK: - 設定管理
    private func markAsChanged() {
        hasUnsavedChanges = true
    }
    
    private func applySettings() {
        // 一時的な値を保存
        cornerRadius = tempRadius
        selectedColor = tempColor
        isEnabled = tempEnabled
        
        // 色を保存
        let nsColor = NSColor(selectedColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
        }
        
        // アプリを再起動して設定を反映
        restartApplication()
        
        hasUnsavedChanges = false
    }
    
    private func restartApplication() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        task.launch()
        
        NSApplication.shared.terminate(nil)
    }
    
    private func resetToSavedValues() {
        tempRadius = cornerRadius
        tempColor = selectedColor
        tempEnabled = isEnabled
        hasUnsavedChanges = false
    }
    
    private func closeSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示に戻す
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.hideSettings()
        }
    }
    
    // MARK: - オーバーレイ操作
    private func updateOverlaySettings() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        
        let nsColor = NSColor(selectedColor)
        appDelegate.updateOverlaySettings(radius: CGFloat(cornerRadius), color: nsColor)
    }
    
    private func updateOverlaySettingsWithTempValues() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        
        let nsColor = NSColor(tempColor)
        appDelegate.updateOverlaySettings(radius: CGFloat(tempRadius), color: nsColor)
    }
    
    private func updateOverlayVisibility() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        
        for window in appDelegate.overlayWindows {
            window.orderOut(nil)
        }
        
        if tempEnabled {
            for window in appDelegate.overlayWindows {
                window.orderFront(nil)
            }
        }
    }
    
    private func saveColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
        }
    }
    
    private func loadSavedColor() {
        guard !cornerColorData.isEmpty,
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: cornerColorData) else {
            return
        }
        
        selectedColor = Color(nsColor)
    }
}

// MARK: - タブビューコンポーネント

struct SettingsTabView: View {
    @Binding var tempRadius: Double
    @Binding var tempColor: Color
    @Binding var tempEnabled: Bool
    @Binding var hasUnsavedChanges: Bool
    let markAsChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 有効/無効トグル
            VStack(alignment: .leading, spacing: 8) {
                Text("一般")
                    .font(.headline)
                
                Toggle("角丸を有効にする", isOn: $tempEnabled)
                    .onChange(of: tempEnabled) { _, _ in
                        markAsChanged()
                    }
            }
            
            // 角の半径設定
            VStack(alignment: .leading, spacing: 12) {
                Text("外観")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("角の半径")
                        Spacer()
                        Text("\(Int(tempRadius))px")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Slider(value: $tempRadius, in: 0...40, step: 1)
                        .onChange(of: tempRadius) { _, _ in
                            markAsChanged()
                        }
                }
                
                // 色選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("角の色")
                    
                    HStack(spacing: 15) {
                        ColorPicker("カスタム色", selection: $tempColor)
                            .labelsHidden()
                            .frame(width: 50, height: 30)
                            .onChange(of: tempColor) { _, _ in
                                markAsChanged()
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("クイック選択")
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
            
            Spacer()
        }
    }
}

struct PermissionsTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("権限管理")
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
                Text("権限の再設定")
                    .font(.headline)
                
                Text("権限に問題がある場合、システム環境設定から再度許可することができます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("システム環境設定を開く") {
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
            Text("クレジット")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                CreditSection(
                    title: "開発",
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
                    title: "ライセンス",
                    items: [
                        "MIT License",
                        "オープンソースプロジェクト"
                    ]
                )
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("サポート")
                    .font(.headline)
                
                Text("問題報告や機能要望はGitHubで受け付けています。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("GitHubを開く") {
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
