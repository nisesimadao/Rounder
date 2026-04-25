//
//  WizardView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI

struct WizardView: View {
    @State private var currentPage = 0
    @State private var cornerRadius: Double = 20.0
    @State private var selectedColor: Color = .black
    @State private var isEnabled: Bool = true
    
    private let totalPages = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("rounder_setup_title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(String(localized: "close_button")) {
                    closeWizard()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            
            Divider()
            
            // プログレスバー
            ProgressView(value: Double(currentPage + 1), total: Double(totalPages))
                .padding(.horizontal)
            
            // コンテンツ
            TabView(selection: $currentPage) {
                // ページ1: ウェルカム
                welcomePage
                    .tag(0)
                
                // ページ2: 権限要求
                permissionsPage
                    .tag(1)
                
                // ページ3: 設定
                settingsPage
                    .tag(2)
            }
                        
            // フッター（ナビゲーションボタン）
            HStack {
                if currentPage > 0 {
                    Button("戻る") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentPage < totalPages - 1 {
                    Button("次へ") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("完了") {
                        completeWizard()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "rectangle.roundedbottom.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("welcome_to_rounder")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("app_utility_description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("main_features")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("screen_corner_rounding")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("customizable_radius_color")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("run_in_background")
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var permissionsPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("permission_request")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("permissions_required_message")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("required_permissions")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "display")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("display_access")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("overlay_description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("auto_start")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("auto_start_description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Text("permissions_usage_only")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var settingsPage: some View {
        VStack(spacing: 20) {
            Text("basic_settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 20) {
                // 有効/無効トグル
                VStack(alignment: .leading, spacing: 8) {
                    Text("general")
                        .font(.headline)
                    
                    Toggle(String(localized: "enable_rounded_corners"), isOn: $isEnabled)
                }
                
                // 角の半径設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("appearance")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("corner_radius")
                            Spacer()
                            Text("\(Int(cornerRadius))px")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        Slider(value: $cornerRadius, in: 0...40, step: 1)
                    }
                    
                    // 色選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("corner_color")
                        
                        HStack(spacing: 15) {
                            ColorPicker(String(localized: "custom_color"), selection: $selectedColor)
                                .labelsHidden()
                                .frame(width: 50, height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("quick_select")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
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
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func closeWizard() {
        if let window = NSApp.keyWindow {
            window.close()
        }
        // バックグラウンドモードに切り替え
        NSApp.setActivationPolicy(.accessory)
        // 通常の起動処理
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.createOverlayWindows()
            appDelegate.setupMenuBar()
            appDelegate.setupSettingsWindow()
        }
    }
    
    private func completeWizard() {
        // 設定を保存
        UserDefaults.standard.set(cornerRadius, forKey: "cornerRadius")
        let nsColor = NSColor(selectedColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "cornerColor")
        }
        UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
        
        closeWizard()
    }
}

#Preview {
    WizardView()
}
