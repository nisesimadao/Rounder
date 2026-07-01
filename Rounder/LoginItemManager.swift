//
//  LoginItemManager.swift
//  Rounder
//
//  ログイン時に自動起動するかどうかを管理する。
//  常時オンで角を丸めるアプリなので、「ログイン時に起動」はこのアプリの目的に沿った機能。
//

import Foundation
import ServiceManagement

enum LoginItemManager {
    /// 現在ログイン項目として登録されているか
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// ログイン時の自動起動を有効／無効にする。
    /// - Returns: 反映後の実際の状態（失敗時は変更前の状態）
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
        return isEnabled
    }
}
