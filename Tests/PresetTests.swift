#!/usr/bin/env swift

import Foundation

// テスト用の簡易実装
struct PresetManagerConstants {
    static let defaultCornerRadius: Double = 20.0
    static let defaultGamingSpeed: Double = 1.0
    static let defaultGlowIntensity: Double = 1.0
    static let defaultBloomWidth: Double = 1.0
}

enum CornerCutoutStyle: String, Codable {
    case rounded
    case squircle
    case polygon
}

struct CornerPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var topLeftEnabled: Bool
    var topRightEnabled: Bool
    var bottomLeftEnabled: Bool
    var bottomRightEnabled: Bool
    var cornerRadius: Double
    var cornerColor: Data
    var superGamingMode: Bool
    var gamingSpeed: Double
    var glowIntensity: Double
    var bloomWidth: Double
    var cornerCutoutStyle: CornerCutoutStyle

    init(name: String,
         topLeftEnabled: Bool = true,
         topRightEnabled: Bool = true,
         bottomLeftEnabled: Bool = true,
         bottomRightEnabled: Bool = true,
         cornerRadius: Double = PresetManagerConstants.defaultCornerRadius,
         cornerColor: Data = Data(),
         superGamingMode: Bool = false,
         gamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed,
         glowIntensity: Double = PresetManagerConstants.defaultGlowIntensity,
         bloomWidth: Double = PresetManagerConstants.defaultBloomWidth,
         cornerCutoutStyle: CornerCutoutStyle = .rounded) {
        self.id = UUID()
        self.name = name
        self.topLeftEnabled = topLeftEnabled
        self.topRightEnabled = topRightEnabled
        self.bottomLeftEnabled = bottomLeftEnabled
        self.bottomRightEnabled = bottomRightEnabled
        self.cornerRadius = cornerRadius
        self.cornerColor = cornerColor
        self.superGamingMode = superGamingMode
        self.gamingSpeed = gamingSpeed
        self.glowIntensity = glowIntensity
        self.bloomWidth = bloomWidth
        self.cornerCutoutStyle = cornerCutoutStyle
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
    }
}

// テスト関数
func testPresetEncodingDecoding() -> Bool {
    print("テスト1: プリセットのエンコード/デコード")
    
    let original = CornerPreset(
        name: "Test Preset",
        superGamingMode: true,
        gamingSpeed: 2.0,
        glowIntensity: 1.5,
        bloomWidth: 2.0,
        cornerCutoutStyle: .squircle
    )
    
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(original)
        print("エンコード成功: \(String(data: data, encoding: .utf8) ?? "")")
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CornerPreset.self, from: data)
        
        let success = decoded.name == original.name &&
                      decoded.superGamingMode == original.superGamingMode &&
                      decoded.gamingSpeed == original.gamingSpeed &&
                      decoded.glowIntensity == original.glowIntensity &&
                      decoded.bloomWidth == original.bloomWidth &&
                      decoded.cornerCutoutStyle == original.cornerCutoutStyle
        
        if success {
            print("✓ デコード成功: すべての値が一致")
            print("  - gamingSpeed: \(decoded.gamingSpeed)")
            print("  - glowIntensity: \(decoded.glowIntensity)")
            print("  - bloomWidth: \(decoded.bloomWidth)")
        } else {
            print("✗ デコード失敗: 値が不一致")
        }
        
        return success
    } catch {
        print("✗ エンコード/デコードエラー: \(error)")
        return false
    }
}

func testLegacyPresetCompatibility() -> Bool {
    print("\nテスト2: 旧プリセット（bloomWidthなし）の互換性")
    
    // bloomWidthがない古いJSON形式
    let legacyJSON = """
    {
        "id": "00000000-0000-0000-0000-000000000001",
        "name": "Legacy Preset",
        "topLeftEnabled": true,
        "topRightEnabled": true,
        "bottomLeftEnabled": true,
        "bottomRightEnabled": true,
        "cornerRadius": 20.0,
        "cornerColor": "",
        "superGamingMode": true,
        "gamingSpeed": 1.5,
        "glowIntensity": 2.0,
        "cornerCutoutStyle": "rounded"
    }
    """
    
    guard let data = legacyJSON.data(using: .utf8) else {
        print("✗ JSONデータ作成失敗")
        return false
    }
    
    do {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CornerPreset.self, from: data)
        
        let success = decoded.bloomWidth == PresetManagerConstants.defaultBloomWidth
        
        if success {
            print("✓ 旧プリセットのデコード成功")
            print("  - bloomWidth（デフォルト値）: \(decoded.bloomWidth)")
        } else {
            print("✗ bloomWidthのデフォルト値が正しくない: \(decoded.bloomWidth)")
        }
        
        return success
    } catch {
        print("✗ 旧プリセットのデコードエラー: \(error)")
        return false
    }
}

func testPresetArray() -> Bool {
    print("\nテスト3: プリセット配列のエンコード/デコード")
    
    let presets = [
        CornerPreset(name: "Preset 1", gamingSpeed: 1.0, glowIntensity: 1.0, bloomWidth: 1.0),
        CornerPreset(name: "Preset 2", gamingSpeed: 2.0, glowIntensity: 1.5, bloomWidth: 2.0),
        CornerPreset(name: "Preset 3", gamingSpeed: 3.0, glowIntensity: 2.0, bloomWidth: 3.0)
    ]
    
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(presets)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([CornerPreset].self, from: data)
        
        let success = decoded.count == presets.count &&
                      decoded[1].gamingSpeed == 2.0 &&
                      decoded[1].glowIntensity == 1.5 &&
                      decoded[1].bloomWidth == 2.0
        
        if success {
            print("✓ プリセット配列のデコード成功")
            print("  - プリセット数: \(decoded.count)")
            print("  - Preset 2: gamingSpeed=\(decoded[1].gamingSpeed), glowIntensity=\(decoded[1].glowIntensity), bloomWidth=\(decoded[1].bloomWidth)")
        } else {
            print("✗ プリセット配列のデコード失敗")
        }
        
        return success
    } catch {
        print("✗ プリセット配列のエンコード/デコードエラー: \(error)")
        return false
    }
}

// メイン実行
print("=== プリセット機能自動テスト ===\n")

let test1 = testPresetEncodingDecoding()
let test2 = testLegacyPresetCompatibility()
let test3 = testPresetArray()

print("\n=== テスト結果 ===")
print("テスト1（エンコード/デコード）: \(test1 ? "✓ 成功" : "✗ 失敗")")
print("テスト2（旧プリセット互換性）: \(test2 ? "✓ 成功" : "✗ 失敗")")
print("テスト3（プリセット配列）: \(test3 ? "✓ 成功" : "✗ 失敗")")

let allPassed = test1 && test2 && test3
print("\n全体結果: \(allPassed ? "✓ すべてのテストに成功" : "✗ いずれかのテストに失敗")")

exit(allPassed ? 0 : 1)
