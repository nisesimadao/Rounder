//
//  MenuBarController.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var appDelegate: AppDelegate?
    
    func setupMenuBar(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let icon = NSImage(named: "StatusIcon") {
                icon.size = NSSize(width: 16, height: 16)
                icon.isTemplate = true
                button.image = icon
            }
            button.toolTip = String(localized: "rounder_tooltip")
            
            let menu = NSMenu()
            
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
    
    @objc private func showSettings() {
        appDelegate?.showSettings()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
