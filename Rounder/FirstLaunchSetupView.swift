//
//  FirstLaunchSetupView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI

// MARK: - Constants
struct FirstLaunchSetupConstants {
    static let iconSize = CGFloat(40)
    static let headerPadding = CGFloat(24)
    static let topPadding = CGFloat(20)
    static let cornerRadiusKey = UserDefaultsKeys.cornerRadius
    static let cornerColorKey = UserDefaultsKeys.cornerColor
    static let totalTabs = 3.0
    static let horizontalPadding = CGFloat(24)
    static let windowWidth = CGFloat(600)
    static let windowHeight = CGFloat(500)
    static let spacingValue = CGFloat(16)
    static let spacingValueSmall = CGFloat(4)
    static let buttonSpacing = CGFloat(12)
    static let iconFrameWidth = CGFloat(32)
    static let iconFontSize = CGFloat(24)
    static let titleFontSize = CGFloat(20)
    static let permissionIconSize = CGFloat(40)
    static let buttonWidth = CGFloat(50)
    static let buttonHeight = CGFloat(30)
    static let checkmarkSize = CGFloat(24)
}

struct FirstLaunchSetupView: View {
    @State private var selectedTab: Int = 0
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
                        .frame(width: FirstLaunchSetupConstants.iconSize, height: FirstLaunchSetupConstants.iconSize)
                    
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
                .padding(.horizontal, FirstLaunchSetupConstants.headerPadding)
                .padding(.top, FirstLaunchSetupConstants.topPadding)
                
                // プログレスバー
                ProgressView(value: Double(selectedTab + 1), total: FirstLaunchSetupConstants.totalTabs)
                    .tint(.blue)
                    .padding(.horizontal, FirstLaunchSetupConstants.horizontalPadding)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // タブコンテンツ
            TabView(selection: $selectedTab) {
                // タブ1: ようこそ
                WelcomeStepView()
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
        .frame(width: FirstLaunchSetupConstants.windowWidth, height: FirstLaunchSetupConstants.windowHeight)
    }

    private func completeSetup() {
        // 再起動せずに、そのままメニューバー常駐モードへ移行する
        if let appDelegate = AppDelegate.shared {
            appDelegate.completeFirstLaunchSetup()
        } else {
            // フォールバック：フラグだけ立てて終了
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasLaunchedBefore)
            NSApplication.shared.terminate(nil)
        }
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("ICON")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)

            VStack(spacing: 8) {
                Text("welcome_to_rounder")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("app_utility_description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(alignment: .leading, spacing: 14) {
                WelcomeFeatureRow(icon: "rectangle.roundedbottom", titleKey: "screen_corner_rounding")
                WelcomeFeatureRow(icon: "slider.horizontal.3", titleKey: "customizable_radius_color")
                WelcomeFeatureRow(icon: "menubar.rectangle", titleKey: "run_in_background")
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

struct WelcomeFeatureRow: View {
    let icon: String
    let titleKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 26)
            Text(titleKey)
                .font(.body)
            Spacer()
        }
    }
}

struct InitialSettingsView: View {
    @AppStorage(FirstLaunchSetupConstants.cornerRadiusKey) private var cornerRadius: Double = RounderAppConstants.defaultCornerRadius
    @AppStorage(FirstLaunchSetupConstants.cornerColorKey) private var cornerColorData: Data = Data()
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
                        Slider(value: $cornerRadius, in: RounderAppConstants.cornerRadiusMin...RounderAppConstants.cornerRadiusMax, step: RounderAppConstants.cornerRadiusStep)
                        Text("\(Int(cornerRadius))px")
                            .frame(width: FirstLaunchSetupConstants.permissionIconSize)
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
                            .frame(width: FirstLaunchSetupConstants.buttonWidth, height: FirstLaunchSetupConstants.buttonHeight)
                        
                        ForEach([Color.black, Color.white, Color.gray], id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: FirstLaunchSetupConstants.checkmarkSize, height: FirstLaunchSetupConstants.checkmarkSize)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor.matchesSwatch(color) ? 2 : 0)
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
    @State private var launchAtLogin: Bool = true
    @State private var didApplyDefault = false

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
                    Toggle("launch_at_login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            launchAtLogin = LoginItemManager.setEnabled(newValue)
                        }

                    Text("background_operation_description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            // 完了ステップに来たら「開始」ボタンを有効化する
            setupComplete = true
            // 既定でログイン起動を登録するのは初回のみ。戻る/進むで再表示されたときに
            // ユーザーの解除を上書きしないようにする。
            if !didApplyDefault {
                didApplyDefault = true
                launchAtLogin = LoginItemManager.setEnabled(true)
            }
        }
    }
}

#Preview {
    FirstLaunchSetupView()
}
