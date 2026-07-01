//
//  NSScreen+DisplayInfo.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/05/04.
//

import Cocoa
import CoreGraphics

extension NSScreen {
    /// ディスプレイIDを取得
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
    
    /// ディスプレイ名を取得
    var displayName: String {
        // localizedNameが利用可能なら使用
        let localizedName = self.localizedName
        if !localizedName.isEmpty {
            return localizedName
        }
        
        // フォールバック：ディスプレイIDを使用
        if let displayID = displayID {
            return "Display \(displayID)"
        }
        
        return "Unknown Display"
    }
    
    /// メインディスプレイかどうか
    var isMainDisplay: Bool {
        guard let displayID = displayID else { return false }
        return CGDisplayIsMain(displayID) != 0
    }
    
    /// ディスプレイの物理サイズを取得
    var physicalSize: NSSize? {
        return deviceDescription[NSDeviceDescriptionKey.size] as? NSSize
    }
    
    /// ディスプレイの解像度を取得
    var resolution: CGSize {
        return frame.size
    }
    
    /// すべてのディスプレイ情報を取得
    static func getAllDisplayInfo() -> [DisplayInfo] {
        return screens.compactMap { screen in
            guard let displayID = screen.displayID else { return nil }
            
            return DisplayInfo(
                screen: screen,
                displayID: displayID,
                name: screen.displayName,
                isMain: screen.isMainDisplay,
                resolution: screen.resolution,
                frame: screen.frame
            )
        }
    }
}

/// ディスプレイ情報構造体
struct DisplayInfo: Identifiable, Hashable {
    let id = UUID()
    let screen: NSScreen
    let displayID: CGDirectDisplayID
    let name: String
    let isMain: Bool
    let resolution: CGSize
    let frame: NSRect
    
    /// ディスプレイの説明文
    var description: String {
        let width = Int(resolution.width)
        let height = Int(resolution.height)
        let mainText = isMain ? String(localized: "main_display_suffix") : ""
        return "\(name) - \(width)x\(height)\(mainText)"
    }
}
