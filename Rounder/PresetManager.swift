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
    
    init(name: String,
         topLeftEnabled: Bool = true,
         topRightEnabled: Bool = true,
         bottomLeftEnabled: Bool = true,
         bottomRightEnabled: Bool = true,
         cornerRadius: Double = 20.0,
         cornerColor: NSColor = .black,
         superGamingMode: Bool = false,
         gamingSpeed: Double = 1.0,
         glowIntensity: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.topLeftEnabled = topLeftEnabled
        self.topRightEnabled = topRightEnabled
        self.bottomLeftEnabled = bottomLeftEnabled
        self.bottomRightEnabled = bottomRightEnabled
        self.cornerRadius = cornerRadius
        self.cornerColor = try! NSKeyedArchiver.archivedData(withRootObject: cornerColor, requiringSecureCoding: false)
        self.superGamingMode = superGamingMode
        self.gamingSpeed = gamingSpeed
        self.glowIntensity = glowIntensity
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
    
    private let presetsKey = "cornerPresets"
    
    init() {
        loadPresets()
        createDefaultPresetsIfNeeded()
    }
    
    // デフォルトプリセットの作成
    private func createDefaultPresetsIfNeeded() {
        if presets.isEmpty {
            let defaultPresets = [
                CornerPreset(name: "すべての角", topLeftEnabled: true, topRightEnabled: true, bottomLeftEnabled: true, bottomRightEnabled: true),
                CornerPreset(name: "上のみ", topLeftEnabled: true, topRightEnabled: true, bottomLeftEnabled: false, bottomRightEnabled: false),
                CornerPreset(name: "下のみ", topLeftEnabled: false, topRightEnabled: false, bottomLeftEnabled: true, bottomRightEnabled: true),
                CornerPreset(name: "左のみ", topLeftEnabled: true, topRightEnabled: false, bottomLeftEnabled: true, bottomRightEnabled: false),
                CornerPreset(name: "右のみ", topLeftEnabled: false, topRightEnabled: true, bottomLeftEnabled: false, bottomRightEnabled: true),
                CornerPreset(name: "なし", topLeftEnabled: false, topRightEnabled: false, bottomLeftEnabled: false, bottomRightEnabled: false)
            ]
            
            presets.append(contentsOf: defaultPresets)
            savePresets()
        }
    }
    
    // プリセットの読み込み
    func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let decodedPresets = try? JSONDecoder().decode([CornerPreset].self, from: data) {
            presets = decodedPresets
        }
    }
    
    // プリセットの保存
    func savePresets() {
        if let encodedData = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encodedData, forKey: presetsKey)
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
        UserDefaults.standard.set(preset.topLeftEnabled, forKey: "topLeftEnabled")
        UserDefaults.standard.set(preset.topRightEnabled, forKey: "topRightEnabled")
        UserDefaults.standard.set(preset.bottomLeftEnabled, forKey: "bottomLeftEnabled")
        UserDefaults.standard.set(preset.bottomRightEnabled, forKey: "bottomRightEnabled")
        UserDefaults.standard.set(preset.cornerRadius, forKey: "cornerRadius")
        UserDefaults.standard.set(preset.cornerColor, forKey: "cornerColor")
        UserDefaults.standard.set(preset.superGamingMode, forKey: "superGamingMode")
        UserDefaults.standard.set(preset.gamingSpeed, forKey: "gamingSpeed")
        UserDefaults.standard.set(preset.glowIntensity, forKey: "glowIntensity")
        
        // AppDelegateに通知して設定を反映
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.updateOverlaySettings(radius: CGFloat(preset.cornerRadius), color: preset.cornerNSColor)
            appDelegate.updateCornerVisibility(
                topLeft: preset.topLeftEnabled,
                topRight: preset.topRightEnabled,
                bottomLeft: preset.bottomLeftEnabled,
                bottomRight: preset.bottomRightEnabled
            )
            appDelegate.updateGamingMode(enabled: preset.superGamingMode, speed: preset.gamingSpeed, glowIntensity: preset.glowIntensity)
        }
    }
    
    // 現在の設定からプリセットを作成
    func createPresetFromCurrentSettings(name: String) -> CornerPreset {
        let topLeftEnabled = UserDefaults.standard.bool(forKey: "topLeftEnabled")
        let topRightEnabled = UserDefaults.standard.bool(forKey: "topRightEnabled")
        let bottomLeftEnabled = UserDefaults.standard.bool(forKey: "bottomLeftEnabled")
        let bottomRightEnabled = UserDefaults.standard.bool(forKey: "bottomRightEnabled")
        let cornerRadius = UserDefaults.standard.object(forKey: "cornerRadius") as? Double ?? 20.0
        let cornerColorData = UserDefaults.standard.data(forKey: "cornerColor") ?? Data()
        let superGamingMode = UserDefaults.standard.bool(forKey: "superGamingMode")
        let gamingSpeed = UserDefaults.standard.object(forKey: "gamingSpeed") as? Double ?? 1.0
        let glowIntensity = UserDefaults.standard.object(forKey: "glowIntensity") as? Double ?? 1.0
        
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
            glowIntensity: glowIntensity
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
