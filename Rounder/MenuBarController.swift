//
//  MenuBarController.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa

// MARK: - Constants
struct MenuBarControllerConstants {
    static let iconSize = NSSize(width: 16, height: 16)
}

class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var appDelegate: AppDelegate?
    private var toggleItem: NSMenuItem?

    func setupMenuBar(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let icon = NSImage(named: "StatusIcon") {
                icon.size = MenuBarControllerConstants.iconSize
                icon.isTemplate = true
                button.image = icon
            }
            button.toolTip = String(localized: "rounder_tooltip")

            let menu = NSMenu()
            menu.delegate = self

            // 角の表示/非表示をワンクリックで切り替えるトグル
            let toggleItem = NSMenuItem(
                title: String(localized: "enable_rounded_corners"),
                action: #selector(toggleEnabled),
                keyEquivalent: ""
            )
            toggleItem.target = self
            menu.addItem(toggleItem)
            self.toggleItem = toggleItem

            menu.addItem(NSMenuItem.separator())

            let settingsItem = NSMenuItem(
                title: String(localized: "settings_menu"),
                action: #selector(showSettings),
                keyEquivalent: ","
            )
            settingsItem.target = self
            menu.addItem(settingsItem)

            menu.addItem(NSMenuItem.separator())

            let quitItem = NSMenuItem(
                title: String(localized: "quit_menu"),
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)

            statusItem?.menu = menu
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        // メニューを開くたびに、現在の有効状態をチェックマークへ反映する
        let isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isEnabled, defaultValue: true)
        toggleItem?.state = isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        let isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isEnabled, defaultValue: true)
        UserDefaults.standard.set(!isEnabled, forKey: UserDefaultsKeys.isEnabled)
        // 保存済み設定でその場で反映（再起動不要）
        appDelegate?.recreateOverlayWindows()
    }

    @objc private func showSettings() {
        appDelegate?.showSettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
