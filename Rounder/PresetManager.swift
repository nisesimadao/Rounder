//
//  PresetManager.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Foundation
import SwiftUI
import Cocoa
import Combine
import UniformTypeIdentifiers

// MARK: - Constants
struct PresetManagerConstants {
    static let defaultCornerRadius: Double = 20.0
    static let defaultGamingSpeed: Double = 1.0
    static let defaultGlowIntensity: Double = 1.0
    static let defaultBloomWidth: Double = 1.0
    static let defaultCornerCutoutStyle: CornerCutoutStyle = .rounded
    static let presetsKey = "cornerPresets"
}

// プリセットデータ構造
struct CornerPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var topLeftEnabled: Bool
    var topRightEnabled: Bool
    var bottomLeftEnabled: Bool
    var bottomRightEnabled: Bool
    var cornerRadius: Double
    var cornerColor: Data  // NSColorをエンコードしたData
    var superGamingMode: Bool
    var gamingSpeed: Double
    var glowIntensity: Double
    var bloomWidth: Double
    var cornerCutoutStyle: CornerCutoutStyle
    var pinToScreen: Bool
    var pinToDesktop: Bool
    var excludeMenuBar: Bool
    var blackMenuBar: Bool
    
    init(name: String,
         topLeftEnabled: Bool = true,
         topRightEnabled: Bool = true,
         bottomLeftEnabled: Bool = true,
         bottomRightEnabled: Bool = true,
         cornerRadius: Double = PresetManagerConstants.defaultCornerRadius,
         cornerColor: NSColor = .black,
         superGamingMode: Bool = false,
         gamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed,
         glowIntensity: Double = PresetManagerConstants.defaultGlowIntensity,
         bloomWidth: Double = PresetManagerConstants.defaultBloomWidth,
         cornerCutoutStyle: CornerCutoutStyle = PresetManagerConstants.defaultCornerCutoutStyle,
         pinToScreen: Bool = true,
         pinToDesktop: Bool = false,
         excludeMenuBar: Bool = false,
         blackMenuBar: Bool = false,
         id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.topLeftEnabled = topLeftEnabled
        self.topRightEnabled = topRightEnabled
        self.bottomLeftEnabled = bottomLeftEnabled
        self.bottomRightEnabled = bottomRightEnabled
        self.cornerRadius = cornerRadius
        
        do {
            self.cornerColor = try NSKeyedArchiver.archivedData(withRootObject: cornerColor, requiringSecureCoding: true)
        } catch {
            print("Failed to archive corner color: \(error)")
            self.cornerColor = Data()
        }
        
        self.superGamingMode = superGamingMode
        self.gamingSpeed = gamingSpeed
        self.glowIntensity = glowIntensity
        self.bloomWidth = bloomWidth
        self.cornerCutoutStyle = cornerCutoutStyle
        self.pinToScreen = pinToScreen
        self.pinToDesktop = pinToDesktop
        self.excludeMenuBar = excludeMenuBar
        self.blackMenuBar = blackMenuBar
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case topLeftEnabled
        case topRightEnabled
        case bottomLeftEnabled
        case bottomRightEnabled
        case cornerRadius
        case cornerColor
        case superGamingMode
        case gamingSpeed
        case glowIntensity
        case bloomWidth
        case cornerCutoutStyle
        case pinToScreen, pinToDesktop, excludeMenuBar, blackMenuBar
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        topLeftEnabled = try container.decode(Bool.self, forKey: .topLeftEnabled)
        topRightEnabled = try container.decode(Bool.self, forKey: .topRightEnabled)
        bottomLeftEnabled = try container.decode(Bool.self, forKey: .bottomLeftEnabled)
        bottomRightEnabled = try container.decode(Bool.self, forKey: .bottomRightEnabled)
        cornerRadius = try container.decode(Double.self, forKey: .cornerRadius)
        cornerColor = try container.decode(Data.self, forKey: .cornerColor)
        superGamingMode = try container.decode(Bool.self, forKey: .superGamingMode)
        gamingSpeed = try container.decode(Double.self, forKey: .gamingSpeed)
        glowIntensity = try container.decode(Double.self, forKey: .glowIntensity)
        bloomWidth = try container.decodeIfPresent(Double.self, forKey: .bloomWidth) ?? PresetManagerConstants.defaultBloomWidth
        cornerCutoutStyle = try container.decodeIfPresent(CornerCutoutStyle.self, forKey: .cornerCutoutStyle) ?? .rounded
        pinToScreen = try container.decodeIfPresent(Bool.self, forKey: .pinToScreen) ?? true
        pinToDesktop = try container.decodeIfPresent(Bool.self, forKey: .pinToDesktop) ?? false
        excludeMenuBar = try container.decodeIfPresent(Bool.self, forKey: .excludeMenuBar) ?? false
        blackMenuBar = try container.decodeIfPresent(Bool.self, forKey: .blackMenuBar) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(topLeftEnabled, forKey: .topLeftEnabled)
        try container.encode(topRightEnabled, forKey: .topRightEnabled)
        try container.encode(bottomLeftEnabled, forKey: .bottomLeftEnabled)
        try container.encode(bottomRightEnabled, forKey: .bottomRightEnabled)
        try container.encode(cornerRadius, forKey: .cornerRadius)
        try container.encode(cornerColor, forKey: .cornerColor)
        try container.encode(superGamingMode, forKey: .superGamingMode)
        try container.encode(gamingSpeed, forKey: .gamingSpeed)
        try container.encode(glowIntensity, forKey: .glowIntensity)
        try container.encode(bloomWidth, forKey: .bloomWidth)
        try container.encode(cornerCutoutStyle, forKey: .cornerCutoutStyle)
        try container.encode(pinToScreen, forKey: .pinToScreen)
        try container.encode(pinToDesktop, forKey: .pinToDesktop)
        try container.encode(excludeMenuBar, forKey: .excludeMenuBar)
        try container.encode(blackMenuBar, forKey: .blackMenuBar)
    }
    
    // 色をNSColorとして取得
    var cornerNSColor: NSColor {
        guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: cornerColor) else {
            return .black
        }
        return color
    }
    
    // 色をSwiftUIのColorとして取得
    var cornerSwiftUIColor: Color {
        return Color(cornerNSColor)
    }
}

// プリセット管理クラス
class PresetManager: ObservableObject {
    @Published var presets: [CornerPreset] = []
    
    private let presetsKey = PresetManagerConstants.presetsKey
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPresets()
        installBuiltInPresetsIfNeeded()
    }

    private func installBuiltInPresetsIfNeeded() {
        let versionKey = "builtInPresetsVersion"
        guard defaults.integer(forKey: versionKey) < 1 else { return }
        let legacyIDs = BuiltInPresets.unchangedLegacyIDs(in: presets)
        presets.removeAll { legacyIDs.contains($0.id) }
        let builtIns = BuiltInPresets.makePresets()
        let existingIDs = Set(presets.map(\.id))
        presets.insert(contentsOf: builtIns.filter { !existingIDs.contains($0.id) }, at: 0)
        savePresets()
        defaults.set(1, forKey: versionKey)
    }

    // プリセットの読み込み
    func loadPresets() {
        if let data = defaults.data(forKey: presetsKey),
           let decodedPresets = try? JSONDecoder().decode([CornerPreset].self, from: data) {
            presets = decodedPresets
        }
    }
    
    // プリセットの保存
    func savePresets() {
        if let encodedData = try? JSONEncoder().encode(presets) {
            defaults.set(encodedData, forKey: presetsKey)
        }
    }
    
    // プリセットの追加
    func addPreset(_ preset: CornerPreset) {
        presets.append(preset)
        savePresets()
    }
    
    // プリセットの削除
    func deletePreset(_ preset: CornerPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
    
    // プリセットの更新
    func updatePreset(_ preset: CornerPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
        }
    }
    
    // プリセットの適用
    func applyPreset(_ preset: CornerPreset) {
        defaults.set(preset.topLeftEnabled, forKey: UserDefaultsKeys.topLeftEnabled)
        defaults.set(preset.topRightEnabled, forKey: UserDefaultsKeys.topRightEnabled)
        defaults.set(preset.bottomLeftEnabled, forKey: UserDefaultsKeys.bottomLeftEnabled)
        defaults.set(preset.bottomRightEnabled, forKey: UserDefaultsKeys.bottomRightEnabled)
        defaults.set(preset.cornerRadius, forKey: UserDefaultsKeys.cornerRadius)
        defaults.set(preset.cornerColor, forKey: UserDefaultsKeys.cornerColor)
        defaults.set(preset.superGamingMode, forKey: UserDefaultsKeys.superGamingMode)
        defaults.set(preset.gamingSpeed, forKey: UserDefaultsKeys.gamingSpeed)
        defaults.set(preset.glowIntensity, forKey: UserDefaultsKeys.glowIntensity)
        defaults.set(preset.bloomWidth, forKey: UserDefaultsKeys.bloomWidth)
        defaults.set(preset.cornerCutoutStyle.rawValue, forKey: UserDefaultsKeys.cornerCutoutStyle)
        defaults.set(preset.pinToScreen, forKey: UserDefaultsKeys.pinToScreen)
        defaults.set(preset.pinToDesktop, forKey: UserDefaultsKeys.pinToDesktop)
        defaults.set(preset.excludeMenuBar, forKey: UserDefaultsKeys.excludeMenuBar)
        defaults.set(preset.blackMenuBar, forKey: UserDefaultsKeys.blackMenuBar)
        
        // AppDelegateに通知して設定を反映
        AppDelegate.shared?.recreateOverlayWindows()
    }
    
    // 現在の設定からプリセットを作成
    func createPresetFromCurrentSettings(name: String) -> CornerPreset {
        let topLeftEnabled = defaults.bool(forKey: UserDefaultsKeys.topLeftEnabled, defaultValue: true)
        let topRightEnabled = defaults.bool(forKey: UserDefaultsKeys.topRightEnabled, defaultValue: true)
        let bottomLeftEnabled = defaults.bool(forKey: UserDefaultsKeys.bottomLeftEnabled, defaultValue: true)
        let bottomRightEnabled = defaults.bool(forKey: UserDefaultsKeys.bottomRightEnabled, defaultValue: true)
        let cornerRadius = defaults.object(forKey: UserDefaultsKeys.cornerRadius) as? Double ?? RounderAppConstants.defaultCornerRadius
        let cornerColorData = defaults.data(forKey: UserDefaultsKeys.cornerColor) ?? Data()
        let superGamingMode = defaults.bool(forKey: UserDefaultsKeys.superGamingMode)
        let gamingSpeed = defaults.object(forKey: UserDefaultsKeys.gamingSpeed) as? Double ?? PresetManagerConstants.defaultGamingSpeed
        let glowIntensity = defaults.object(forKey: UserDefaultsKeys.glowIntensity) as? Double ?? PresetManagerConstants.defaultGlowIntensity
        let bloomWidth = defaults.object(forKey: UserDefaultsKeys.bloomWidth) as? Double ?? PresetManagerConstants.defaultBloomWidth
        let cornerCutoutStyle = CornerCutoutStyle(
            rawValue: defaults.string(forKey: UserDefaultsKeys.cornerCutoutStyle) ?? ""
        ) ?? .rounded
        
        let preset = CornerPreset(
            name: name,
            topLeftEnabled: topLeftEnabled,
            topRightEnabled: topRightEnabled,
            bottomLeftEnabled: bottomLeftEnabled,
            bottomRightEnabled: bottomRightEnabled,
            cornerRadius: cornerRadius,
            cornerColor: NSColor(from: cornerColorData) ?? .black,
            superGamingMode: superGamingMode,
            gamingSpeed: gamingSpeed,
            glowIntensity: glowIntensity,
            bloomWidth: bloomWidth,
            cornerCutoutStyle: cornerCutoutStyle,
            pinToScreen: defaults.bool(forKey: UserDefaultsKeys.pinToScreen, defaultValue: true),
            pinToDesktop: defaults.bool(forKey: UserDefaultsKeys.pinToDesktop),
            excludeMenuBar: defaults.bool(forKey: UserDefaultsKeys.excludeMenuBar),
            blackMenuBar: defaults.bool(forKey: UserDefaultsKeys.blackMenuBar)
        )
        
        return preset
    }
    
    // プリセットのエクスポート
    func exportPresets() -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(presets)
            
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "rounder_presets.json"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try data.write(to: url)
                return url
            }
        } catch {
            print("Failed to export presets: \(error)")
        }
        return nil
    }
    
    // プリセットのインポート
    func importPresets() -> Int {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let data = try Data(contentsOf: url)
                let importedPresets = try JSONDecoder().decode([CornerPreset].self, from: data)
                
                // 重複チェック（名前が同じ場合はスキップ）
                var addedCount = 0
                for preset in importedPresets {
                    if !presets.contains(where: { $0.name == preset.name }) {
                        presets.append(preset)
                        addedCount += 1
                    }
                }
                
                if addedCount > 0 {
                    savePresets()
                }
                
                return addedCount
            } catch {
                print("Failed to import presets: \(error)")
            }
        }
        return 0
    }
}

// NSColorの拡張
extension NSColor {
    convenience init?(from data: Data) {
        guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        self.init(cgColor: color.cgColor)
    }
}
