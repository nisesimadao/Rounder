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
            VStack(spacing: 16) {
                HStack {
                    Image("ICON")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("welcome_to_rounder")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("app_description")
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
                    Button("back") {
                        selectedTab -= 1
                    }
                    .keyboardShortcut(.leftArrow)
                }
                
                Spacer()
                
                if selectedTab < 2 {
                    Button("next") {
                        selectedTab += 1
                    }
                    .keyboardShortcut(.rightArrow)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTab == 0 && !allPermissionsGranted())
                } else {
                    Button("start_rounder") {
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
            Text("required_permissions")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(spacing: 16) {
                PermissionRow(
                    title: "accessibility_permission",
                    description: "accessibility_description",
                    icon: "accessibility",
                    isGranted: $accessibilityGranted,
                    action: { requestAccessibilityPermission() }
                )
                
                PermissionRow(
                    title: "screen_permission",
                    description: "screen_description",
                    icon: "display",
                    isGranted: $screenGranted,
                    action: { requestScreenPermission() }
                )
                
                PermissionRow(
                    title: "automation_permission",
                    description: "automation_description",
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
            Text("basic_settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 20) {
                // 角の半径設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("corner_radius")
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
                    Text("corner_color")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ColorPicker(String(localized: "custom_color"), selection: $selectedColor)
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
                    Text("about_settings")
                        .font(.headline)
                    
                    Text("settings_change_instructions")
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
            Text("setup_complete")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 12) {
                    Text("setup_complete_message")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("rounder_description")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(String(localized: "complete_setup_start_rounder"), isOn: $isChecked)
                        .onChange(of: isChecked) { _, _ in
                            setupComplete = isChecked
                        }
                    
                    Text("background_operation_description")
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
