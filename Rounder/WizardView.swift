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
                Text("Rounder セットアップ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button("閉じる") {
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
                
                Text("Rounderへようこそ")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Macの画面コーナーを美しい角丸に変換するユーティリティです。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("主な機能:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("画面コーナーの角丸化")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("カスタマイズ可能な半径と色")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("バックグラウンドで動作")
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
                
                Text("権限の要求")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Rounderが正常に動作するために、以下の権限が必要です:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("必要な権限:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "display")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("画面アクセス")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("オーバーレイを表示して画面コーナーを角丸にします")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("自動起動")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("ログイン時に自動的に起動します")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Text("これらの権限はRounderの動作にのみ使用され、他の目的では使用されません。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var settingsPage: some View {
        VStack(spacing: 20) {
            Text("基本設定")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 20) {
                // 有効/無効トグル
                VStack(alignment: .leading, spacing: 8) {
                    Text("一般")
                        .font(.headline)
                    
                    Toggle("角丸を有効にする", isOn: $isEnabled)
                }
                
                // 角の半径設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("外観")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("角の半径")
                            Spacer()
                            Text("\(Int(cornerRadius))px")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        Slider(value: $cornerRadius, in: 0...40, step: 1)
                    }
                    
                    // 色選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("角の色")
                        
                        HStack(spacing: 15) {
                            ColorPicker("カスタム色", selection: $selectedColor)
                                .labelsHidden()
                                .frame(width: 50, height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("クイック選択")
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
