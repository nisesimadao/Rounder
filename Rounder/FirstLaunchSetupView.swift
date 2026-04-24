//
//  FirstLaunchSetupView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI

struct FirstLaunchSetupView: View {
    @State private var selectedTab: Int = 0
    @State private var accessibilityGranted: Bool = false
    @State private var screenGranted: Bool = false
    @State private var automationGranted: Bool = false
    @State private var setupComplete: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            VStack(spacing: 16) {
                HStack {
                    Image("ICON")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rounderへようこそ")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("macOSの画面コーナーを美しく角丸化")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // プログレスバー
                ProgressView(value: Double(selectedTab + 1), total: 3.0)
                    .tint(.blue)
                    .padding(.horizontal, 24)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // タブコンテンツ
            TabView(selection: $selectedTab) {
                // タブ1: 権限設定
                PermissionsSetupView(
                    accessibilityGranted: $accessibilityGranted,
                    screenGranted: $screenGranted,
                    automationGranted: $automationGranted
                )
                    .tag(0)
                
                // タブ2: 初期設定
                InitialSettingsView()
                    .tag(1)
                
                // タブ3: 完了
                SetupCompleteView(setupComplete: $setupComplete)
                    .tag(2)
            }
                        
            // フッターボタン
            HStack(spacing: 12) {
                if selectedTab > 0 {
                    Button("戻る") {
                        selectedTab -= 1
                    }
                    .keyboardShortcut(.leftArrow)
                }
                
                Spacer()
                
                if selectedTab < 2 {
                    Button("次へ") {
                        selectedTab += 1
                    }
                    .keyboardShortcut(.rightArrow)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTab == 0 && !allPermissionsGranted())
                } else {
                    Button("Rounderを開始") {
                        completeSetup()
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(!setupComplete)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
    }
    
    private func allPermissionsGranted() -> Bool {
        return accessibilityGranted && screenGranted && automationGranted
    }
    
    private func completeSetup() {
        // 初回起動完了フラグを設定
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        
        // アプリを再起動して通常モードへ
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        task.launch()
        
        NSApplication.shared.terminate(nil)
    }
}

struct PermissionsSetupView: View {
    @Binding var accessibilityGranted: Bool
    @Binding var screenGranted: Bool
    @Binding var automationGranted: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("必要な権限")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(spacing: 16) {
                PermissionRow(
                    title: "アクセシビリティ権限",
                    description: "画面の角を検出してオーバーレイを表示するために必要です",
                    icon: "accessibility",
                    isGranted: $accessibilityGranted,
                    action: { requestAccessibilityPermission() }
                )
                
                PermissionRow(
                    title: "画面録画権限",
                    description: "スクリーンセーバーレベルでオーバーレイを表示するために必要です",
                    icon: "display",
                    isGranted: $screenGranted,
                    action: { requestScreenPermission() }
                )
                
                PermissionRow(
                    title: "自動化権限",
                    description: "システムイベントを監視して画面変更に対応するために必要です",
                    icon: "gear.badge",
                    isGranted: $automationGranted,
                    action: { requestAutomationPermission() }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func requestAccessibilityPermission() {
        // アクセシビリティ権限を要求
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        accessibilityGranted = true
    }
    
    private func requestScreenPermission() {
        // 画面録画権限を要求
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        screenGranted = true
    }
    
    private func requestAutomationPermission() {
        // 自動化権限を要求
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
        automationGranted = true
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isGranted ? .green : .blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                Button("許可する") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InitialSettingsView: View {
    @AppStorage("cornerRadius") private var cornerRadius: Double = 20.0
    @AppStorage("cornerColor") private var cornerColorData: Data = Data()
    @State private var selectedColor: Color = .black
    
    var body: some View {
        VStack(spacing: 24) {
            Text("初期設定")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 20) {
                // 角の半径設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("角の半径")
                        .font(.headline)
                    
                    HStack {
                        Slider(value: $cornerRadius, in: 0...40, step: 1)
                        Text("\(Int(cornerRadius))px")
                            .frame(width: 40)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 色選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("角の色")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ColorPicker("カスタム色", selection: $selectedColor)
                            .labelsHidden()
                            .frame(width: 50, height: 30)
                        
                        ForEach([Color.black, Color.white, Color.gray], id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 説明
                VStack(alignment: .leading, spacing: 8) {
                    Text("設定について")
                        .font(.headline)
                    
                    Text("これらの設定は後からいつでも変更できます。メニューバーのRounderアイコンから設定画面を開いてください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            loadSavedColor()
            saveColor()
        }
        .onChange(of: selectedColor) { _, _ in
            saveColor()
        }
    }
    
    private func loadSavedColor() {
        guard !cornerColorData.isEmpty,
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: cornerColorData) else {
            return
        }
        selectedColor = Color(nsColor)
    }
    
    private func saveColor() {
        let nsColor = NSColor(selectedColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            cornerColorData = data
        }
    }
}

struct SetupCompleteView: View {
    @Binding var setupComplete: Bool
    @State private var isChecked: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("セットアップ完了")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 12) {
                    Text("準備が完了しました！")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Rounderは画面の角に美しい角丸オーバーレイを表示します。")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("セットアップを完了してRounderを開始", isOn: $isChecked)
                        .onChange(of: isChecked) { _, _ in
                            setupComplete = isChecked
                        }
                    
                    Text("チェックを入れると、Rounderがバックグラウンドで起動し、メニューバーにアイコンが表示されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    FirstLaunchSetupView()
}
